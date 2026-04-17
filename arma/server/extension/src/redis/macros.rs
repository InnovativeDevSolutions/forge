//! Macros for Redis operation boilerplate reduction.

/// Macro for Redis operations that handles all connection and async boilerplate.
#[macro_export]
macro_rules! redis_operation {
    ($conn:ident => $operation:block) => {{
        use tokio::time::{Duration, timeout};
        use $crate::redis;
        use $crate::{CONNECTION_STATE, ConnectionState, REDIS_POOL, RUNTIME};

        let timeout_config = redis::config::load().redis;
        let pool_get_timeout =
            Duration::from_millis(timeout_config.pool_get_timeout_ms.unwrap_or(2000));
        let command_timeout =
            Duration::from_millis(timeout_config.command_timeout_ms.unwrap_or(2000));
        let init_timeout = Duration::from_millis(timeout_config.connect_timeout_ms.unwrap_or(2000));

        // Get the Redis connection pool (initialized at startup)
        let pool = match REDIS_POOL.get() {
            Some(pool) => pool,
            None => {
                if *CONNECTION_STATE.read().unwrap() == ConnectionState::Failed {
                    return "Error: Redis connection unavailable".to_string();
                }

                // Attempt lazy initialization if not already initialized
                let rt = &RUNTIME;
                let init_result = rt.block_on(async move {
                    let cfg = redis::config::load();
                    match timeout(init_timeout, redis::client::create_redis_pool(&cfg.redis)).await
                    {
                        Ok(Ok(pool)) => {
                            let _ = REDIS_POOL.set(pool);
                            Ok(())
                        }
                        Ok(Err(_e)) => {
                            let default_cfg = redis::RedisConfig::default();
                            match timeout(
                                init_timeout,
                                redis::client::create_redis_pool(&default_cfg),
                            )
                            .await
                            {
                                Ok(Ok(pool)) => {
                                    let _ = REDIS_POOL.set(pool);
                                    Ok(())
                                }
                                Ok(Err(e)) => Err(format!("{}", e)),
                                Err(_) => {
                                    Err("Redis fallback initialization timed out".to_string())
                                }
                            }
                        }
                        Err(_) => Err("Redis initialization timed out".to_string()),
                    }
                });

                match init_result {
                    Ok(()) => {
                        *CONNECTION_STATE.write().unwrap() = ConnectionState::Connected;
                        match REDIS_POOL.get() {
                            Some(pool) => pool,
                            None => return "Error: Redis pool not initialized".to_string(),
                        }
                    }
                    Err(err) => {
                        *CONNECTION_STATE.write().unwrap() = ConnectionState::Failed;
                        return format!("Error: {}", err);
                    }
                }
            }
        };

        // Use the global tokio runtime to execute async operations
        let rt = &RUNTIME;
        rt.block_on(async move {
            // Acquire a connection from the pool
            let mut $conn = match timeout(pool_get_timeout, pool.get()).await {
                Ok(Ok(conn)) => conn,
                Ok(Err(e)) => return format!("Error: {}", e),
                Err(_) => return "Error: Redis connection checkout timed out".to_string(),
            };

            // Execute the user-provided Redis operation
            match timeout(command_timeout, async move { $operation }).await {
                Ok(result) => result,
                Err(_) => "Error: Redis operation timed out".to_string(),
            }
        })
    }};
}

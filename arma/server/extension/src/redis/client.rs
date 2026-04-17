use super::config::RedisConfig;
use bb8_redis::{RedisConnectionManager, bb8};
use std::error::Error;
use std::time::Duration;

/// Redis connection pool type alias.
pub type RedisClient = bb8::Pool<RedisConnectionManager>;

/// Creates a Redis connection pool with the specified configuration.
pub async fn create_redis_pool(
    config: &RedisConfig,
) -> Result<RedisClient, Box<dyn Error + Send + Sync>> {
    // Generate the Redis connection string from configuration
    let connection_string = config.connection_string();

    // Create the connection manager that will handle individual connections
    let manager = RedisConnectionManager::new(connection_string)?;

    // Start building the connection pool with default settings
    let mut pool_builder = bb8::Pool::builder();

    // Configure maximum number of connections if specified
    // This prevents overwhelming the Redis server with too many connections
    if let Some(max_conn) = config.max_connections {
        pool_builder = pool_builder.max_size(max_conn as u32);
    }

    // Configure minimum idle connections if specified
    // This ensures quick response times by keeping connections ready
    if let Some(min_conn) = config.min_connections {
        pool_builder = pool_builder.min_idle(Some(min_conn as u32));
    }

    // Configure idle connection timeout if specified
    // This prevents keeping stale connections that might be closed by the server
    if let Some(idle_timeout) = config.idle_timeout {
        pool_builder = pool_builder.idle_timeout(Some(Duration::from_secs(idle_timeout)));
    }

    // Bound connection acquisition from the pool so game thread calls fail fast
    if let Some(connect_timeout_ms) = config.connect_timeout_ms {
        pool_builder = pool_builder.connection_timeout(Duration::from_millis(connect_timeout_ms));
    }

    // Build the final connection pool with all configured parameters
    let pool = pool_builder.build(manager).await?;
    Ok(pool)
}

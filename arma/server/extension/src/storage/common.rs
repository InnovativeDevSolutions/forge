use super::*;
use serde_json::Value as JsonValue;

pub(super) fn surreal_select<T>(
    table: &'static str,
    id: &str,
    label: &str,
) -> Result<Option<T>, String>
where
    T: DeserializeOwned,
{
    let id = id.to_string();
    RUNTIME.block_on(async move {
        let value: Option<JsonValue> = surreal::client()
            .await?
            .select((table, id.as_str()))
            .await
            .map_err(|error| format!("SurrealDB {} select failed: {}", label, error))?;
        value
            .map(|record| {
                serde_json::from_value(record)
                    .map_err(|error| format!("SurrealDB {} decode failed: {}", label, error))
            })
            .transpose()
    })
}

pub(super) fn surreal_select_all<T>(table: &'static str, label: &str) -> Result<Vec<T>, String>
where
    T: DeserializeOwned,
{
    RUNTIME.block_on(async move {
        let values: Vec<JsonValue> = surreal::client()
            .await?
            .select(table)
            .await
            .map_err(|error| format!("SurrealDB {} select all failed: {}", label, error))?;
        values
            .into_iter()
            .map(|record| {
                serde_json::from_value(record)
                    .map_err(|error| format!("SurrealDB {} decode failed: {}", label, error))
            })
            .collect()
    })
}

pub(super) fn surreal_upsert<T>(
    table: &'static str,
    id: &str,
    label: &str,
    record: &T,
) -> Result<(), String>
where
    T: Serialize + DeserializeOwned,
{
    let id = id.to_string();
    let record = serde_json::to_value(record)
        .map_err(|error| format!("SurrealDB {} serialize failed: {}", label, error))?;
    RUNTIME.block_on(async move {
        let _: Option<JsonValue> = surreal::client()
            .await?
            .upsert((table, id.as_str()))
            .content(record)
            .await
            .map_err(|error| format!("SurrealDB {} upsert failed: {}", label, error))?;
        Ok(())
    })
}

pub(super) fn surreal_delete<T>(table: &'static str, id: &str, label: &str) -> Result<(), String>
where
    T: DeserializeOwned,
{
    let id = id.to_string();
    RUNTIME.block_on(async move {
        let _: Option<JsonValue> = surreal::client()
            .await?
            .delete((table, id.as_str()))
            .await
            .map_err(|error| format!("SurrealDB {} delete failed: {}", label, error))?;
        Ok(())
    })
}

pub(super) fn surreal_select_by_uid<T>(
    table: &'static str,
    label: &str,
    uid: &str,
) -> Result<Vec<T>, String>
where
    T: DeserializeOwned,
{
    surreal_select_by_field(table, label, "uid", uid)
}

pub(super) fn surreal_select_by_field<T>(
    table: &'static str,
    label: &str,
    field: &'static str,
    value: &str,
) -> Result<Vec<T>, String>
where
    T: DeserializeOwned,
{
    let value = value.to_string();
    RUNTIME.block_on(async move {
        let mut response = surreal::client()
            .await?
            .query(format!("SELECT * FROM {} WHERE {} = $value", table, field))
            .bind(("value", value))
            .await
            .map_err(|error| format!("SurrealDB {} select by field failed: {}", label, error))?;
        let values: Vec<JsonValue> = response
            .take(0)
            .map_err(|error| format!("SurrealDB {} select by field failed: {}", label, error))?;
        values
            .into_iter()
            .map(|record| {
                serde_json::from_value(record)
                    .map_err(|error| format!("SurrealDB {} decode failed: {}", label, error))
            })
            .collect()
    })
}

pub(super) fn surreal_delete_by_uid(
    table: &'static str,
    label: &str,
    uid: &str,
) -> Result<(), String> {
    surreal_delete_by_field(table, label, "uid", uid)
}

pub(super) fn surreal_delete_by_field(
    table: &'static str,
    label: &str,
    field: &'static str,
    value: &str,
) -> Result<(), String> {
    let value = value.to_string();
    RUNTIME.block_on(async move {
        surreal::client()
            .await?
            .query(format!("DELETE {} WHERE {} = $value", table, field))
            .bind(("value", value))
            .await
            .map_err(|error| format!("SurrealDB {} delete by field failed: {}", label, error))?
            .check()
            .map_err(|error| format!("SurrealDB {} delete by field failed: {}", label, error))?;
        Ok(())
    })
}

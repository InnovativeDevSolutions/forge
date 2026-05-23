use crate::log;
use crate::surreal::SurrealDb;

const SCHEMAS: &[(&str, &str)] = &[
    ("actor", include_str!("actor.surql")),
    ("bank", include_str!("bank.surql")),
    ("org", include_str!("org.surql")),
    ("locker", include_str!("locker.surql")),
    ("garage", include_str!("garage.surql")),
    ("phone", include_str!("phone.surql")),
];

pub async fn apply_all(db: &SurrealDb) -> Result<(), String> {
    for (name, schema) in SCHEMAS {
        for statement in schema_statements(schema) {
            db.query(statement)
                .await
                .map_err(|error| {
                    format!(
                        "SurrealDB {} schema bootstrap failed for statement '{}': {}",
                        name, statement, error
                    )
                })?
                .check()
                .map_err(|error| {
                    format!(
                        "SurrealDB {} schema bootstrap failed for statement '{}': {}",
                        name, statement, error
                    )
                })?;
        }

        log::log(
            "surreal",
            "DEBUG",
            &format!("Applied SurrealDB {} schema", name),
        );
    }

    Ok(())
}

fn schema_statements(schema: &'static str) -> impl Iterator<Item = &'static str> {
    schema
        .split(';')
        .map(str::trim)
        .filter(|statement| !statement.is_empty())
}

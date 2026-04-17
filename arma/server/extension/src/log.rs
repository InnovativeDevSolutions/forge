#![allow(dead_code)]

use std::collections::HashMap;
use std::fs::{File, OpenOptions, create_dir_all};
use std::io::Write;
use std::path::Path;
use std::sync::LazyLock;
use std::sync::Mutex;

static LOG_FILES: LazyLock<Mutex<HashMap<String, File>>> = LazyLock::new(|| {
    let logs_dir = Path::new("@forge_server/logs");
    create_dir_all(logs_dir).expect("Failed to create logs directory");
    Mutex::new(HashMap::new())
});

/// Generic logging function that creates log files on-demand.
///
/// # Arguments
/// * `category` - The log category (e.g., "actor", "org", "vehicle")
/// * `level` - The log level (e.g., "INFO", "DEBUG", "WARN", "ERROR")
/// * `message` - The message to log
///
/// # Example
/// ```
/// log("actor", "INFO", "Actor created successfully");
/// log("vehicle", "ERROR", "Failed to spawn vehicle");
/// ```
pub fn log(category: &str, level: &str, message: &str) {
    let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
    let log_entry = format!("[{}] [{}] {}\n", timestamp, level, message);

    if let Ok(mut files) = LOG_FILES.lock() {
        // Get or create the log file for this category
        let file = files.entry(category.to_string()).or_insert_with(|| {
            let logs_dir = Path::new("@forge_server/logs");
            let filename = format!("{}.log", category);
            let path = logs_dir.join(filename);

            OpenOptions::new()
                .create(true)
                .append(true)
                .open(path)
                .unwrap_or_else(|_| panic!("Failed to open {} log file", category))
        });

        let _ = file.write_all(log_entry.as_bytes());
        let _ = file.flush();
    }
}

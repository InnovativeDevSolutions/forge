#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use std::fs;
use std::io::{BufRead, BufReader};
use std::net::{SocketAddr, TcpStream};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

#[cfg(windows)]
use std::os::windows::process::CommandExt;

const LOG_LIMIT: usize = 500;
#[cfg(windows)]
const CREATE_NO_WINDOW: u32 = 0x08000000;
const SURREAL_VERSION_URL: &str = "https://version.surrealdb.com";
const SURREAL_DOWNLOAD_BASE_URL: &str = "https://download.surrealdb.com";

#[derive(Clone, Debug, Deserialize, Serialize)]
struct ServiceConfig {
    enabled: bool,
    command: String,
    args: Vec<String>,
    working_dir: String,
    health_host: String,
    health_port: u16,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct HostConfig {
    #[serde(default)]
    server: IcomServerConfig,
    #[serde(default)]
    surreal: ExtensionSurrealConfig,
    #[serde(default = "default_surrealdb_service")]
    surrealdb: ServiceConfig,
    #[serde(default = "default_icom_service")]
    icom: ServiceConfig,
    #[serde(default = "default_arma_service")]
    arma: ServiceConfig,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct IcomServerConfig {
    host: String,
    port: u16,
}

impl Default for IcomServerConfig {
    fn default() -> Self {
        Self {
            host: "0.0.0.0".to_string(),
            port: 9090,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct ExtensionSurrealConfig {
    endpoint: String,
    namespace: String,
    database: String,
    username: Option<String>,
    password: Option<String>,
    connect_timeout_ms: Option<u64>,
}

impl Default for ExtensionSurrealConfig {
    fn default() -> Self {
        Self {
            endpoint: "127.0.0.1:8000".to_string(),
            namespace: "forge".to_string(),
            database: "main".to_string(),
            username: Some("root".to_string()),
            password: Some("root".to_string()),
            connect_timeout_ms: Some(5000),
        }
    }
}

#[derive(Clone, Copy)]
enum ServiceKind {
    SurrealDb,
    Icom,
    Arma,
}

impl ServiceKind {
    fn from_name(name: &str) -> Result<Self, String> {
        match name {
            "surrealdb" => Ok(Self::SurrealDb),
            "icom" => Ok(Self::Icom),
            "arma" => Ok(Self::Arma),
            _ => Err(format!("Unknown service '{name}'")),
        }
    }

    fn name(self) -> &'static str {
        match self {
            Self::SurrealDb => "surrealdb",
            Self::Icom => "icom",
            Self::Arma => "arma",
        }
    }
}

#[derive(Debug, Serialize)]
struct ServiceStatus {
    name: String,
    enabled: bool,
    configured: bool,
    running: bool,
    healthy: bool,
    ping_ms: Option<u32>,
    pid: Option<u32>,
    command: String,
    health: String,
}

#[derive(Debug, Serialize)]
struct HostSnapshot {
    config_path: String,
    config: HostConfig,
    statuses: Vec<ServiceStatus>,
    logs: Vec<String>,
}

#[derive(Debug, Serialize)]
struct SurrealDbInstallInfo {
    installed: bool,
    version: Option<String>,
    path: Option<String>,
    latest: Option<String>,
}

struct ManagedProcess {
    child: Child,
}

#[derive(Default)]
struct Processes {
    surrealdb: Option<ManagedProcess>,
    icom: Option<ManagedProcess>,
    arma: Option<ManagedProcess>,
}

struct AppState {
    config_path: PathBuf,
    config: Mutex<HostConfig>,
    processes: Mutex<Processes>,
    logs: Arc<Mutex<VecDeque<String>>>,
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .manage(AppState::new())
        .invoke_handler(tauri::generate_handler![
            get_snapshot,
            start_service,
            stop_service,
            save_config,
            get_surrealdb_install_info,
            get_latest_surrealdb_version,
            install_surrealdb,
            create_arma_server_config,
            read_text_file,
            write_text_file
        ])
        .run(tauri::generate_context!())
        .expect("failed to run Forge Host");
}

impl AppState {
    fn new() -> Self {
        let config_path = locate_config_path();
        let config = load_config(&config_path)
            .or_else(|_| load_example_config())
            .unwrap_or_else(|error| {
                eprintln!("Failed to load Forge Host config: {error}");
                default_config()
            });

        if !config_path.exists() {
            eprintln!(
                "Forge Host config not found; using defaults until saved to {}",
                config_path.display()
            );
        }

        Self {
            config_path,
            config: Mutex::new(config),
            processes: Mutex::new(Processes::default()),
            logs: Arc::new(Mutex::new(VecDeque::new())),
        }
    }
}

fn load_example_config() -> Result<HostConfig, String> {
    if let Some(repo_root) = find_repo_root() {
        let example = repo_root
            .join("bin")
            .join("host")
            .join("config.example.toml");
        return load_config(&example);
    }

    Err("No Forge Host example config found".to_string())
}

#[tauri::command]
fn get_snapshot(state: tauri::State<AppState>) -> Result<HostSnapshot, String> {
    let config = state
        .config
        .lock()
        .map_err(|_| "Config lock poisoned".to_string())?
        .clone();
    let mut processes = state
        .processes
        .lock()
        .map_err(|_| "Process lock poisoned".to_string())?;

    let statuses = vec![
        service_status(ServiceKind::SurrealDb, &config.surrealdb, &mut processes),
        service_status(ServiceKind::Icom, &config.icom, &mut processes),
        service_status(ServiceKind::Arma, &config.arma, &mut processes),
    ];

    Ok(HostSnapshot {
        config_path: state.config_path.display().to_string(),
        config,
        statuses,
        logs: read_logs(&state.logs),
    })
}

#[tauri::command]
fn start_service(name: String, state: tauri::State<AppState>) -> Result<HostSnapshot, String> {
    let kind = ServiceKind::from_name(&name)?;
    let config = state
        .config
        .lock()
        .map_err(|_| "Config lock poisoned".to_string())?
        .clone();
    let service = service_config(kind, &config);

    if !service.enabled {
        return Err(format!("{} is disabled in host config", kind.name()));
    }
    if !matches!(kind, ServiceKind::SurrealDb) && service.command.trim().is_empty() {
        return Err(format!("{} command is empty", kind.name()));
    }

    let mut processes = state
        .processes
        .lock()
        .map_err(|_| "Process lock poisoned".to_string())?;
    if process_slot(kind, &mut processes).is_some() {
        drop(processes);
        return get_snapshot(state);
    }

    let config_dir = state
        .config_path
        .parent()
        .map(Path::to_path_buf)
        .unwrap_or_else(|| PathBuf::from("."));
    let working_dir = resolve_optional_path(&config_dir, &service.working_dir);
    let command_name = effective_service_command(kind, &service);
    let command_path = resolve_command(&working_dir, &command_name);
    validate_service_command(kind, &command_path)?;

    append_log(
        &state.logs,
        format!(
            "[{}] starting: {} {}",
            kind.name(),
            command_path.display(),
            service.args.join(" ")
        ),
    );

    let mut command = Command::new(&command_path);
    command
        .args(&service.args)
        .current_dir(&working_dir)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    hide_child_console(&mut command);

    let mut child = command
        .spawn()
        .map_err(|error| format!("Failed to start {}: {}", kind.name(), error))?;

    if let Some(stdout) = child.stdout.take() {
        pipe_logs(kind, "out", stdout, Arc::clone(&state.logs));
    }
    if let Some(stderr) = child.stderr.take() {
        pipe_logs(kind, "err", stderr, Arc::clone(&state.logs));
    }

    *process_slot(kind, &mut processes) = Some(ManagedProcess { child });
    drop(processes);
    get_snapshot(state)
}

#[tauri::command]
fn stop_service(name: String, state: tauri::State<AppState>) -> Result<HostSnapshot, String> {
    let kind = ServiceKind::from_name(&name)?;
    let mut processes = state
        .processes
        .lock()
        .map_err(|_| "Process lock poisoned".to_string())?;
    if let Some(mut managed) = process_slot(kind, &mut processes).take() {
        append_log(&state.logs, format!("[{}] stopping", kind.name()));
        managed
            .child
            .kill()
            .map_err(|error| format!("Failed to stop {}: {}", kind.name(), error))?;
        let _ = managed.child.wait();
    }
    drop(processes);
    get_snapshot(state)
}

#[tauri::command]
fn save_config(config: HostConfig, state: tauri::State<AppState>) -> Result<HostSnapshot, String> {
    let text = toml::to_string_pretty(&config)
        .map_err(|error| format!("Failed to serialize config: {error}"))?;
    fs::write(&state.config_path, text)
        .map_err(|error| format!("Failed to write config: {error}"))?;
    *state
        .config
        .lock()
        .map_err(|_| "Config lock poisoned".to_string())? = config;
    append_log(
        &state.logs,
        format!("[host] saved config to {}", state.config_path.display()),
    );
    get_snapshot(state)
}

#[tauri::command]
fn get_surrealdb_install_info() -> Result<SurrealDbInstallInfo, String> {
    let path = find_surreal_executable();
    let version = path.as_ref().and_then(|path| surreal_version(path).ok());

    Ok(SurrealDbInstallInfo {
        installed: path.is_some(),
        version,
        path: path.map(|path| path.display().to_string()),
        latest: None,
    })
}

#[tauri::command]
async fn get_latest_surrealdb_version() -> Result<String, String> {
    latest_surreal_version().await
}

#[tauri::command]
async fn install_surrealdb(
    version: String,
    state: tauri::State<'_, AppState>,
) -> Result<SurrealDbInstallInfo, String> {
    let target = normalize_surreal_version(&version)?;
    let resolved_version = resolve_surreal_version(&target).await?;
    let install_path = surreal_install_path()?;
    let install_dir = install_path
        .parent()
        .ok_or_else(|| "Unable to resolve SurrealDB install directory".to_string())?;

    fs::create_dir_all(install_dir)
        .map_err(|error| format!("Failed to create SurrealDB install directory: {error}"))?;

    append_log(
        &state.logs,
        format!(
            "[surrealdb] installing {resolved_version} to {}",
            install_path.display()
        ),
    );

    let download_url = surreal_download_url(&resolved_version)?;
    let bytes = reqwest::get(&download_url)
        .await
        .map_err(|error| format!("Failed to download SurrealDB: {error}"))?
        .error_for_status()
        .map_err(|error| format!("SurrealDB download failed: {error}"))?
        .bytes()
        .await
        .map_err(|error| format!("Failed to read SurrealDB download: {error}"))?;

    install_surreal_binary(&bytes, &install_path)?;
    ensure_surreal_on_user_path(install_dir)?;

    let info = get_surrealdb_install_info()?;
    append_log(
        &state.logs,
        format!(
            "[surrealdb] installed {}",
            info.version.as_deref().unwrap_or("SurrealDB")
        ),
    );
    Ok(info)
}

#[cfg(windows)]
fn hide_child_console(command: &mut Command) {
    command.creation_flags(CREATE_NO_WINDOW);
}

#[cfg(not(windows))]
fn hide_child_console(_command: &mut Command) {}

#[tauri::command]
fn create_arma_server_config(path: String, template: String) -> Result<(), String> {
    let path = PathBuf::from(path);
    if path.exists() {
        return Err(format!("Config file already exists: {}", path.display()));
    }

    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .map_err(|error| format!("Failed to create config directory: {error}"))?;
    }

    let content = arma_config_template(&template)?;

    fs::write(&path, content).map_err(|error| format!("Failed to write server config: {error}"))
}

#[tauri::command]
fn read_text_file(path: String) -> Result<String, String> {
    fs::read_to_string(&path).map_err(|error| format!("Failed to read {path}: {error}"))
}

#[tauri::command]
fn write_text_file(path: String, content: String) -> Result<(), String> {
    fs::write(&path, content).map_err(|error| format!("Failed to write {path}: {error}"))
}

fn normalize_surreal_version(value: &str) -> Result<String, String> {
    let trimmed = value.trim();
    if trimmed.eq_ignore_ascii_case("latest") {
        return Ok("latest".to_string());
    }
    if trimmed.chars().all(|character| character.is_ascii_digit()) {
        return Ok(trimmed.to_string());
    }
    let without_v = trimmed.strip_prefix('v').unwrap_or(trimmed);
    let parts: Vec<&str> = without_v.split('.').collect();
    if parts.len() == 3
        && parts.iter().all(|part| {
            !part.is_empty() && part.chars().all(|character| character.is_ascii_digit())
        })
    {
        return Ok(format!("v{without_v}"));
    }

    Err(format!(
        "Unsupported SurrealDB version '{value}'. Use a major version like '3', an exact version like 'v3.1.2', or 'latest'."
    ))
}

async fn latest_surreal_version() -> Result<String, String> {
    reqwest::get(SURREAL_VERSION_URL)
        .await
        .map_err(|error| format!("Failed to check latest SurrealDB version: {error}"))?
        .error_for_status()
        .map_err(|error| format!("SurrealDB version lookup failed: {error}"))?
        .text()
        .await
        .map(|text| text.trim().to_string())
        .map_err(|error| format!("Failed to read latest SurrealDB version: {error}"))
}

async fn resolve_surreal_version(target: &str) -> Result<String, String> {
    if target == "latest" {
        return latest_surreal_version().await;
    }

    if target.chars().all(|character| character.is_ascii_digit()) {
        let latest = latest_surreal_version().await?;
        if latest
            .trim_start_matches('v')
            .starts_with(&format!("{target}."))
        {
            return Ok(latest);
        }
        return Err(format!(
            "Latest SurrealDB is {latest}, not {target}.x. Enter an exact version or use latest after confirming compatibility."
        ));
    }

    Ok(target.to_string())
}

fn surreal_download_url(version: &str) -> Result<String, String> {
    Ok(format!(
        "{SURREAL_DOWNLOAD_BASE_URL}/{version}/surreal-{version}.{}",
        surreal_download_suffix()?
    ))
}

fn surreal_download_suffix() -> Result<&'static str, String> {
    match (std::env::consts::OS, std::env::consts::ARCH) {
        ("windows", "x86_64") => Ok("windows-amd64.exe"),
        ("linux", "x86_64") => Ok("linux-amd64.tgz"),
        ("macos", "x86_64") => Ok("darwin-amd64.tgz"),
        ("macos", "aarch64") => Ok("darwin-arm64.tgz"),
        (os, arch) => Err(format!(
            "SurrealDB in-app install is not configured for {os}-{arch}"
        )),
    }
}

#[cfg(windows)]
fn install_surreal_binary(bytes: &[u8], install_path: &Path) -> Result<(), String> {
    fs::write(install_path, bytes).map_err(|error| format!("Failed to write surreal.exe: {error}"))
}

#[cfg(not(windows))]
fn install_surreal_binary(bytes: &[u8], install_path: &Path) -> Result<(), String> {
    use flate2::read::GzDecoder;
    use std::io::Cursor;
    use std::os::unix::fs::PermissionsExt;
    use tar::Archive;

    let decoder = GzDecoder::new(Cursor::new(bytes));
    let mut archive = Archive::new(decoder);
    for entry in archive
        .entries()
        .map_err(|error| format!("Failed to read SurrealDB archive: {error}"))?
    {
        let mut entry =
            entry.map_err(|error| format!("Failed to read SurrealDB archive entry: {error}"))?;
        let path = entry
            .path()
            .map_err(|error| format!("Failed to read SurrealDB archive path: {error}"))?;
        if path
            .file_name()
            .and_then(|name| name.to_str())
            .is_some_and(|name| name == "surreal")
        {
            entry
                .unpack(install_path)
                .map_err(|error| format!("Failed to write SurrealDB executable: {error}"))?;
            let mut permissions = fs::metadata(install_path)
                .map_err(|error| format!("Failed to inspect SurrealDB executable: {error}"))?
                .permissions();
            permissions.set_mode(0o755);
            fs::set_permissions(install_path, permissions).map_err(|error| {
                format!("Failed to mark SurrealDB executable runnable: {error}")
            })?;
            return Ok(());
        }
    }

    Err("SurrealDB archive did not contain a surreal executable".to_string())
}

fn surreal_install_path() -> Result<PathBuf, String> {
    if let Some(existing) = find_surreal_executable() {
        return Ok(existing);
    }

    #[cfg(windows)]
    {
        let base = std::env::var_os("LOCALAPPDATA")
            .map(PathBuf::from)
            .or_else(|| std::env::var_os("USERPROFILE").map(PathBuf::from))
            .ok_or_else(|| "Unable to resolve LOCALAPPDATA for SurrealDB install".to_string())?;
        Ok(base.join("SurrealDB").join("surreal.exe"))
    }

    #[cfg(not(windows))]
    {
        let home = std::env::var_os("HOME")
            .map(PathBuf::from)
            .ok_or_else(|| "Unable to resolve HOME for SurrealDB install".to_string())?;
        Ok(home.join(".surrealdb").join("bin").join("surreal"))
    }
}

fn find_surreal_executable() -> Option<PathBuf> {
    find_executable_on_path(surreal_executable_name())
        .or_else(|| default_surreal_install_path().filter(|path| path.exists()))
}

fn default_surreal_install_path() -> Option<PathBuf> {
    #[cfg(windows)]
    {
        std::env::var_os("LOCALAPPDATA")
            .map(PathBuf::from)
            .or_else(|| std::env::var_os("USERPROFILE").map(PathBuf::from))
            .map(|base| base.join("SurrealDB").join("surreal.exe"))
    }

    #[cfg(not(windows))]
    {
        std::env::var_os("HOME")
            .map(PathBuf::from)
            .map(|home| home.join(".surrealdb").join("bin").join("surreal"))
    }
}

fn surreal_executable_name() -> &'static str {
    if cfg!(windows) {
        "surreal.exe"
    } else {
        "surreal"
    }
}

fn find_executable_on_path(executable: &str) -> Option<PathBuf> {
    let paths = std::env::var_os("PATH")?;
    std::env::split_paths(&paths)
        .map(|path| path.join(executable))
        .find(|path| path.is_file())
}

fn surreal_version(path: &Path) -> Result<String, String> {
    let mut command = Command::new(path);
    command.arg("version");
    hide_child_console(&mut command);
    let output = command
        .output()
        .map_err(|error| format!("Failed to run {} version: {error}", path.display()))?;
    if !output.status.success() {
        return Err(format!(
            "Failed to read SurrealDB version from {}",
            path.display()
        ));
    }

    let text = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(text)
}

#[cfg(windows)]
fn ensure_surreal_on_user_path(install_dir: &Path) -> Result<(), String> {
    let current_path = std::env::var_os("PATH").unwrap_or_default();
    let mut path_parts: Vec<PathBuf> = std::env::split_paths(&current_path).collect();
    if !path_parts.iter().any(|path| path == install_dir) {
        path_parts.insert(0, install_dir.to_path_buf());
        let joined = std::env::join_paths(path_parts)
            .map_err(|error| format!("Failed to update process PATH: {error}"))?;
        unsafe {
            std::env::set_var("PATH", joined);
        }
    }

    let install_dir_text = install_dir.display().to_string();
    let script = format!(
        "$dir = '{}'; $path = [Environment]::GetEnvironmentVariable('Path', 'User'); if (($path -split ';') -notcontains $dir) {{ [Environment]::SetEnvironmentVariable('Path', (($dir, $path) -join ';').Trim(';'), 'User') }}",
        install_dir_text.replace('\'', "''")
    );
    let mut command = Command::new("powershell");
    command.args([
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        &script,
    ]);
    hide_child_console(&mut command);
    let output = command
        .output()
        .map_err(|error| format!("Failed to update user PATH: {error}"))?;
    if output.status.success() || output.status.code().is_none() {
        Ok(())
    } else {
        Err(format!(
            "Failed to update user PATH: {}",
            String::from_utf8_lossy(&output.stderr)
        ))
    }
}

#[cfg(not(windows))]
fn ensure_surreal_on_user_path(_install_dir: &Path) -> Result<(), String> {
    Ok(())
}

fn arma_config_template(template: &str) -> Result<&'static str, String> {
    match template {
        "basic" => Ok(include_str!("../../basic.example.cfg")),
        "server" | "" => Ok(include_str!("../../server.example.cfg")),
        other => Err(format!("Unknown Arma config template '{other}'")),
    }
}

fn service_config(kind: ServiceKind, config: &HostConfig) -> ServiceConfig {
    match kind {
        ServiceKind::SurrealDb => config.surrealdb.clone(),
        ServiceKind::Icom => config.icom.clone(),
        ServiceKind::Arma => config.arma.clone(),
    }
}

fn process_slot<'a>(
    kind: ServiceKind,
    processes: &'a mut Processes,
) -> &'a mut Option<ManagedProcess> {
    match kind {
        ServiceKind::SurrealDb => &mut processes.surrealdb,
        ServiceKind::Icom => &mut processes.icom,
        ServiceKind::Arma => &mut processes.arma,
    }
}

fn service_status(
    kind: ServiceKind,
    config: &ServiceConfig,
    processes: &mut Processes,
) -> ServiceStatus {
    let slot = process_slot(kind, processes);
    let running = match slot {
        Some(managed) => match managed.child.try_wait() {
            Ok(Some(_)) => {
                *slot = None;
                false
            }
            Ok(None) => true,
            Err(_) => false,
        },
        None => false,
    };
    let pid = slot.as_ref().map(|managed| managed.child.id());

    let (healthy, ping_ms) = if matches!(kind, ServiceKind::Icom | ServiceKind::Arma) {
        if running {
            (true, Some(0))
        } else {
            (false, None)
        }
    } else {
        check_health(&config.health_host, config.health_port)
    };

    ServiceStatus {
        name: kind.name().to_string(),
        enabled: config.enabled,
        configured: matches!(kind, ServiceKind::SurrealDb) || !config.command.trim().is_empty(),
        running,
        healthy,
        ping_ms,
        pid,
        command: effective_service_command(kind, config),
        health: format!("{}:{}", config.health_host, config.health_port),
    }
}

fn effective_service_command(kind: ServiceKind, config: &ServiceConfig) -> String {
    match kind {
        ServiceKind::SurrealDb => find_surreal_executable()
            .map(|path| path.display().to_string())
            .unwrap_or_else(|| "surreal".to_string()),
        ServiceKind::Icom | ServiceKind::Arma => config.command.clone(),
    }
}

fn check_health(host: &str, port: u16) -> (bool, Option<u32>) {
    let Ok(addr) = format!("{host}:{port}").parse::<SocketAddr>() else {
        return (false, None);
    };
    let started = Instant::now();
    match TcpStream::connect_timeout(&addr, Duration::from_millis(350)) {
        Ok(_) => {
            let elapsed_ms = started.elapsed().as_millis();
            let ping_ms = u32::try_from(elapsed_ms).unwrap_or(u32::MAX).max(1);
            (true, Some(ping_ms))
        }
        Err(_) => (false, None),
    }
}

fn pipe_logs<R>(
    kind: ServiceKind,
    stream_name: &'static str,
    reader: R,
    logs: Arc<Mutex<VecDeque<String>>>,
) where
    R: std::io::Read + Send + 'static,
{
    std::thread::spawn(move || {
        for line in BufReader::new(reader).lines() {
            match line {
                Ok(line) => {
                    append_log(&logs, format!("[{}:{}] {}", kind.name(), stream_name, line))
                }
                Err(error) => {
                    append_log(
                        &logs,
                        format!(
                            "[{}:{}] log read error: {}",
                            kind.name(),
                            stream_name,
                            error
                        ),
                    );
                    break;
                }
            }
        }
    });
}

fn append_log(logs: &Arc<Mutex<VecDeque<String>>>, line: String) {
    if let Ok(mut logs) = logs.lock() {
        if logs.len() >= LOG_LIMIT {
            logs.pop_front();
        }
        logs.push_back(line);
    }
}

fn read_logs(logs: &Arc<Mutex<VecDeque<String>>>) -> Vec<String> {
    logs.lock()
        .map(|logs| logs.iter().cloned().collect())
        .unwrap_or_default()
}

fn load_config(path: &Path) -> Result<HostConfig, String> {
    let text = fs::read_to_string(path).map_err(|error| error.to_string())?;
    toml::from_str(&text).map_err(|error| error.to_string())
}

fn locate_config_path() -> PathBuf {
    if let Some(repo_root) = find_repo_root() {
        return repo_root.join("config.toml");
    }

    let cwd_config = std::env::current_dir()
        .unwrap_or_else(|_| PathBuf::from("."))
        .join("config.toml");
    if cwd_config.exists() {
        return cwd_config;
    }

    std::env::current_exe()
        .ok()
        .and_then(|path| path.parent().map(|dir| dir.join("config.toml")))
        .unwrap_or(cwd_config)
}

fn find_repo_root() -> Option<PathBuf> {
    let mut candidates = Vec::new();
    if let Ok(cwd) = std::env::current_dir() {
        candidates.push(cwd);
    }
    if let Ok(exe) = std::env::current_exe() {
        if let Some(parent) = exe.parent() {
            candidates.push(parent.to_path_buf());
        }
    }

    for candidate in candidates {
        for ancestor in candidate.ancestors() {
            if ancestor.join("Cargo.toml").exists()
                && ancestor.join("bin").join("host").exists()
                && ancestor.join("arma").join("server").exists()
            {
                return Some(ancestor.to_path_buf());
            }
        }
    }

    None
}

fn resolve_optional_path(config_dir: &Path, path: &str) -> PathBuf {
    if path.trim().is_empty() {
        return config_dir.to_path_buf();
    }
    let path = PathBuf::from(path);
    if path.is_absolute() {
        path
    } else {
        config_dir.join(path)
    }
}

fn resolve_command(working_dir: &Path, command: &str) -> PathBuf {
    let command_path = PathBuf::from(command);
    if command_path.is_absolute() || command.contains('\\') || command.contains('/') {
        if command_path.is_absolute() {
            command_path
        } else {
            working_dir.join(command_path)
        }
    } else {
        command_path
    }
}

fn validate_service_command(kind: ServiceKind, command_path: &Path) -> Result<(), String> {
    if !matches!(kind, ServiceKind::Arma) {
        return Ok(());
    }

    let exe_name = command_path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or_default()
        .to_ascii_lowercase();

    if is_arma_server_executable(&exe_name) {
        return Ok(());
    }

    Err(format!(
        "Arma hosting must launch arma3server_x64.exe, not '{}'. Select the dedicated server executable.",
        command_path.display()
    ))
}

fn is_arma_server_executable(exe_name: &str) -> bool {
    exe_name.starts_with("arma3server")
}

fn default_config() -> HostConfig {
    HostConfig {
        server: IcomServerConfig::default(),
        surreal: ExtensionSurrealConfig::default(),
        surrealdb: default_surrealdb_service(),
        icom: default_icom_service(),
        arma: default_arma_service(),
    }
}

fn default_surrealdb_service() -> ServiceConfig {
    ServiceConfig {
        enabled: true,
        command: "surreal".to_string(),
        args: vec![
            "start".to_string(),
            "--user".to_string(),
            "root".to_string(),
            "--pass".to_string(),
            "root".to_string(),
            "--bind".to_string(),
            "127.0.0.1:8000".to_string(),
            "rocksdb://forge.db".to_string(),
        ],
        working_dir: "arma/server/surrealdb".to_string(),
        health_host: "127.0.0.1".to_string(),
        health_port: 8000,
    }
}

fn default_icom_service() -> ServiceConfig {
    ServiceConfig {
        enabled: true,
        command: "target/release/forge-icom.exe".to_string(),
        args: Vec::new(),
        working_dir: ".".to_string(),
        health_host: "127.0.0.1".to_string(),
        health_port: 9090,
    }
}

fn default_arma_service() -> ServiceConfig {
    ServiceConfig {
        enabled: false,
        command: "arma3server_x64.exe".to_string(),
        args: vec![
            "-config=server.cfg".to_string(),
            "-cfg=basic.cfg".to_string(),
            "-port=2302".to_string(),
            "-profiles=serverprofiles".to_string(),
            "-name=server".to_string(),
            "-noBattlEye".to_string(),
        ],
        working_dir: String::new(),
        health_host: "127.0.0.1".to_string(),
        health_port: 2302,
    }
}

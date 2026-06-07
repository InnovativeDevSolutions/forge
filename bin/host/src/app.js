const serviceNames = {
    surrealdb: "SurrealDB",
    icom: "ICOM",
    arma: "Arma Server",
};

const subtitles = {
    overview: "Start, stop, and check local Forge hosting services.",
    settings:
        "Edit process command, arguments, working directory, and health port.",
    logs: "Recent stdout, stderr, and host supervisor events.",
};

let snapshot = null;
let refreshTimer = null;
let lastRenderedLogText = "";
let activeSettingsService = "surrealdb";
let configDirty = false;
let activeEditorPath = "";
let surrealInstallInfo = null;

const views = {
    overview: document.getElementById("overviewView"),
    settings: document.getElementById("settingsView"),
    logs: document.getElementById("logsView"),
};

document.querySelectorAll(".nav-button").forEach((button) => {
    button.addEventListener("click", () => {
        const view = button.dataset.view;
        if (button.dataset.service) {
            if (
                configDirty &&
                button.dataset.service !== activeSettingsService
            ) {
                persistActiveSettingsForm();
            }
            activeSettingsService = button.dataset.service;
        } else if (view === "settings") {
            if (configDirty && activeSettingsService !== "surrealdb") {
                persistActiveSettingsForm();
            }
            activeSettingsService = "surrealdb";
        }
        document
            .querySelectorAll(".nav-button")
            .forEach((item) => item.classList.remove("active"));
        button.classList.add("active");
        Object.entries(views).forEach(([key, element]) =>
            element.classList.toggle("active", key === view),
        );
        setHeader(view);
        renderSettings(true);
        syncBulkActionsVisibility();
        syncRefreshTimer();
    });
});

document.getElementById("refreshButton").addEventListener("click", refresh);
document.getElementById("saveButton").addEventListener("click", saveConfig);
document.getElementById("startAllButton").addEventListener("click", startAll);
document.getElementById("stopAllButton").addEventListener("click", stopAll);
document
    .getElementById("editorCloseButton")
    .addEventListener("click", closeConfigEditor);
document
    .getElementById("editorReloadButton")
    .addEventListener("click", () =>
        runAction(() => openConfigEditor(activeEditorPath)),
    );
document
    .getElementById("editorSaveButton")
    .addEventListener("click", () => runAction(saveConfigEditor));

async function loadAppVersion() {
    const getVersion = window.__TAURI__?.app?.getVersion;
    if (!getVersion) return;

    try {
        document.getElementById("appVersion").textContent =
            `v${await getVersion()}`;
    } catch (error) {
        console.warn("Unable to load app version:", error);
    }
}

async function refresh() {
    if (isSettingsViewActive() && configDirty) {
        return;
    }

    try {
        const nextSnapshot = await tauriInvoke("get_snapshot");
        if (configDirty && snapshot) {
            persistActiveSettingsForm();
            nextSnapshot.config = snapshot.config;
        }
        snapshot = nextSnapshot;
        render();
    } catch (error) {
        renderError(error);
    }
}

async function startService(name) {
    snapshot = await tauriInvoke("start_service", { name });
    render();
}

async function stopService(name) {
    snapshot = await tauriInvoke("stop_service", { name });
    render();
}

async function startAll() {
    if (!snapshot) return;

    const serviceNames = Object.keys(snapshot.config).filter(
        (name) =>
            snapshot.config[name].enabled &&
            (name === "surrealdb" ||
                snapshot.config[name].command.trim() !== ""),
    );

    for (const name of serviceNames) {
        const status = snapshot.statuses.find((s) => s.name === name);
        if (status && !status.running) {
            await startService(name);

            if (name === "surrealdb") {
                await waitForServiceHealth("surrealdb", 30000);
            }
        }
    }
}

async function stopAll() {
    if (!snapshot) return;
    const serviceNames = Object.keys(snapshot.config).filter(
        (name) => snapshot.config[name].enabled,
    );
    for (const name of serviceNames) {
        const status = snapshot.statuses.find((s) => s.name === name);
        if (status && status.running) {
            await stopService(name);
        }
    }
}

async function waitForServiceHealth(serviceName, timeoutMs = 30000) {
    const startTime = Date.now();
    while (Date.now() - startTime < timeoutMs) {
        await refresh();
        const status = snapshot?.statuses.find((s) => s.name === serviceName);
        if (status?.healthy) {
            return true;
        }
        await new Promise((resolve) => setTimeout(resolve, 500));
    }
    return false;
}

async function saveConfig() {
    if (!snapshot) {
        await refresh();
    }
    const config = readFormConfig();
    snapshot = await tauriInvoke("save_config", { config });
    configDirty = false;
    render();
}

function tauriInvoke(command, payload) {
    const invoke = window.__TAURI__?.core?.invoke;
    if (!invoke) {
        return Promise.reject(
            "Tauri invoke API is not available in this window.",
        );
    }
    return invoke(command, payload);
}

function render() {
    if (!snapshot) return;
    document.getElementById("configPath").textContent = snapshot.config_path;
    syncSidebarStatus();
    renderServices();
    renderSettings();
    renderLogs();
    syncBulkActionsVisibility();
}

function setHeader(view) {
    const title =
        view === "settings"
            ? serviceNames[activeSettingsService]
            : activeNavLabel();
    document.getElementById("viewTitle").textContent = title;
    document.getElementById("viewSubtitle").textContent = subtitles[view];
}

function activeNavLabel() {
    return (
        document
            .querySelector(".nav-button.active span:last-child")
            ?.textContent.trim() || "Overview"
    );
}

function syncSidebarStatus() {
    document
        .querySelectorAll(
            ".nav-button[data-service], .nav-button[data-view='settings']:not([data-service])",
        )
        .forEach((button) => {
            const service = button.dataset.service || "surrealdb";
            const config = snapshot.config[service];
            const status = snapshot.statuses.find((s) => s.name === service);
            const enabled = config?.enabled;
            const running = status?.running;
            const healthy = status?.healthy;

            const isDisabled = !enabled;
            const isOnline = enabled && running && healthy;
            const isStopped = enabled && !isOnline;

            button.classList.toggle("service-enabled", Boolean(isOnline));
            button.classList.toggle("service-disabled", Boolean(isDisabled));
            button.classList.toggle("service-stopped", Boolean(isStopped));
        });
}

function renderServices() {
    const grid = document.getElementById("serviceGrid");
    const template = document.getElementById("serviceCardTemplate");
    grid.replaceChildren();

    snapshot.statuses.forEach((status) => {
        const node = template.content.firstElementChild.cloneNode(true);
        node.querySelector("h2").textContent =
            serviceNames[status.name] || status.name;
        const pingPill = node.querySelector(".ping-pill");
        const pingDisplay = resolvePingDisplay(status);
        pingPill.textContent = pingDisplay.label;
        pingPill.classList.remove("good", "warn", "bad", "unavailable");
        pingPill.classList.add(pingDisplay.className);
        node.querySelector(".command-line").textContent =
            status.command || "No command configured";

        const pill = node.querySelector(".status-pill");
        pill.textContent = status.running ? "Running" : "Stopped";
        pill.classList.add(status.running ? "running" : "stopped");

        node.querySelector(".pid").textContent = status.pid
            ? String(status.pid)
            : "-";
        node.querySelector(".health").textContent = status.health;
        node.querySelector(".enabled").textContent = status.enabled
            ? "Yes"
            : "No";

        const start = node.querySelector(".start");
        const stop = node.querySelector(".stop");
        if (!start || !stop) {
            throw new Error(
                "Service card template is missing start or stop controls.",
            );
        }
        start.disabled =
            status.running || !status.enabled || !status.configured;
        stop.disabled = !status.running;
        start.addEventListener("click", () =>
            runAction(() => startService(status.name)),
        );
        stop.addEventListener("click", () =>
            runAction(() => stopService(status.name)),
        );

        grid.appendChild(node);
    });
}

function resolvePingDisplay(status) {
    if (!status.healthy || typeof status.ping_ms !== "number") {
        return { label: "N/A", className: "unavailable" };
    }

    if (status.ping_ms <= 60) {
        return { label: `${status.ping_ms} ms`, className: "good" };
    }

    if (status.ping_ms <= 120) {
        return { label: `${status.ping_ms} ms`, className: "warn" };
    }

    return { label: `${status.ping_ms} ms`, className: "bad" };
}

function renderSettings(force = false) {
    if (!snapshot) return;
    if (!isSettingsViewActive()) return;

    const form = document.getElementById("configForm");
    if (!force && configDirty && isSettingsViewActive()) return;

    if (!snapshot.config[activeSettingsService]) {
        activeSettingsService = Object.keys(snapshot.config)[0];
    }

    const name = activeSettingsService;
    const config = snapshot.config[name];

    form.replaceChildren();
    form.className = "settings-form";
    form.innerHTML = renderSettingsPanel(name, config);

    form.querySelectorAll(
        "input[data-service], input[data-arg-key], select[data-arg-key]",
    ).forEach((input) => {
        input.addEventListener("input", () => {
            configDirty = true;
        });
        input.addEventListener("change", () => {
            configDirty = true;
        });
    });

    form.querySelectorAll("[data-picker]").forEach((button) => {
        button.addEventListener("click", () => {
            runAction(() =>
                pickPath(
                    button.dataset.picker,
                    button.dataset.target,
                    button.dataset.serviceTarget,
                ),
            );
        });
    });

    form.querySelectorAll("[data-create-server-config]").forEach((button) => {
        button.addEventListener("click", () => {
            runAction(() =>
                createArmaServerConfig(
                    button.dataset.configTemplate || "server",
                    button.dataset.configTarget || "config",
                    button.dataset.defaultFile || "server.cfg",
                ),
            );
        });
    });

    form.querySelectorAll("[data-edit-server-config]").forEach((button) => {
        button.addEventListener("click", () => {
            const target = button.dataset.configTarget || "config";
            const path = document
                .querySelector(`[data-arg-key="${target}"]`)
                ?.value.trim();
            if (!path) {
                alert("Select or create a config first.");
                return;
            }
            runAction(() => openConfigEditor(resolveArmaConfigPath(path)));
        });
    });

    form.querySelectorAll("[data-surreal-install]").forEach((button) => {
        button.addEventListener("click", () => {
            const version = selectedSurrealInstallVersion();
            runAction(() => installSurrealDb(version));
        });
    });

    form.querySelectorAll("[data-surreal-version-mode]").forEach((select) => {
        select.addEventListener("change", () => {
            syncSurrealCustomVersion();
        });
    });

    if (name === "surrealdb" && !surrealInstallInfo) {
        loadSurrealInstallInfo();
    } else if (
        name === "surrealdb" &&
        surrealInstallInfo &&
        !surrealInstallInfo.latest
    ) {
        loadLatestSurrealVersion();
    }
}

function isSettingsViewActive() {
    return views.settings.classList.contains("active");
}

function isLogsViewActive() {
    return views.logs.classList.contains("active");
}

function syncRefreshTimer() {
    if (refreshTimer) {
        clearInterval(refreshTimer);
        refreshTimer = null;
    }

    if (!isSettingsViewActive()) {
        refreshTimer = setInterval(refresh, isLogsViewActive() ? 30000 : 2500);
    }
}

function syncBulkActionsVisibility() {
    const bulkActions = document.getElementById("bulkActions");
    bulkActions.style.display = views.overview.classList.contains("active")
        ? "flex"
        : "none";

    const stopAllButton = document.getElementById("stopAllButton");
    const hasRunningService = Boolean(
        snapshot?.statuses.some((status) => status.running),
    );
    stopAllButton.disabled = !hasRunningService;
}

function renderLogs() {
    const output = document.getElementById("logOutput");
    const nextLogText = snapshot.logs.length
        ? snapshot.logs.join("\n")
        : "No host logs yet.";
    if (nextLogText === lastRenderedLogText) return;

    lastRenderedLogText = nextLogText;
    output.textContent = nextLogText;
    output.scrollTop = output.scrollHeight;
}

function renderError(error) {
    const message = String(error);
    document.getElementById("configPath").textContent = "Unable to load";
    document.getElementById("serviceGrid").replaceChildren();
    document.getElementById("configForm").replaceChildren();
    lastRenderedLogText = message;
    document.getElementById("logOutput").textContent = message;
}

function readFormConfig() {
    const config = structuredClone(snapshot.config);
    document.querySelectorAll("[data-service][data-field]").forEach((input) => {
        const service = input.dataset.service;
        const field = input.dataset.field;
        if (field === "enabled") {
            config[service][field] = input.checked;
        } else if (field === "health_port") {
            config[service][field] = Number(input.value);
        } else if (field === "args") {
            config[service][field] = readArgumentFields(service, input);
        } else {
            config[service][field] = input.value.trim();
        }
    });
    return config;
}

function renderSettingsPanel(name, config) {
    if (name === "arma") {
        return renderArmaSettings(config);
    }
    if (name === "icom") {
        return renderIcomSettings(config);
    }

    return `
    <section class="settings-panel active">
      <div class="settings-header">
        <h2>${serviceNames[name] || name}</h2>
        <label class="toggle-row">
          <input type="checkbox" data-service="${name}" data-field="enabled" ${config.enabled ? "checked" : ""} />
          <span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span>
          <span>Enabled</span>
        </label>
      </div>
      <div class="field-grid">
        ${renderSurrealInstallControls()}
        <div class="field full">
          <label>Working Directory</label>
          <input data-service="${name}" data-field="working_dir" value="${escapeAttr(config.working_dir)}" />
        </div>
        <div class="field">
          <label>Health Host</label>
          <input data-service="${name}" data-field="health_host" value="${escapeAttr(config.health_host)}" />
        </div>
        <div class="field">
          <label>Health Port</label>
          <input data-service="${name}" data-field="health_port" type="number" min="1" max="65535" value="${config.health_port}" />
        </div>
        <div class="field full">
          <label>Arguments</label>
          <div class="args-list" data-service="${name}" data-field="args">
            ${renderArgumentFields(name, config.args)}
          </div>
        </div>
      </div>
    </section>
  `;
}

function renderSurrealInstallControls() {
    const installed = surrealInstallInfo?.installed;
    const version = surrealInstallInfo?.version || "Not installed";
    const latest = surrealInstallInfo?.latest || "Checking...";
    const path =
        surrealInstallInfo?.path ||
        "SurrealDB will be installed to the user-local default path.";

    return `
    <div class="field full surreal-install">
      <div class="install-summary">
        <div>
          <label>SurrealDB Install</label>
          <strong>${escapeHtml(version)}</strong>
          <span>${escapeHtml(path)}</span>
        </div>
        <div>
          <label>Latest</label>
          <strong>${escapeHtml(latest)}</strong>
          <span>${installed ? "Choose a target version when updating." : "Install before starting SurrealDB."}</span>
        </div>
      </div>
      <div class="install-action">
        <label class="install-version">
          <span>Target</span>
          <select data-surreal-version-mode>
            <option value="3" selected>3.x</option>
            <option value="2">2.x</option>
            <option value="latest">Latest</option>
            <option value="custom">Custom</option>
          </select>
        </label>
        <label class="install-custom" hidden>
          <span>Custom Version</span>
          <input data-surreal-custom-version placeholder="v3.1.3" />
        </label>
        <button type="button" data-surreal-install>${installed ? "Update" : "Install"}</button>
      </div>
    </div>
  `;
}

function selectedSurrealInstallVersion() {
    const mode =
        document.querySelector("[data-surreal-version-mode]")?.value || "3";
    if (mode !== "custom") {
        return mode;
    }
    return (
        document.querySelector("[data-surreal-custom-version]")?.value.trim() ||
        "3"
    );
}

function syncSurrealCustomVersion() {
    const custom = document.querySelector(".install-custom");
    if (!custom) return;
    const isCustom =
        document.querySelector("[data-surreal-version-mode]")?.value ===
        "custom";
    custom.hidden = !isCustom;
    if (isCustom) {
        custom.querySelector("input")?.focus();
    }
}

async function loadSurrealInstallInfo() {
    try {
        surrealInstallInfo = await tauriInvoke("get_surrealdb_install_info");
        if (
            activeSettingsService === "surrealdb" &&
            isSettingsViewActive() &&
            !configDirty &&
            !isSurrealInstallFocused()
        ) {
            renderSettings(true);
        }
        await loadLatestSurrealVersion();
    } catch (error) {
        surrealInstallInfo = {
            installed: false,
            version: "Unable to check",
            path: String(error),
            latest: "Unknown",
        };
    }
}

async function loadLatestSurrealVersion() {
    try {
        const latest = await tauriInvoke("get_latest_surrealdb_version");
        surrealInstallInfo = { ...(surrealInstallInfo || {}), latest };
        if (
            activeSettingsService === "surrealdb" &&
            isSettingsViewActive() &&
            !configDirty &&
            !isSurrealInstallFocused()
        ) {
            renderSettings(true);
        }
    } catch (error) {
        surrealInstallInfo = {
            ...(surrealInstallInfo || {}),
            latest: "Unavailable",
        };
        if (
            activeSettingsService === "surrealdb" &&
            isSettingsViewActive() &&
            !configDirty &&
            !isSurrealInstallFocused()
        ) {
            renderSettings(true);
        }
    }
}

function isSurrealInstallFocused() {
    return Boolean(document.activeElement?.closest?.(".surreal-install"));
}

async function installSurrealDb(version) {
    surrealInstallInfo = await tauriInvoke("install_surrealdb", { version });
    await refresh();
    if (activeSettingsService === "surrealdb" && isSettingsViewActive()) {
        renderSettings(true);
    }
}

function renderIcomSettings(config) {
    return `
    <section class="settings-panel active">
      <div class="settings-header">
        <h2>ICOM</h2>
        <label class="toggle-row">
          <input type="checkbox" data-service="icom" data-field="enabled" ${config.enabled ? "checked" : ""} />
          <span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span>
          <span>Enabled</span>
        </label>
      </div>
      <div class="field-grid">
        <div class="field with-button full">
          <label>ICOM Executable</label>
          <div class="input-action action-one">
            <input data-service="icom" data-field="command" value="${escapeAttr(config.command)}" placeholder="forge-icom.exe" />
            <button class="icon-button" type="button" data-picker="file" data-service-target="icom" data-target='[data-service="icom"][data-field="command"]' title="Select executable" aria-label="Select executable"><span class="svg-icon icon-browse"></span></button>
          </div>
        </div>
        <div class="field with-button full">
          <label>Working Directory</label>
          <div class="input-action action-one">
            <input data-service="icom" data-field="working_dir" value="${escapeAttr(config.working_dir)}" />
            <button class="icon-button" type="button" data-picker="directory" data-service-target="icom" data-target='[data-service="icom"][data-field="working_dir"]' title="Select folder" aria-label="Select folder"><span class="svg-icon icon-browse"></span></button>
          </div>
        </div>
        <div class="field">
          <label>Health Host</label>
          <input data-service="icom" data-field="health_host" value="${escapeAttr(config.health_host)}" />
        </div>
        <div class="field">
          <label>Health Port</label>
          <input data-service="icom" data-field="health_port" type="number" min="1" max="65535" value="${config.health_port}" />
        </div>
        <div class="field full">
          <label>Arguments</label>
          <div class="args-list" data-service="icom" data-field="args">
            ${renderArgumentFields("icom", config.args)}
          </div>
        </div>
      </div>
    </section>
  `;
}

function renderArmaSettings(config) {
    const parsed = parseArmaArgs(config.args);
    return `
    <section class="settings-panel active">
      <div class="settings-header">
        <h2>Arma Server</h2>
        <label class="toggle-row">
          <input type="checkbox" data-service="arma" data-field="enabled" ${config.enabled ? "checked" : ""} />
          <span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span>
          <span>Enabled</span>
        </label>
      </div>
      <div class="field-grid arma-grid">
        <div class="field with-button full">
          <label>Server Executable</label>
          <div class="input-action action-one">
            <input data-service="arma" data-field="command" value="${escapeAttr(config.command)}" placeholder="arma3server_x64.exe" />
            <button class="icon-button" type="button" data-picker="file" data-service-target="arma" data-target='[data-service="arma"][data-field="command"]' title="Select executable" aria-label="Select executable"><span class="svg-icon icon-browse"></span></button>
          </div>
        </div>
        <div class="field with-button full">
          <label>Server Directory</label>
          <div class="input-action action-one">
            <input data-service="arma" data-field="working_dir" value="${escapeAttr(config.working_dir)}" />
            <button class="icon-button" type="button" data-picker="directory" data-service-target="arma" data-target='[data-service="arma"][data-field="working_dir"]' title="Select folder" aria-label="Select folder"><span class="svg-icon icon-browse"></span></button>
          </div>
        </div>
        <div class="field">
          <label>Health Host</label>
          <input data-service="arma" data-field="health_host" value="${escapeAttr(config.health_host)}" />
        </div>
        <div class="field">
          <label>Health Port</label>
          <input data-service="arma" data-field="health_port" type="number" min="1" max="65535" value="${config.health_port}" />
        </div>
        <div class="field full">
          <label>Launch Options</label>
          <div class="args-list arma-args" data-service="arma" data-field="args">
            ${serverConfigInput(parsed.config)}
            ${basicConfigInput(parsed.cfg)}
            ${argumentInput("Port", "port", parsed.port)}
            ${argumentInput("Profiles", "profiles", parsed.profiles)}
            ${argumentInput("Name", "name", parsed.name)}
            ${argumentInput("Mods", "mods", parsed.mods)}
            ${argumentInput("Server Mods", "serverMods", parsed.serverMods)}
            ${toggleArgument("AutoInit", "autoInit", parsed.autoInit)}
            ${toggleArgument("ReportNonNetworkObject", "reportNonNetworkObject", parsed.reportNonNetworkObject)}
            ${toggleArgument("BattlEye", "battleye", parsed.battleye)}
            ${argumentInput("Misc Arguments", "misc", parsed.misc.join(" "), "full")}
          </div>
        </div>
      </div>
    </section>
  `;
}

function persistActiveSettingsForm() {
    const form = document.getElementById("configForm");
    if (!snapshot || !form.children.length) return;
    snapshot.config = readFormConfig();
}

function renderArgumentFields(service, args) {
    if (service === "surrealdb") {
        const parsed = parseSurrealArgs(args);
        return `
      ${argumentInput("Subcommand", "subcommand", parsed.subcommand)}
      ${argumentInput("Root User", "user", parsed.user)}
      ${argumentInput("Root Password", "pass", parsed.pass)}
      ${argumentInput("Bind Address", "bind", parsed.bind)}
      ${argumentInput("Database Path", "database", parsed.database)}
      ${argumentInput("Misc Arguments", "misc", parsed.misc.join(" "), "full")}
    `;
    }

    const label = service === "arma" ? "Startup Parameters" : "Misc Arguments";
    return argumentInput(label, "misc", args.join(" "), "full");
}

function argumentInput(label, key, value, className = "") {
    return `
    <div class="arg-field ${className}">
      <label>${label}</label>
      <input class="arg-input" data-arg-key="${key}" value="${escapeAttr(value)}" />
    </div>
  `;
}

function serverConfigInput(value) {
    return configFileInput({
        label: "Server Config",
        key: "config",
        value,
        placeholder: "server.cfg",
        template: "server",
        defaultFile: "server.cfg",
    });
}

function basicConfigInput(value) {
    return configFileInput({
        label: "Basic Network Config",
        key: "cfg",
        value,
        placeholder: "basic.cfg",
        template: "basic",
        defaultFile: "basic.cfg",
    });
}

function configFileInput({
    label,
    key,
    value,
    placeholder,
    template,
    defaultFile,
}) {
    const target = `[data-arg-key="${key}"]`;
    return `
    <div class="arg-field full">
      <label>${label}</label>
      <div class="input-action action-three">
        <input class="arg-input" data-arg-key="${key}" value="${escapeAttr(value)}" placeholder="${placeholder}" />
        <button class="icon-button" type="button" data-picker="config" data-service-target="arma" data-target='${target}' title="Select config" aria-label="Select config"><span class="svg-icon icon-browse"></span></button>
        <button class="icon-button" type="button" data-create-server-config data-config-template="${template}" data-config-target="${key}" data-default-file="${defaultFile}" title="Create default config" aria-label="Create default config"><span class="svg-icon icon-new"></span></button>
        <button class="icon-button" type="button" data-edit-server-config data-config-target="${key}" title="Edit config" aria-label="Edit config"><span class="svg-icon icon-edit"></span></button>
      </div>
    </div>
  `;
}

function toggleArgument(label, key, value) {
    return `
    <label class="arg-toggle">
      <input type="checkbox" class="arg-input" data-arg-key="${key}" ${value ? "checked" : ""} />
      ${label}
    </label>
  `;
}

function readArgumentFields(service, container) {
    const value = (key) =>
        container.querySelector(`[data-arg-key="${key}"]`)?.value.trim() || "";
    const checked = (key) =>
        Boolean(container.querySelector(`[data-arg-key="${key}"]`)?.checked);
    if (service === "surrealdb") {
        const args = [];
        if (value("subcommand")) args.push(value("subcommand"));
        if (value("user")) args.push("--user", value("user"));
        if (value("pass")) args.push("--pass", value("pass"));
        if (value("bind")) args.push("--bind", value("bind"));
        args.push(...splitMiscArgs(value("misc")));
        if (value("database")) args.push(value("database"));
        return args;
    }

    if (service === "arma") {
        const args = [];
        if (value("config")) args.push(`-config=${value("config")}`);
        if (value("cfg")) args.push(`-cfg=${value("cfg")}`);
        if (value("port")) args.push(`-port=${value("port")}`);
        if (value("profiles")) args.push(`-profiles=${value("profiles")}`);
        if (value("name")) args.push(`-name=${value("name")}`);
        if (value("mods")) args.push(`-mod=${value("mods")}`);
        if (value("serverMods")) args.push(`-serverMod=${value("serverMods")}`);
        checked("autoInit") && args.push("-autoInit");
        checked("reportNonNetworkObject") &&
            args.push("-reportNonNetworkObject");
        args.push(checked("battleye") ? "-battleye" : "-noBattlEye");
        args.push(...splitMiscArgs(value("misc")));
        return args;
    }

    return splitMiscArgs(value("misc"));
}

function parseSurrealArgs(args) {
    const parsed = {
        subcommand: "",
        user: "",
        pass: "",
        bind: "",
        database: "",
        misc: [],
    };

    const remaining = [...args];
    if (remaining[0] && !remaining[0].startsWith("-")) {
        parsed.subcommand = remaining.shift();
    }

    for (let index = 0; index < remaining.length; index += 1) {
        const arg = remaining[index];
        if (arg === "--user") {
            parsed.user = remaining[++index] || "";
        } else if (arg === "--pass") {
            parsed.pass = remaining[++index] || "";
        } else if (arg === "--bind") {
            parsed.bind = remaining[++index] || "";
        } else if (!arg.startsWith("-")) {
            parsed.database = arg;
        } else {
            parsed.misc.push(arg);
        }
    }

    return parsed;
}

function parseArmaArgs(args) {
    const parsed = {
        config: "",
        cfg: "",
        port: "",
        profiles: "",
        name: "",
        mods: "",
        serverMods: "",
        autoInit: false,
        reportNonNetworkObject: false,
        battleye: true,
        misc: [],
    };

    for (const arg of args) {
        if (!arg) continue;
        const lowerArg = arg.toLowerCase();

        if (lowerArg.startsWith("-config=")) {
            parsed.config = arg.slice("-config=".length);
        } else if (lowerArg.startsWith("-cfg=")) {
            parsed.cfg = arg.slice("-cfg=".length);
        } else if (lowerArg.startsWith("-port=")) {
            parsed.port = arg.slice("-port=".length);
        } else if (lowerArg.startsWith("-profiles=")) {
            parsed.profiles = arg.slice("-profiles=".length);
        } else if (lowerArg.startsWith("-name=")) {
            parsed.name = arg.slice("-name=".length);
        } else if (lowerArg.startsWith("-mod=")) {
            parsed.mods = arg.slice("-mod=".length);
        } else if (lowerArg.startsWith("-servermod=")) {
            parsed.serverMods = arg.slice("-serverMod=".length);
        } else if (lowerArg === "-nobattleye") {
            parsed.battleye = false;
        } else if (lowerArg === "-battleye") {
            parsed.battleye = true;
        } else if (lowerArg === "-autoinit") {
            parsed.autoInit = true;
        } else if (lowerArg === "-reportnonnetworkobject") {
            parsed.reportNonNetworkObject = true;
        } else {
            parsed.misc.push(arg);
        }
    }

    return parsed;
}

function splitMiscArgs(value) {
    return value
        .split(/\s+/)
        .map((arg) => arg.trim())
        .filter(Boolean);
}

async function pickPath(kind, targetSelector, service) {
    const open = window.__TAURI__?.dialog?.open;
    if (!open) {
        throw new Error("Tauri dialog API is not available in this window.");
    }

    const selected = await open({
        multiple: false,
        directory: kind === "directory",
        filters: pickerFilters(kind),
    });
    if (!selected) return;

    const input = document.querySelector(targetSelector);
    if (!input) return;
    const finalPath =
        kind === "file"
            ? normalizePickedExecutable(service, selected)
            : selected;
    input.value = finalPath;

    if (kind === "file" && targetSelector.includes('data-field="command"')) {
        const workingDir = document.querySelector(
            `[data-service="${service}"][data-field="working_dir"]`,
        );
        if (workingDir) {
            workingDir.value = finalPath.replace(/[\\/][^\\/]+$/, "");
        }
    }

    configDirty = true;
    persistActiveSettingsForm();

    if (kind === "config") {
        await openConfigEditor(resolveArmaConfigPath(finalPath));
    }
}

function pickerFilters(kind) {
    if (kind === "file") {
        return [{ name: "Executable", extensions: ["exe"] }];
    }
    if (kind === "config") {
        return [{ name: "Arma Server Config", extensions: ["cfg"] }];
    }
    return undefined;
}

async function createArmaServerConfig(template, targetKey, defaultFile) {
    const save = window.__TAURI__?.dialog?.save;
    if (!save) {
        throw new Error(
            "Tauri save dialog API is not available in this window.",
        );
    }

    const workingDir = document
        .querySelector('[data-service="arma"][data-field="working_dir"]')
        ?.value.trim();
    const defaultPath = workingDir
        ? `${workingDir}\\${defaultFile}`
        : defaultFile;
    const selected = await save({
        defaultPath,
        filters: [{ name: "Arma Server Config", extensions: ["cfg"] }],
    });
    if (!selected) return;

    await tauriInvoke("create_arma_server_config", {
        path: selected,
        template,
    });
    const input = document.querySelector(`[data-arg-key="${targetKey}"]`);
    if (input) {
        input.value = selected;
        configDirty = true;
        persistActiveSettingsForm();
    }
    await openConfigEditor(selected);
}

function resolveArmaConfigPath(path) {
    if (/^[a-zA-Z]:[\\/]/.test(path) || path.startsWith("\\\\")) {
        return path;
    }

    const workingDir = document
        .querySelector('[data-service="arma"][data-field="working_dir"]')
        ?.value.trim();
    return workingDir ? `${workingDir}\\${path}` : path;
}

async function openConfigEditor(path) {
    if (!path) return;
    activeEditorPath = path;
    const content = await tauriInvoke("read_text_file", { path });
    document.getElementById("editorPath").textContent = path;
    document.getElementById("configEditor").value = content;
    document.getElementById("editorOverlay").hidden = false;
    document.getElementById("configEditor").focus();
}

function closeConfigEditor() {
    document.getElementById("editorOverlay").hidden = true;
}

async function saveConfigEditor() {
    if (!activeEditorPath) return;
    const content = document.getElementById("configEditor").value;
    await tauriInvoke("write_text_file", { path: activeEditorPath, content });
}

function normalizePickedExecutable(service, path) {
    if (service !== "arma") {
        return path;
    }

    const fileName = path.split(/[\\/]/).pop()?.toLowerCase() || "";
    if (isArmaServerExecutable(fileName)) {
        return path;
    }

    if (fileName === "arma3_x64.exe" || fileName === "arma3.exe") {
        alert(
            "That is the Arma 3 client executable. Forge Host will use arma3server_x64.exe from the same directory instead.",
        );
        return path.replace(/[\\/][^\\/]+$/, "\\arma3server_x64.exe");
    }

    alert(
        "Select arma3server_x64.exe for dedicated server hosting. The app will block client executables at launch.",
    );
    return path;
}

function isArmaServerExecutable(fileName) {
    return fileName.startsWith("arma3server");
}

async function runAction(action) {
    try {
        await action();
    } catch (error) {
        alert(String(error));
        await refresh();
    }
}

function escapeHtml(value) {
    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;");
}

function escapeAttr(value) {
    return escapeHtml(value).replaceAll('"', "&quot;");
}

refresh();
syncRefreshTimer();
loadAppVersion();

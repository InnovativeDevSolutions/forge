(function () {
    const state = {
        factions: [],
        settings: {
            enemyFaction: "IND_G_F",
            maxConcurrentMissions: 3,
            missionInterval: 300,
            locationReuseCooldown: 900,
            moneyMin: 500,
            moneyMax: 1000,
            reputationMin: 25,
            reputationMax: 100,
            penaltyMin: -5,
            penaltyMax: -25,
            timeLimitMin: 600,
            timeLimitMax: 900,
        },
        error: "",
    };

    function send(event, data = {}) {
        if (!window.A3API || typeof window.A3API.SendAlert !== "function") {
            return false;
        }

        window.A3API.SendAlert(JSON.stringify({ event, data }));
        return true;
    }

    function fieldNumber(id) {
        const value = Number(document.getElementById(id)?.value || 0);
        return Number.isFinite(value) ? value : 0;
    }

    function readSettings() {
        return {
            enemyFaction: String(document.getElementById("enemyFaction")?.value || "IND_G_F"),
            maxConcurrentMissions: fieldNumber("maxConcurrentMissions"),
            missionInterval: fieldNumber("missionInterval"),
            locationReuseCooldown: fieldNumber("locationReuseCooldown"),
            moneyMin: fieldNumber("moneyMin"),
            moneyMax: fieldNumber("moneyMax"),
            reputationMin: fieldNumber("reputationMin"),
            reputationMax: fieldNumber("reputationMax"),
            penaltyMin: fieldNumber("penaltyMin"),
            penaltyMax: fieldNumber("penaltyMax"),
            timeLimitMin: fieldNumber("timeLimitMin"),
            timeLimitMax: fieldNumber("timeLimitMax"),
        };
    }

    function escapeHtml(value) {
        return String(value ?? "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function apply() {
        const settings = readSettings();
        if (settings.moneyMax < settings.moneyMin) {
            state.error = "Money max must be greater than or equal to money min.";
            render();
            return;
        }

        if (settings.reputationMax < settings.reputationMin) {
            state.error = "Reputation max must be greater than or equal to reputation min.";
            render();
            return;
        }

        if (settings.penaltyMin > 0 || settings.penaltyMax > 0) {
            state.error = "Reputation hits must be zero or negative values.";
            render();
            return;
        }

        if (settings.timeLimitMax < settings.timeLimitMin) {
            state.error = "Time limit max must be greater than or equal to time limit min.";
            render();
            return;
        }

        state.error = "";
        send("missionSetup::apply", settings);
    }

    function close() {
        send("missionSetup::cancel", {});
    }

    function option(faction) {
        const selected = faction.faction === state.settings.enemyFaction ? " selected" : "";
        return `<option value="${escapeHtml(faction.faction)}"${selected}>${escapeHtml(faction.display)}</option>`;
    }

    function render() {
        const settings = state.settings;
        const faction = state.factions.find((item) => item.faction === settings.enemyFaction);
        const factionLabel = faction ? faction.display : settings.enemyFaction;

        document.getElementById("app").innerHTML = `
            <div class="shell">
                <header class="titlebar">
                    <div class="brand">
                        <span class="kicker">FORGE</span>
                        <span class="title">Mission Setup</span>
                    </div>
                    <button class="close" type="button" aria-label="Close" data-action="close">x</button>
                </header>

                <main class="content">
                    <div class="grid">
                        <section class="panel">
                            <div class="panel-head">
                                <span class="kicker">Deployment Profile</span>
                                <h1>Operation Settings</h1>
                            </div>
                            <div class="form">
                                <div class="field">
                                    <label for="enemyFaction">Opposing Faction</label>
                                    <select id="enemyFaction">${state.factions.map(option).join("")}</select>
                                </div>
                                <div class="field">
                                    <label for="locationReuseCooldown">Location Cooldown</label>
                                    <input id="locationReuseCooldown" type="number" min="0" step="60" value="${settings.locationReuseCooldown}" />
                                </div>
                                <div class="field">
                                    <label for="maxConcurrentMissions">Concurrent Missions</label>
                                    <input id="maxConcurrentMissions" type="number" min="1" max="50" value="${settings.maxConcurrentMissions}" />
                                </div>
                                <div class="field">
                                    <label for="missionInterval">Mission Interval</label>
                                    <input id="missionInterval" type="number" min="1" step="30" value="${settings.missionInterval}" />
                                </div>
                                <div class="field">
                                    <label for="moneyMin">Min Funds</label>
                                    <input id="moneyMin" type="number" min="0" step="100" value="${settings.moneyMin}" />
                                </div>
                                <div class="field">
                                    <label for="moneyMax">Max Funds</label>
                                    <input id="moneyMax" type="number" min="0" step="100" value="${settings.moneyMax}" />
                                </div>
                                <div class="field">
                                    <label for="reputationMin">Min Rating</label>
                                    <input id="reputationMin" type="number" step="1" value="${settings.reputationMin}" />
                                </div>
                                <div class="field">
                                    <label for="reputationMax">Max Rating</label>
                                    <input id="reputationMax" type="number" step="1" value="${settings.reputationMax}" />
                                </div>
                                <div class="field">
                                    <label for="penaltyMin">Min Rep Hit</label>
                                    <input id="penaltyMin" type="number" max="0" step="1" value="${settings.penaltyMin}" />
                                </div>
                                <div class="field">
                                    <label for="penaltyMax">Max Rep Hit</label>
                                    <input id="penaltyMax" type="number" max="0" step="1" value="${settings.penaltyMax}" />
                                </div>
                                <div class="field">
                                    <label for="timeLimitMin">Min Time</label>
                                    <input id="timeLimitMin" type="number" min="1" step="60" value="${settings.timeLimitMin}" />
                                </div>
                                <div class="field">
                                    <label for="timeLimitMax">Max Time</label>
                                    <input id="timeLimitMax" type="number" min="1" step="60" value="${settings.timeLimitMax}" />
                                </div>
                            </div>
                        </section>

                        <aside class="panel">
                            <div class="panel-head">
                                <span class="kicker">Current Selection</span>
                                <h2>Generator Runtime</h2>
                            </div>
                            <div class="summary">
                                <div class="summary-row"><span>Faction</span><strong>${escapeHtml(factionLabel)}</strong></div>
                                <div class="summary-row"><span>Mission Cap</span><strong>${settings.maxConcurrentMissions}</strong></div>
                                <div class="summary-row"><span>Interval</span><strong>${settings.missionInterval}s</strong></div>
                                <div class="summary-row"><span>Location Cooldown</span><strong>${settings.locationReuseCooldown}s</strong></div>
                                <div class="summary-row"><span>Reward Range</span><strong>$${Number(settings.moneyMin).toLocaleString()} - $${Number(settings.moneyMax).toLocaleString()}</strong></div>
                                <div class="summary-row"><span>Reputation</span><strong>${settings.reputationMin} - ${settings.reputationMax}</strong></div>
                                <div class="summary-row"><span>Reputation Hit</span><strong>${settings.penaltyMin} to ${settings.penaltyMax}</strong></div>
                                <div class="summary-row"><span>Time Limit</span><strong>${settings.timeLimitMin}s - ${settings.timeLimitMax}s</strong></div>
                                ${state.error ? `<div class="notice">${state.error}</div>` : ""}
                            </div>
                        </aside>
                    </div>
                </main>

                <footer class="actions">
                    <button class="btn secondary" type="button" data-action="close">Cancel</button>
                    <button class="btn primary" type="button" data-action="apply">Apply Settings</button>
                </footer>
            </div>
        `;

        document.querySelectorAll("input, select").forEach((input) => {
            input.addEventListener("change", () => {
                state.settings = readSettings();
                render();
            });
        });

        document.querySelectorAll("[data-action='close']").forEach((button) => {
            button.addEventListener("click", close);
        });

        document.querySelector("[data-action='apply']").addEventListener("click", apply);
    }

    window.MissionSetupBridge = {
        receive(payload) {
            if (!payload || typeof payload !== "object") {
                return false;
            }

            if (payload.event === "missionSetup::hydrate") {
                let factions = Array.isArray(payload.data?.factions) ? payload.data.factions : [];
                const seen = new Set();
                factions = factions.filter((faction) => {
                    const key = ((faction.display || faction.faction) + "").toLowerCase().trim();
                    if (seen.has(key)) {
                        return false;
                    }
                    seen.add(key);
                    return true;
                });
                state.factions = factions;
                state.settings = Object.assign({}, state.settings, payload.data?.settings || {});
                render();
                return true;
            }

            if (payload.event === "missionSetup::error") {
                state.error = String(payload.data?.message || "Mission setup failed.");
                render();
                return true;
            }

            return false;
        },
    };

    render();
    send("missionSetup::ready", { loaded: true });
})();

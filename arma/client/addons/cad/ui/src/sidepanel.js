window.cadTasks = {
    contracts: [],
    requests: [],
    groups: [],
    activity: [],
    session: {},
    mode: "operations",
    dispatchView: "board",
    activeTab: "contracts",
    selectedDispatchGroupId: "",
    selectedDispatchTaskId: "",
    selectedDispatchRequestId: "",
    selectedRosterMemberUid: "",
    focusStatusTimer: null,
    requestModalType: "",
    statuses: [
        "available",
        "en_route",
        "on_task",
        "holding",
        "danger",
        "unavailable",
    ],
    roles: ["infantry", "recon", "armor", "air", "logistics", "support"],
    requestTypes: [
        {
            id: "medevac_9line",
            label: "9-Line MEDEVAC",
            defaultPriority: "emergency",
            fields: [
                {
                    id: "pickup_location",
                    label: "Line 1 Pickup Location",
                    type: "text",
                    defaultFromGroupPosition: true,
                },
                {
                    id: "radio_freq",
                    label: "Line 2 Radio / Call Sign",
                    type: "text",
                },
                {
                    id: "precedence",
                    label: "Line 3 Precedence",
                    type: "select",
                    options: [
                        "urgent",
                        "urgent_surgical",
                        "priority",
                        "routine",
                        "convenience",
                    ],
                },
                {
                    id: "special_equipment",
                    label: "Line 4 Special Equipment",
                    type: "select",
                    options: ["none", "hoist", "extraction", "ventilator"],
                },
                {
                    id: "patient_type",
                    label: "Line 5 Patient Type",
                    type: "select",
                    options: ["litter", "ambulatory", "mixed"],
                },
                {
                    id: "security",
                    label: "Line 6 Security",
                    type: "select",
                    options: [
                        "secure",
                        "possible_enemy",
                        "enemy_in_area",
                        "hot",
                    ],
                },
                {
                    id: "marking",
                    label: "Line 7 Marking",
                    type: "select",
                    options: ["panels", "smoke", "ir", "none", "other"],
                },
                {
                    id: "patient_nationality",
                    label: "Line 8 Patient Nationality",
                    type: "select",
                    options: ["coalition", "civilian", "enemy", "epw", "mixed"],
                },
                {
                    id: "terrain",
                    label: "Line 9 Terrain",
                    type: "select",
                    options: [
                        "flat",
                        "restricted",
                        "slope",
                        "rooftop",
                        "wooded",
                    ],
                },
            ],
        },
        {
            id: "ace_lace",
            label: "ACE/LACE",
            defaultPriority: "routine",
            fields: [
                { id: "ammo", label: "Ammo", type: "textarea" },
                { id: "casualties", label: "Casualties", type: "textarea" },
                { id: "equipment", label: "Equipment", type: "textarea" },
                { id: "notes", label: "Notes", type: "textarea" },
            ],
        },
        {
            id: "fire_support",
            label: "Fire Support",
            defaultPriority: "priority",
            fields: [
                {
                    id: "target_location",
                    label: "Target Location",
                    type: "text",
                    defaultFromGroupPosition: true,
                },
                {
                    id: "target_description",
                    label: "Target Description",
                    type: "textarea",
                },
                {
                    id: "requested_effect",
                    label: "Requested Effect",
                    type: "select",
                    options: [
                        "suppress",
                        "destroy",
                        "illum",
                        "smoke",
                        "screen",
                    ],
                },
                { id: "ordnance", label: "Requested Ordnance", type: "text" },
                {
                    id: "danger_close",
                    label: "Danger Close",
                    type: "select",
                    options: ["no", "yes"],
                },
                { id: "remarks", label: "Remarks", type: "textarea" },
            ],
        },
        {
            id: "air_support",
            label: "Air Support",
            defaultPriority: "priority",
            fields: [
                {
                    id: "target_location",
                    label: "Target Location",
                    type: "text",
                    defaultFromGroupPosition: true,
                },
                {
                    id: "target_description",
                    label: "Target Description",
                    type: "textarea",
                },
                {
                    id: "target_marking",
                    label: "Target Marking",
                    type: "select",
                    options: ["smoke", "ir", "laser", "grid", "visual"],
                },
                {
                    id: "requested_effect",
                    label: "Requested Effect",
                    type: "select",
                    options: [
                        "show_of_force",
                        "escort",
                        "suppress",
                        "destroy",
                        "recon",
                    ],
                },
                { id: "remarks", label: "Remarks", type: "textarea" },
            ],
        },
        {
            id: "logreq",
            label: "LOGREQ",
            defaultPriority: "priority",
            fields: [
                {
                    id: "category",
                    label: "Category",
                    type: "select",
                    options: [
                        "ammo",
                        "medical",
                        "fuel",
                        "repair",
                        "vehicle",
                        "equipment",
                        "weapons",
                        "mixed",
                    ],
                },
                {
                    id: "delivery_method",
                    label: "Delivery Method",
                    type: "select",
                    options: [
                        "ground",
                        "airdrop",
                        "pickup",
                        "dispatch_discretion",
                    ],
                },
                {
                    id: "delivery_location",
                    label: "Delivery Location",
                    type: "text",
                    defaultFromGroupPosition: true,
                },
                {
                    id: "requested_items",
                    label: "Requested Items",
                    type: "textarea",
                },
                {
                    id: "quantity",
                    label: "Quantity / Package",
                    type: "text",
                },
                {
                    id: "remarks",
                    label: "Remarks",
                    type: "textarea",
                },
            ],
        },
    ],
    init() {
        document.querySelectorAll(".cad-tab").forEach((tab) => {
            tab.addEventListener("click", () => {
                this.setActiveTab(tab.dataset.tab || "contracts");
            });
        });

        document
            .getElementById("cadRequestModalCloseBtn")
            .addEventListener("click", () => {
                this.closeRequestModal();
            });

        document
            .getElementById("cadRequestModalSaveBtn")
            .addEventListener("click", () => {
                this.submitSupportRequest();
            });

        document
            .querySelector("#cadRequestModal .cad-modal-backdrop")
            .addEventListener("click", () => {
                this.closeRequestModal();
            });

        window.ForgeBridge.on("cad::hydrate", (payload) => {
            this.setHydratePayload(payload || {});
        });

        window.ForgeBridge.on("cad::assignment::response", (payload) => {
            this.handleServerResponse(!!payload.success, payload.message || "");
        });

        window.ForgeBridge.on("cad::group::response", (payload) => {
            this.handleServerResponse(!!payload.success, payload.message || "");
        });

        window.ForgeBridge.on("cad::request::response", (payload) => {
            this.handleServerResponse(!!payload.success, payload.message || "");
        });

        window.ForgeBridge.ready({ loaded: true });
    },
    setActiveTab(tabName) {
        this.activeTab = tabName || "contracts";

        document.querySelectorAll(".cad-tab").forEach((tab) => {
            tab.classList.toggle(
                "is-active",
                tab.dataset.tab === this.activeTab,
            );
        });

        document.querySelectorAll("[data-panel]").forEach((panel) => {
            panel.classList.toggle(
                "is-active",
                panel.dataset.panel === this.activeTab,
            );
        });
    },
    syncLayoutState() {
        const tabsEl = document.querySelector(".cad-tabs");
        const contractsTab = document.getElementById("tabContractsBtn");
        const rosterTab = document.getElementById("tabRosterBtn");
        const requestsTab = document.getElementById("tabRequestsBtn");
        const activityTab = document.getElementById("tabActivityBtn");
        const contractsPanel = document.getElementById("contractsPanel");
        const rosterPanel = document.getElementById("rosterPanel");
        const requestsPanel = document.getElementById("requestsPanel");
        const activityPanel = document.getElementById("activityPanel");
        const contractsHeader = contractsPanel?.querySelector(
            ".cad-section-header",
        );
        const rosterHeader = rosterPanel?.querySelector(".cad-section-header");

        if (this.isDispatchMapMode()) {
            if (tabsEl) {
                tabsEl.style.display = "";
                tabsEl.classList.remove("is-two-col");
                tabsEl.classList.add("is-three-col");
            }
            if (contractsTab) {
                contractsTab.style.display = "";
            }
            if (rosterTab) {
                rosterTab.textContent = "Groups";
            }
            if (activityTab) {
                activityTab.style.display = "none";
            }
            if (requestsTab) {
                requestsTab.style.display = "";
            }
            if (activityPanel) {
                activityPanel.classList.remove("is-active");
                activityPanel.style.display = "none";
            }
            if (requestsPanel) {
                requestsPanel.style.display = "";
            }
            if (rosterPanel) {
                rosterPanel.style.display = "";
            }
            if (rosterHeader) {
                rosterHeader.textContent = "Active Groups";
            }
            if (contractsPanel) {
                contractsPanel.style.display = "";
            }
            if (contractsHeader) {
                contractsHeader.textContent = "Contracts";
            }
            if (!["contracts", "roster", "requests"].includes(this.activeTab)) {
                this.activeTab = "contracts";
            }
            return;
        }

        if (tabsEl) {
            tabsEl.style.display = "";
            tabsEl.classList.remove("is-three-col");
            tabsEl.classList.remove("is-two-col");
        }
        if (contractsTab) {
            contractsTab.style.display = "";
        }
        if (rosterTab) {
            rosterTab.textContent = "Roster";
        }
        if (activityTab) {
            activityTab.style.display = "";
        }
        if (requestsTab) {
            requestsTab.style.display = "";
        }
        if (contractsPanel) {
            contractsPanel.style.display = "";
        }
        if (activityPanel) {
            activityPanel.style.display = "";
        }
        if (requestsPanel) {
            requestsPanel.style.display = "";
        }
        if (rosterPanel) {
            rosterPanel.style.display = "";
        }
        if (rosterHeader) {
            rosterHeader.textContent = "Roster";
        }
        if (contractsHeader) {
            contractsHeader.textContent = "Contracts";
        }
    },
    setHydratePayload(payload) {
        this.contracts = Array.isArray(payload.contracts)
            ? payload.contracts
            : [];
        this.requests = Array.isArray(payload.requests) ? payload.requests : [];
        this.groups = Array.isArray(payload.groups) ? payload.groups : [];
        this.activity = Array.isArray(payload.activity) ? payload.activity : [];
        this.session =
            payload.session && typeof payload.session === "object"
                ? payload.session
                : {};
        this.mode =
            payload && typeof payload.mode === "string"
                ? payload.mode
                : "operations";
        this.dispatchView =
            payload && typeof payload.dispatchView === "string"
                ? payload.dispatchView
                : "board";

        const statusEl = document.getElementById("cadStatusMessage");
        if (
            statusEl &&
            (!statusEl.dataset.type || statusEl.dataset.type === "info")
        ) {
            this.setStatus("", "");
        }

        if (
            this.selectedDispatchGroupId &&
            !this.groups.some(
                (group) => group.groupId === this.selectedDispatchGroupId,
            )
        ) {
            this.selectedDispatchGroupId = "";
        }

        if (this.selectedRosterMemberUid) {
            const memberExists = this.groups.some((group) =>
                this.normalizeCollection(group.members).some(
                    (member) =>
                        (member.uid || "") === this.selectedRosterMemberUid,
                ),
            );

            if (!memberExists) {
                this.selectedRosterMemberUid = "";
            }
        }

        if (
            this.selectedDispatchTaskId &&
            !this.contracts.some((task) => {
                const taskId = task.taskId || task.taskID || "";
                return taskId === this.selectedDispatchTaskId;
            })
        ) {
            this.selectedDispatchTaskId = "";
        }

        if (
            this.selectedDispatchRequestId &&
            !this.requests.some(
                (request) =>
                    (request.requestId || "") ===
                    this.selectedDispatchRequestId,
            )
        ) {
            this.selectedDispatchRequestId = "";
        }

        if (
            this.mode === "dispatch" &&
            this.dispatchView === "map" &&
            !["contracts", "roster", "requests"].includes(this.activeTab)
        ) {
            this.activeTab = "contracts";
        }

        this.render();
    },
    setStatus(message, type) {
        const statusEl = document.getElementById("cadStatusMessage");
        if (!statusEl) {
            return;
        }

        statusEl.textContent = message || "";
        statusEl.dataset.type = type || "";
    },
    getDangerGroups() {
        return this.groups.filter((group) => (group.status || "") === "danger");
    },
    getSupportAlertRequests() {
        return this.requests.filter((request) =>
            ["medevac_9line", "fire_support", "air_support"].includes(
                request.type || "",
            ),
        );
    },
    buildSupportAlertMessage() {
        const alertRequests = this.getSupportAlertRequests();
        if (!alertRequests.length) {
            return "";
        }

        const labels = alertRequests.map((request) => {
            const groupLabel =
                request.groupCallsign || request.groupId || "Unknown Group";
            const typeLabel = this.getRequestTypeLabel(
                request.type || "request",
            );
            return `${groupLabel} ${typeLabel}`;
        });

        return `Support request alert: ${labels.join(", ")}`;
    },
    getCurrentGroupCoordinates() {
        const currentGroup = this.getCurrentGroup();
        const position = Array.isArray(currentGroup?.position)
            ? currentGroup.position
            : [0, 0, 0];
        return window.mapUI.formatPosition(position);
    },
    getSortedGroups() {
        return this.groups.slice().sort((left, right) => {
            const leftDanger = (left.status || "") === "danger" ? 0 : 1;
            const rightDanger = (right.status || "") === "danger" ? 0 : 1;

            if (leftDanger !== rightDanger) {
                return leftDanger - rightDanger;
            }

            const leftCallsign = left.callsign || left.groupId || "";
            const rightCallsign = right.callsign || right.groupId || "";
            return leftCallsign.localeCompare(rightCallsign);
        });
    },
    isDispatchOrder(entry) {
        return (
            !!entry.isDispatchOrder || (entry.type || "") === "dispatch_order"
        );
    },
    formatTypeLabel(entry) {
        const typeLabel = (entry.type || "task").replaceAll("_", " ");
        return this.isDispatchOrder(entry) ? "dispatch order" : typeLabel;
    },
    getRequestDefinition(typeID) {
        return this.requestTypes.find((entry) => entry.id === typeID) || null;
    },
    getRequestTypeLabel(typeID) {
        return this.getRequestDefinition(typeID)?.label || typeID;
    },
    canSubmitSupportRequest() {
        return this.mode === "operations" && this.isLeader();
    },
    openRequestModal(typeID) {
        const definition = this.getRequestDefinition(typeID);
        if (!definition) {
            return;
        }

        this.requestModalType = typeID;
        document.getElementById("cadRequestModalTitle").textContent =
            definition.label;
        document.getElementById("cadRequestPrioritySelect").value =
            definition.defaultPriority || "priority";
        this.renderRequestFields(definition);
        document
            .getElementById("cadRequestModal")
            .classList.remove("is-hidden");
    },
    closeRequestModal() {
        this.requestModalType = "";
        document.getElementById("cadRequestFields").innerHTML = "";
        document.getElementById("cadRequestModal").classList.add("is-hidden");
    },
    renderRequestFields(definition) {
        const container = document.getElementById("cadRequestFields");
        if (!container || !definition) {
            return;
        }

        const coords = this.getCurrentGroupCoordinates();
        container.innerHTML = definition.fields
            .map((field) => {
                const defaultValue = field.defaultFromGroupPosition
                    ? coords
                    : "";

                if (field.type === "select") {
                    return `
                        <label class="cad-field">
                            <span>${field.label}</span>
                            <select id="cadRequestField_${field.id}" class="cad-select">
                                ${field.options
                                    .map(
                                        (option) =>
                                            `<option value="${option}">${option.replaceAll("_", " ")}</option>`,
                                    )
                                    .join("")}
                            </select>
                        </label>
                    `;
                }

                if (field.type === "textarea") {
                    return `
                        <label class="cad-field">
                            <span>${field.label}</span>
                            <textarea id="cadRequestField_${field.id}" class="cad-textarea" rows="3">${defaultValue}</textarea>
                        </label>
                    `;
                }

                return `
                    <label class="cad-field">
                        <span>${field.label}</span>
                        <input id="cadRequestField_${field.id}" class="cad-input" type="text" value="${defaultValue}" />
                    </label>
                `;
            })
            .join("");
    },
    submitSupportRequest() {
        const definition = this.getRequestDefinition(this.requestModalType);
        if (!definition) {
            return;
        }

        const fields = {};
        definition.fields.forEach((field) => {
            const input = document.getElementById(
                `cadRequestField_${field.id}`,
            );
            fields[field.id] = input ? String(input.value || "").trim() : "";
        });

        const priority = document.getElementById(
            "cadRequestPrioritySelect",
        ).value;
        this.setStatus("Submitting support request...", "info");
        window.mapUI.sendEvent("cad::supportRequest::submit", {
            type: definition.id,
            fields: fields,
            priority: priority,
        });
        this.closeRequestModal();
    },
    closeSupportRequest(requestID) {
        if (!requestID) {
            return;
        }

        this.setStatus(
            this.isDispatchMode()
                ? "Closing support request..."
                : "Cancelling support request...",
            "info",
        );
        window.mapUI.sendEvent("cad::supportRequest::close", {
            requestID: requestID,
        });
    },
    renderRequests() {
        const listEl = document.getElementById("requestList");
        if (!listEl) {
            return;
        }

        if (this.isDispatchMapMode()) {
            const dispatchRequests = this.requests
                .slice()
                .sort((left, right) => {
                    const leftTitle = left.title || left.requestId || "";
                    const rightTitle = right.title || right.requestId || "";
                    return leftTitle.localeCompare(rightTitle);
                });

            if (!dispatchRequests.length) {
                listEl.innerHTML =
                    '<div class="placeholder-message"><p>No support requests are currently active.</p></div>';
                return;
            }

            listEl.innerHTML = dispatchRequests
                .map((request) => {
                    const requestID = request.requestId || "";
                    const position = Array.isArray(request.position)
                        ? request.position
                        : [0, 0, 0];
                    const isSelected =
                        requestID === this.selectedDispatchRequestId;
                    const isWarning = [
                        "medevac_9line",
                        "fire_support",
                        "air_support",
                    ].includes(request.type || "");

                    return `
                        <button
                            type="button"
                            class="task-card dispatch-map-card ${isSelected ? "is-selected" : ""} ${isWarning ? "is-warning" : ""}"
                            data-request-id="${requestID}"
                            onclick="window.cadTasks.focusRequest('${requestID}')"
                        >
                            <div class="task-card-header">
                                <strong>${request.title || requestID || "Support Request"}</strong>
                                <span class="task-type">${this.getRequestTypeLabel(request.type || "request")}</span>
                            </div>
                            <p class="task-description">${request.summary || ""}</p>
                            <div class="task-meta">
                                <span>Group: ${request.groupCallsign || request.groupId || "Unknown"}</span>
                                <span>${(request.priority || "priority").replaceAll("_", " ")}</span>
                            </div>
                            <div class="task-meta">
                                <span>${window.mapUI.formatPosition(position)}</span>
                                <span>${requestID || "request"}</span>
                            </div>
                        </button>
                    `;
                })
                .join("");
            return;
        }

        const requestButtons = this.canSubmitSupportRequest()
            ? `
                <div class="cad-request-actions">
                    ${this.requestTypes
                        .map(
                            (requestType) => `
                                <button
                                    type="button"
                                    class="task-secondary-btn cad-request-btn"
                                    onclick="window.cadTasks.openRequestModal('${requestType.id}')"
                                >
                                    ${requestType.label}
                                </button>
                            `,
                        )
                        .join("")}
                </div>
            `
            : "";

        if (!this.requests.length) {
            listEl.innerHTML = `
                ${requestButtons}
                <div class="placeholder-message"><p>No support requests are currently active.</p></div>
            `;
            return;
        }

        listEl.innerHTML = `
            ${requestButtons}
            ${this.requests
                .map((request) => {
                    const isOwnGroupLeader =
                        this.isLeader() &&
                        (request.groupId || "") === this.getPlayerGroupId();
                    const canClose = this.canDispatch() || isOwnGroupLeader;
                    const requestActionLabel = this.isDispatchMode()
                        ? "Close"
                        : "Cancel";
                    const requestID = request.requestId || "";
                    const isSelected =
                        requestID === this.selectedDispatchRequestId;
                    return `
                        <div
                            class="task-card cad-request-card dispatch-map-card ${isSelected ? "is-selected" : ""}"
                            data-request-id="${requestID}"
                            role="button"
                            tabindex="0"
                            onclick="window.cadTasks.focusRequest('${requestID}')"
                            onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); window.cadTasks.focusRequest('${requestID}'); }"
                        >
                            <div class="task-card-header">
                                <strong>${request.title || this.getRequestTypeLabel(request.type || "")}</strong>
                                <span class="task-type">${(request.priority || "priority").replaceAll("_", " ")}</span>
                            </div>
                            <p class="task-description">${request.summary || ""}</p>
                            <div class="task-meta">
                                <span>Group: ${request.groupCallsign || request.groupId || "Unknown"}</span>
                                <span>${this.getRequestTypeLabel(request.type || "")}</span>
                            </div>
                            ${
                                canClose
                                    ? `<div class="task-action-row">
                                        <button type="button" class="task-secondary-btn" onclick="event.stopPropagation(); window.cadTasks.closeSupportRequest('${requestID}')">${requestActionLabel}</button>
                                    </div>`
                                    : ""
                            }
                        </div>
                    `;
                })
                .join("")}
        `;
    },
    updateDangerAlert() {
        const alertEl = document.getElementById("cadDangerAlert");
        if (!alertEl) {
            return;
        }

        if (!this.isDispatchMapMode()) {
            alertEl.textContent = "";
            alertEl.classList.add("is-hidden");
            return;
        }

        const dangerGroups = this.getDangerGroups();
        if (!dangerGroups.length) {
            alertEl.textContent = "";
            alertEl.classList.add("is-hidden");
            return;
        }

        const callsigns = dangerGroups.map(
            (group) => group.callsign || group.groupId || "Unknown Group",
        );
        alertEl.textContent = `Danger alert active: ${callsigns.join(", ")}`;
        alertEl.classList.remove("is-hidden");
    },
    updateRequestAlert() {
        const alertEl = document.getElementById("cadRequestAlert");
        if (!alertEl) {
            return;
        }

        if (!this.isDispatchMapMode()) {
            alertEl.textContent = "";
            alertEl.classList.add("is-hidden");
            return;
        }

        const alertMessage = this.buildSupportAlertMessage();
        if (!alertMessage) {
            alertEl.textContent = "";
            alertEl.classList.add("is-hidden");
            return;
        }

        alertEl.textContent = alertMessage;
        alertEl.classList.remove("is-hidden");
    },
    clearFocusStatusSoon(message) {
        if (this.focusStatusTimer) {
            window.clearTimeout(this.focusStatusTimer);
        }

        this.focusStatusTimer = window.setTimeout(() => {
            const statusEl = document.getElementById("cadStatusMessage");
            if (!statusEl) {
                return;
            }

            if (
                statusEl.dataset.type === "info" &&
                statusEl.textContent === message
            ) {
                this.setStatus("", "");
            }
        }, 1800);
    },
    handleServerResponse(success, message) {
        this.setStatus(
            message ||
                (success ? "CAD update succeeded." : "CAD update failed."),
            success ? "success" : "error",
        );
    },
    acknowledgeTask(taskID) {
        this.setStatus("Acknowledging contract...", "info");
        window.mapUI.sendEvent("cad::tasks::acknowledge", { taskID: taskID });
    },
    declineTask(taskID) {
        this.setStatus("Declining contract...", "info");
        window.mapUI.sendEvent("cad::tasks::decline", { taskID: taskID });
    },
    updateGroupStatus(groupID, status) {
        this.setStatus("Updating group status...", "info");
        window.mapUI.sendEvent("cad::groups::status", {
            groupID: groupID,
            status: status,
        });
    },
    updateGroupRole(groupID, role) {
        this.setStatus("Updating group role...", "info");
        window.mapUI.sendEvent("cad::groups::role", {
            groupID: groupID,
            role: role,
        });
    },
    focusGroup(groupID) {
        const group = this.groups.find((entry) => entry.groupId === groupID);
        if (!group) {
            this.setStatus("Selected group is no longer available.", "error");
            return;
        }

        this.selectedDispatchGroupId = groupID;
        this.selectedDispatchTaskId = "";
        this.selectedDispatchRequestId = "";
        this.selectedRosterMemberUid = "";
        const statusMessage = `Centering map on ${group.callsign || group.groupId || "group"}...`;
        this.setStatus(statusMessage, "info");
        this.clearFocusStatusSoon(statusMessage);
        window.mapUI.sendEvent("cad::groups::focus", {
            groupID: groupID,
        });
        this.render();
    },
    focusMember(uid) {
        let selectedMember = null;

        this.groups.some((group) =>
            this.normalizeCollection(group.members).some((member) => {
                if ((member.uid || "") !== uid) {
                    return false;
                }

                selectedMember = member;
                return true;
            }),
        );

        if (!selectedMember) {
            this.setStatus(
                "Selected group member is no longer available.",
                "error",
            );
            return;
        }

        const position = Array.isArray(selectedMember.position)
            ? selectedMember.position
            : [];
        if (position.length < 2) {
            this.setStatus(
                "Selected group member has no map position.",
                "error",
            );
            return;
        }

        this.selectedRosterMemberUid = uid;
        this.selectedDispatchGroupId = "";
        this.selectedDispatchTaskId = "";
        this.selectedDispatchRequestId = "";
        const statusMessage = `Centering map on ${selectedMember.name || "group member"}...`;
        this.setStatus(statusMessage, "info");
        this.clearFocusStatusSoon(statusMessage);
        window.mapUI.sendEvent("cad::members::focus", {
            uid: uid,
        });
        this.render();
    },
    focusTask(taskID) {
        const task = this.contracts.find((entry) => {
            const entryTaskID = entry.taskId || entry.taskID || "";
            return entryTaskID === taskID;
        });
        if (!task) {
            this.setStatus(
                "Selected contract is no longer available.",
                "error",
            );
            return;
        }

        this.selectedDispatchTaskId = taskID;
        this.selectedDispatchGroupId = "";
        this.selectedDispatchRequestId = "";
        this.selectedRosterMemberUid = "";
        const statusMessage = `Centering map on ${task.title || taskID}...`;
        this.setStatus(statusMessage, "info");
        this.clearFocusStatusSoon(statusMessage);
        window.mapUI.sendEvent("cad::tasks::focus", {
            taskID: taskID,
        });
        this.render();
    },
    focusRequest(requestID) {
        const request = this.requests.find(
            (entry) => (entry.requestId || "") === requestID,
        );
        if (!request) {
            this.setStatus("Selected request is no longer available.", "error");
            return;
        }

        const position = Array.isArray(request.position)
            ? request.position
            : [];
        if (position.length < 2) {
            this.setStatus("Selected request has no map position.", "error");
            return;
        }

        this.selectedDispatchRequestId = requestID;
        this.selectedDispatchGroupId = "";
        this.selectedDispatchTaskId = "";
        this.selectedRosterMemberUid = "";
        const statusMessage = `Centering map on ${request.title || requestID}...`;
        this.setStatus(statusMessage, "info");
        this.clearFocusStatusSoon(statusMessage);
        window.mapUI.sendEvent("cad::requests::focus", {
            requestID: requestID,
        });
        this.render();
    },
    getPlayerGroupId() {
        return this.session.groupId || "";
    },
    getCurrentGroup() {
        const currentGroupId = this.getPlayerGroupId();
        return (
            this.groups.find((group) => group.groupId === currentGroupId) ||
            null
        );
    },
    normalizeCollection(value) {
        if (Array.isArray(value)) {
            return value;
        }

        if (value && typeof value === "object") {
            return Object.values(value);
        }

        return [];
    },
    canDispatch() {
        return !!this.session.isDispatcher;
    },
    isDispatchMode() {
        return this.mode === "dispatch";
    },
    isDispatchMapMode() {
        return this.mode === "dispatch" && this.dispatchView === "map";
    },
    isLeader() {
        return !!this.session.isLeader;
    },
    renderContracts() {
        const listEl = document.getElementById("taskList");
        if (!listEl) {
            return;
        }

        if (this.isDispatchMapMode()) {
            if (!this.contracts.length) {
                listEl.innerHTML =
                    '<div class="placeholder-message"><p>No contracts are currently available.</p></div>';
                return;
            }

            const dispatchContracts = this.contracts
                .slice()
                .sort((left, right) => {
                    const leftAssigned =
                        (left.assignmentState || "unassigned") === "unassigned"
                            ? 0
                            : 1;
                    const rightAssigned =
                        (right.assignmentState || "unassigned") === "unassigned"
                            ? 0
                            : 1;

                    if (leftAssigned !== rightAssigned) {
                        return leftAssigned - rightAssigned;
                    }

                    const leftId = left.taskId || left.taskID || "";
                    const rightId = right.taskId || right.taskID || "";
                    return leftId.localeCompare(rightId);
                });

            listEl.innerHTML = dispatchContracts
                .map((task) => {
                    const taskId = task.taskId || task.taskID || "";
                    const position = Array.isArray(task.position)
                        ? task.position
                        : [0, 0, 0];
                    const assignedGroupId = task.assignedGroupId || "";
                    const assignmentState =
                        task.assignmentState || "unassigned";
                    const assignedGroup = this.groups.find(
                        (group) => group.groupId === assignedGroupId,
                    );
                    const isSelected = taskId === this.selectedDispatchTaskId;
                    const stateLabel =
                        assignmentState === "unassigned"
                            ? "Unassigned"
                            : `${assignmentState}: ${assignedGroup ? assignedGroup.callsign : assignedGroupId || "Unknown"}`;

                    return `
                        <button
                            type="button"
                            class="task-card dispatch-map-card ${isSelected ? "is-selected" : ""}"
                            data-task-id="${taskId}"
                            onclick="window.cadTasks.focusTask('${taskId}')"
                        >
                            <div class="task-card-header">
                                <strong>${task.title || taskId}</strong>
                                <span class="task-type">${this.formatTypeLabel(task)}</span>
                            </div>
                            <p class="task-description">${task.description || ""}</p>
                            <div class="task-meta">
                                <span>${stateLabel}</span>
                                <span>${window.mapUI.formatPosition(position)}</span>
                            </div>
                        </button>
                    `;
                })
                .join("");
            return;
        }

        const currentGroupId = this.getPlayerGroupId();
        const visibleContracts = this.contracts.filter(
            (task) => (task.assignedGroupId || "") === currentGroupId,
        );

        if (!visibleContracts.length) {
            listEl.innerHTML =
                '<div class="placeholder-message"><p>No contract is currently assigned to your group.</p></div>';
            return;
        }

        listEl.innerHTML = visibleContracts
            .map((task) => {
                const taskId = task.taskId || task.taskID || "";
                const position = Array.isArray(task.position)
                    ? task.position
                    : [0, 0, 0];
                const assignedGroupId = task.assignedGroupId || "";
                const assignmentState = task.assignmentState || "unassigned";
                const assignedGroup = this.groups.find(
                    (group) => group.groupId === assignedGroupId,
                );
                const isAssignedToLeader =
                    this.isLeader() && assignedGroupId === currentGroupId;
                const isSelected = taskId === this.selectedDispatchTaskId;

                return `
                    <div
                        class="task-card dispatch-map-card ${isSelected ? "is-selected" : ""}"
                        data-task-id="${taskId}"
                        role="button"
                        tabindex="0"
                        onclick="window.cadTasks.focusTask('${taskId}')"
                        onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); window.cadTasks.focusTask('${taskId}'); }"
                    >
                        <div class="task-card-header">
                            <strong>${task.title || taskId}</strong>
                            <span class="task-type">${this.formatTypeLabel(task)}</span>
                        </div>
                        <p class="task-description">${task.description || ""}</p>
                        <div class="task-meta">
                            <span>${assignmentState === "unassigned" ? "Available" : `${assignmentState}: ${assignedGroup ? assignedGroup.callsign : assignedGroupId}`}</span>
                            <span>${window.mapUI.formatPosition(position)}</span>
                        </div>
                        ${
                            isAssignedToLeader && assignmentState === "assigned"
                                ? `<div class="task-action-row">
                                    <button type="button" class="task-accept-btn" onclick="event.stopPropagation(); window.cadTasks.acknowledgeTask('${taskId}')">Acknowledge</button>
                                    <button type="button" class="task-secondary-btn" onclick="event.stopPropagation(); window.cadTasks.declineTask('${taskId}')">Decline</button>
                                </div>`
                                : ""
                        }
                    </div>
                `;
            })
            .join("");
    },
    renderRoster() {
        const listEl = document.getElementById("rosterList");
        if (!listEl) {
            return;
        }

        if (this.isDispatchMapMode()) {
            if (!this.groups.length) {
                listEl.innerHTML =
                    '<div class="placeholder-message"><p>No active groups are currently available.</p></div>';
                return;
            }

            listEl.innerHTML = this.getSortedGroups()
                .map((group) => {
                    const isSelected =
                        (group.groupId || "") === this.selectedDispatchGroupId;
                    const isDanger = (group.status || "") === "danger";
                    return `
                        <button
                            type="button"
                            class="task-card roster-member-card dispatch-map-group-card ${isSelected ? "is-selected" : ""} ${isDanger ? "is-danger" : ""}"
                            data-group-id="${group.groupId || ""}"
                            onclick="window.cadTasks.focusGroup('${group.groupId || ""}')"
                        >
                            <div class="task-card-header">
                                <strong>${group.callsign || group.groupId || "Unknown Group"}</strong>
                                <span class="task-type">${group.role || "group"}</span>
                                ${isDanger ? '<span class="task-alert-badge">Danger</span>' : ""}
                            </div>
                            <div class="task-meta">
                                <span>Leader: ${group.leaderName || "Unknown"}</span>
                                <span>Status: ${group.status || "unknown"}</span>
                            </div>
                            <div class="task-meta">
                                <span>Members: ${this.normalizeCollection(group.members).length}</span>
                                <span>Task: ${group.currentTaskId || "None"}</span>
                            </div>
                        </button>
                    `;
                })
                .join("");
            return;
        }

        const currentGroup = this.getCurrentGroup();
        if (!currentGroup) {
            listEl.innerHTML =
                '<div class="placeholder-message"><p>Your group is not currently available.</p></div>';
            return;
        }

        const roster = this.normalizeCollection(currentGroup.members);
        const isDanger = (currentGroup.status || "") === "danger";

        if (!roster.length) {
            listEl.innerHTML =
                '<div class="placeholder-message"><p>No roster members are currently available.</p></div>';
            return;
        }

        listEl.innerHTML = `
            <div class="roster-summary-card ${isDanger ? "is-danger" : ""}">
                <div class="task-card-header">
                    <strong>${currentGroup.callsign || currentGroup.groupId || "Current Group"}</strong>
                    <span class="task-type">${roster.length} member${roster.length === 1 ? "" : "s"}</span>
                    ${isDanger ? '<span class="task-alert-badge">Danger</span>' : ""}
                </div>
                <div class="task-meta">
                    <span>Leader: ${currentGroup.leaderName || "Unknown"}</span>
                    <span>Status: ${currentGroup.status || "unknown"}</span>
                </div>
                <div class="task-meta">
                    <span>Role: ${currentGroup.role || "unassigned"}</span>
                    <span>Task: ${currentGroup.currentTaskId || "None"}</span>
                </div>
            </div>
            ${roster
                .map((member) => {
                    const lifeState = (
                        member.lifeState || "unknown"
                    ).replaceAll("_", " ");
                    const leaderBadge = member.isLeader
                        ? '<span class="roster-leader-badge">Leader</span>'
                        : "";
                    const memberUid = member.uid || "";
                    const isSelected =
                        memberUid && memberUid === this.selectedRosterMemberUid;

                    return `
                    <div
                        class="task-card roster-member-card dispatch-map-group-card ${isSelected ? "is-selected" : ""}"
                        data-member-id="${memberUid}"
                        role="button"
                        tabindex="0"
                        onclick="window.cadTasks.focusMember('${memberUid}')"
                        onkeydown="if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); window.cadTasks.focusMember('${memberUid}'); }"
                    >
                        <div class="task-card-header">
                            <strong>${member.name || "Unknown Operator"}</strong>
                            <span class="task-type">${lifeState}</span>
                        </div>
                        <div class="task-meta">
                            <span>${member.uid || "No UID"}</span>
                            <span>${leaderBadge}</span>
                        </div>
                    </div>
                `;
                })
                .join("")}
        `;
    },
    renderActivity() {
        const listEl = document.getElementById("activityList");
        if (!listEl) {
            return;
        }

        if (!this.activity.length) {
            listEl.innerHTML =
                '<div class="placeholder-message"><p>No recent activity.</p></div>';
            return;
        }

        listEl.innerHTML = this.activity
            .slice()
            .reverse()
            .slice(0, 8)
            .map(
                (entry) => `
                    <div class="task-card">
                        <div class="task-card-header">
                            <strong>${entry.type || "activity"}</strong>
                            <span class="task-type">${Math.round(entry.timestamp || 0)}s</span>
                        </div>
                        <p class="task-description">${entry.message || ""}</p>
                    </div>
                `,
            )
            .join("");
    },
    render() {
        this.updateDangerAlert();
        this.updateRequestAlert();
        this.syncLayoutState();
        this.renderContracts();
        this.renderRoster();
        this.renderRequests();
        this.renderActivity();
        this.setActiveTab(this.activeTab);
    },
};

window.cadTasks.init();

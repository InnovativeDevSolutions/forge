window.cadDispatcherRender = {
    updateDangerAlert() {
        const alertEl = document.getElementById("dispatcherDangerAlert");
        if (!alertEl) {
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
        const alertEl = document.getElementById("dispatcherRequestAlert");
        if (!alertEl) {
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
    buildGroupEditorButton(groupID) {
        return `
            <button
                type="button"
                class="dispatch-icon-btn"
                onclick="window.cadDispatcher.openGroupModal('${groupID}')"
                aria-label="Edit group"
                title="Edit group"
            >
                &#9881;
            </button>
        `;
    },
    buildCloseOrderButton(taskID) {
        return `
            <button
                type="button"
                class="dispatch-btn dispatch-btn-secondary"
                onclick="window.cadDispatcher.closeDispatchOrder('${taskID}')"
            >
                Close
            </button>
        `;
    },
    buildCloseRequestButton(requestID) {
        return `
            <button
                type="button"
                class="dispatch-btn dispatch-btn-secondary"
                onclick="event.stopPropagation(); window.cadDispatcher.closeSupportRequest('${requestID}')"
            >
                Close
            </button>
        `;
    },
    buildConvertRequestButton(requestID) {
        return `
            <button
                type="button"
                class="dispatch-btn"
                onclick="event.stopPropagation(); window.cadDispatcher.convertRequestToOrder('${requestID}')"
            >
                Convert to Order
            </button>
        `;
    },
    renderMetrics() {
        const assignedContracts = this.contracts.filter(
            (entry) => (entry.assignmentState || "unassigned") !== "unassigned",
        );
        const openContracts = this.contracts.filter(
            (entry) => (entry.assignmentState || "unassigned") === "unassigned",
        );
        const openRequests = this.requests.length;
        const supportAlertRequests = this.getSupportAlertRequests();
        const dangerGroups = this.groups.filter(
            (group) => (group.status || "") === "danger",
        );

        document.getElementById("metricOpenContracts").textContent =
            openContracts.length;
        document.getElementById("metricAssignedContracts").textContent =
            assignedContracts.length;
        document.getElementById("metricActiveGroups").textContent =
            this.groups.length;
        document.getElementById("metricOpenRequests").textContent =
            openRequests;
        document.getElementById("metricDangerGroups").textContent =
            dangerGroups.length;

        const dangerMetricCard = document.getElementById(
            "metricDangerGroupsCard",
        );
        if (dangerMetricCard) {
            dangerMetricCard.classList.toggle(
                "is-danger",
                dangerGroups.length > 0,
            );
        }

        const requestMetricCard = document.getElementById(
            "metricOpenRequestsCard",
        );
        if (requestMetricCard) {
            requestMetricCard.classList.toggle(
                "is-warning",
                supportAlertRequests.length > 0,
            );
        }
    },
    renderOpenContracts() {
        const container = document.getElementById("dispatcherOpenContracts");
        const openContracts = this.contracts.filter(
            (entry) => (entry.assignmentState || "unassigned") === "unassigned",
        );

        if (!openContracts.length) {
            container.innerHTML =
                '<div class="placeholder-message"><p>No open contracts.</p></div>';
            return;
        }

        const groupOptions = this.buildGroupOptions("");

        container.innerHTML = openContracts
            .map((task) => {
                const taskId = task.taskId || task.taskID || "";
                const position = Array.isArray(task.position)
                    ? task.position
                    : [0, 0, 0];
                const targetGroup = this.groups.find(
                    (group) => group.groupId === (task.targetGroupId || ""),
                );

                return `
                    <article class="dispatch-card">
                        <header class="dispatch-card-header">
                            <strong>${task.title || taskId}</strong>
                            <span class="dispatch-badge">${this.formatTypeLabel(task)}</span>
                        </header>
                        <p class="dispatch-description">${task.description || ""}</p>
                        <div class="dispatch-meta">
                            <span>Unassigned</span>
                            <span>${window.mapUI.formatPosition(position)}</span>
                        </div>
                        <div class="dispatch-meta">
                            <span>Target: ${targetGroup ? targetGroup.callsign : task.targetGroupCallsign || "None"}</span>
                            <span>Priority: ${(task.priority || "priority").replaceAll("_", " ")}</span>
                        </div>
                        <div class="dispatch-actions">
                            <select id="dispatcher-assign-group-${taskId}" class="dispatch-select">
                                <option value="">Assign to group</option>
                                ${groupOptions}
                            </select>
                            <button type="button" class="dispatch-btn" onclick="window.cadDispatcher.assignTask('${taskId}')">Assign</button>
                        </div>
                    </article>
                `;
            })
            .join("");
    },
    renderAssignedContracts() {
        const container = document.getElementById(
            "dispatcherAssignedContracts",
        );
        const assignedContracts = this.contracts.filter(
            (entry) => (entry.assignmentState || "unassigned") !== "unassigned",
        );

        if (!assignedContracts.length) {
            container.innerHTML =
                '<div class="placeholder-message"><p>No assigned contracts.</p></div>';
            return;
        }

        container.innerHTML = assignedContracts
            .map((task) => {
                const taskId = task.taskId || task.taskID || "";
                const assignedGroup = this.groups.find(
                    (group) => group.groupId === (task.assignedGroupId || ""),
                );
                const targetGroup = this.groups.find(
                    (group) => group.groupId === (task.targetGroupId || ""),
                );
                const isDispatchOrder = this.isDispatchOrder(task);

                return `
                    <article class="dispatch-card">
                        <header class="dispatch-card-header">
                            <strong>${task.title || taskId}</strong>
                            <span class="dispatch-badge">${task.assignmentState || "assigned"}</span>
                        </header>
                        <p class="dispatch-description">${task.description || ""}</p>
                        <div class="dispatch-meta">
                            <span>Group: ${assignedGroup ? assignedGroup.callsign : task.assignedGroupId || "Unknown"}</span>
                            <span>Type: ${this.formatTypeLabel(task)}</span>
                        </div>
                        <div class="dispatch-meta">
                            <span>Target: ${targetGroup ? targetGroup.callsign : task.targetGroupCallsign || "None"}</span>
                            <span>Priority: ${(task.priority || "priority").replaceAll("_", " ")}</span>
                        </div>
                        ${isDispatchOrder ? `<div class="dispatch-actions dispatch-actions-split">${this.buildCloseOrderButton(taskId)}</div>` : ""}
                    </article>
                `;
            })
            .join("");
    },
    renderGroups() {
        const container = document.getElementById("dispatcherGroups");
        if (!this.groups.length) {
            container.innerHTML =
                '<div class="placeholder-message"><p>No active groups available.</p></div>';
            return;
        }

        container.innerHTML = this.getSortedGroups()
            .map((group) => {
                const isDanger = (group.status || "") === "danger";
                return `
                    <article class="dispatch-card dispatch-card-group ${isDanger ? "is-danger" : ""}">
                        <header class="dispatch-card-header">
                            <div class="dispatch-card-header-main">
                                <strong>${group.callsign || group.groupId}</strong>
                                <span class="dispatch-badge">${group.role || "group"}</span>
                                ${isDanger ? '<span class="dispatch-alert-badge">Danger</span>' : ""}
                            </div>
                            <div class="dispatch-card-header-actions">
                                ${this.buildGroupEditorButton(group.groupId)}
                            </div>
                        </header>
                        <div class="dispatch-meta">
                            <span>Leader: ${group.leaderName || "Unknown"}</span>
                            <span>Status: ${group.status || "unknown"}</span>
                        </div>
                        <div class="dispatch-meta">
                            <span>Org: ${group.orgId || "default"}</span>
                            <span>Task: ${group.currentTaskId || "None"}</span>
                        </div>
                    </article>
                `;
            })
            .join("");
    },
    renderActivity() {
        const container = document.getElementById("dispatcherActivity");
        const requestsHTML = this.requests.length
            ? this.requests
                  .map(
                      (request) => `
                        <article class="dispatch-card dispatch-card-interactive ${["medevac_9line", "fire_support", "air_support"].includes(request.type || "") ? "is-warning" : ""}" onclick="window.cadDispatcher.openRequestModal('${request.requestId || ""}')">
                            <header class="dispatch-card-header">
                                <strong>${request.title || request.requestId || "Support Request"}</strong>
                                <span class="dispatch-badge">${(request.priority || "priority").replaceAll("_", " ")}</span>
                            </header>
                            <p class="dispatch-description">${request.summary || ""}</p>
                            <div class="dispatch-meta">
                                <span>Group: ${request.groupCallsign || request.groupId || "Unknown"}</span>
                                <span>${this.getRequestTypeLabel(request.type || "request")}</span>
                            </div>
                            <div class="dispatch-actions dispatch-actions-split">
                                ${this.buildConvertRequestButton(request.requestId || "")}
                                ${this.buildCloseRequestButton(request.requestId || "")}
                            </div>
                        </article>
                    `,
                  )
                  .join("")
            : '<div class="placeholder-message"><p>No active support requests.</p></div>';

        const activityHTML = this.activity.length
            ? this.activity
                  .slice()
                  .reverse()
                  .slice(0, 8)
                  .map(
                      (entry) => `
                        <article class="dispatch-card">
                            <header class="dispatch-card-header">
                                <strong>${entry.type || "activity"}</strong>
                                <span class="dispatch-badge">${Math.round(entry.timestamp || 0)}s</span>
                            </header>
                            <p class="dispatch-description">${entry.message || ""}</p>
                        </article>
                    `,
                  )
                  .join("")
            : '<div class="placeholder-message"><p>No recent activity.</p></div>';

        container.innerHTML = `
            <div class="dispatch-inline-section">
                <div class="dispatch-inline-header">Support Requests</div>
                ${requestsHTML}
            </div>
            <div class="dispatch-inline-section">
                <div class="dispatch-inline-header">Recent Activity</div>
                ${activityHTML}
            </div>
        `;
    },
    render() {
        this.updateDangerAlert();
        this.updateRequestAlert();
        this.renderMetrics();
        this.renderOpenContracts();
        this.renderAssignedContracts();
        this.renderGroups();
        this.renderActivity();
    },
};

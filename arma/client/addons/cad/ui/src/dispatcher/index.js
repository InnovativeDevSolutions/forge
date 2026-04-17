const dispatcherFormatters = window.cadDispatcherFormatters || {};
const dispatcherModals = window.cadDispatcherModals || {};
const dispatcherRender = window.cadDispatcherRender || {};

window.cadDispatcher = {
    contracts: [],
    requests: [],
    groups: [],
    activity: [],
    session: {},
    editingGroupId: "",
    viewingRequestId: "",
    convertingRequestId: "",
    statuses: [
        "available",
        "en_route",
        "on_task",
        "holding",
        "danger",
        "unavailable",
    ],
    roles: ["infantry", "recon", "armor", "air", "logistics", "support"],
    ...dispatcherFormatters,
    ...dispatcherModals,
    ...dispatcherRender,
    init() {
        document
            .getElementById("dispatcherCreateOrderBtn")
            .addEventListener("click", () => {
                this.openOrderModal();
            });

        document
            .getElementById("dispatcherGroupModalCloseBtn")
            .addEventListener("click", () => {
                this.closeGroupModal();
            });

        document
            .getElementById("dispatcherGroupModalSaveBtn")
            .addEventListener("click", () => {
                this.applyGroupUpdates();
            });

        document
            .querySelector("#dispatcherGroupModal .dispatch-modal-backdrop")
            .addEventListener("click", () => {
                this.closeGroupModal();
            });

        document
            .getElementById("dispatcherOrderModalCloseBtn")
            .addEventListener("click", () => {
                this.closeOrderModal();
            });

        document
            .getElementById("dispatcherOrderModalSaveBtn")
            .addEventListener("click", () => {
                this.createDispatchOrder();
            });

        document
            .querySelector("#dispatcherOrderModal .dispatch-modal-backdrop")
            .addEventListener("click", () => {
                this.closeOrderModal();
            });

        document
            .getElementById("dispatcherRequestModalCloseBtn")
            .addEventListener("click", () => {
                this.closeRequestModal();
            });

        document
            .getElementById("dispatcherRequestModalDoneBtn")
            .addEventListener("click", () => {
                this.closeRequestModal();
            });

        document
            .getElementById("dispatcherRequestConvertBtn")
            .addEventListener("click", () => {
                this.convertViewedRequestToOrder();
            });

        document
            .querySelector("#dispatcherRequestModal .dispatch-modal-backdrop")
            .addEventListener("click", () => {
                this.closeRequestModal();
            });

        window.mapUI.sendEvent("cad::dispatcher::ready", {});
    },
    receiveHydrate(payload) {
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

        const statusEl = document.getElementById("dispatcherStatusMessage");
        if (
            statusEl &&
            (!statusEl.dataset.type || statusEl.dataset.type === "info")
        ) {
            this.setStatus("", "");
        }

        this.syncOpenModal();
        this.syncOrderModal();
        this.syncRequestModal();
        this.render();
    },
    setStatus(message, type) {
        const statusEl = document.getElementById("dispatcherStatusMessage");
        if (!statusEl) {
            return;
        }

        statusEl.textContent = message || "";
        statusEl.dataset.type = type || "";
    },
    createDispatchOrder() {
        const assigneeGroupID = document.getElementById(
            "dispatcherOrderAssigneeSelect",
        ).value;
        const targetGroupID = document.getElementById(
            "dispatcherOrderTargetSelect",
        ).value;
        const priority = document.getElementById(
            "dispatcherOrderPrioritySelect",
        ).value;
        const note = document.getElementById("dispatcherOrderNoteInput").value;
        const sourceRequest = this.convertingRequestId
            ? this.requests.find(
                  (entry) =>
                      (entry.requestId || "") === this.convertingRequestId,
              ) || null
            : null;

        if (!assigneeGroupID || !targetGroupID) {
            this.setStatus(
                "Select both an assignee and a target group.",
                "error",
            );
            return;
        }

        if (assigneeGroupID === targetGroupID) {
            this.setStatus(
                "Assignee and target groups must be different.",
                "error",
            );
            return;
        }

        this.setStatus(
            this.convertingRequestId
                ? "Creating dispatch order from request..."
                : "Creating dispatch order...",
            "info",
        );
        window.mapUI.sendEvent("cad::dispatchOrder::create", {
            assigneeGroupID: assigneeGroupID,
            targetGroupID: targetGroupID,
            note: note.trim(),
            priority: priority,
            request: sourceRequest
                ? {
                      requestId: sourceRequest.requestId || "",
                      type: sourceRequest.type || "",
                      title: sourceRequest.title || "",
                      summary: sourceRequest.summary || "",
                      fields:
                          sourceRequest.fields &&
                          typeof sourceRequest.fields === "object"
                              ? sourceRequest.fields
                              : {},
                  }
                : {},
        });

        this.closeOrderModal();
    },
    assignTask(taskID) {
        const selector = document.getElementById(
            `dispatcher-assign-group-${taskID}`,
        );
        if (!selector || !selector.value) {
            this.setStatus(
                "Select a group before assigning a contract.",
                "error",
            );
            return;
        }

        this.setStatus("Submitting assignment...", "info");
        window.mapUI.sendEvent("cad::tasks::assign", {
            taskID: taskID,
            groupID: selector.value,
            note: "",
        });
    },
    applyGroupUpdates() {
        if (!this.editingGroupId) {
            return;
        }

        const group = this.groups.find(
            (entry) => entry.groupId === this.editingGroupId,
        );
        if (!group) {
            this.closeGroupModal();
            return;
        }

        const roleValue = document.getElementById(
            "dispatcherModalRoleSelect",
        ).value;
        const statusValue = document.getElementById(
            "dispatcherModalStatusSelect",
        ).value;
        const nextRole =
            roleValue && roleValue !== (group.role || "") ? roleValue : "";
        const nextStatus =
            statusValue && statusValue !== (group.status || "")
                ? statusValue
                : "";
        const hasChanges = nextRole || nextStatus;

        if (!hasChanges) {
            this.setStatus("No group changes to save.", "info");
            this.closeGroupModal();
            return;
        }

        this.setStatus("Updating group profile...", "info");
        window.mapUI.sendEvent("cad::groups::profile", {
            groupID: this.editingGroupId,
            role: nextRole,
            status: nextStatus,
        });

        this.closeGroupModal();
    },
    closeDispatchOrder(taskID) {
        if (!taskID) {
            return;
        }

        this.setStatus("Closing dispatch order...", "info");
        window.mapUI.sendEvent("cad::dispatchOrder::close", {
            taskID: taskID,
        });
    },
    closeSupportRequest(requestID) {
        if (!requestID) {
            return;
        }

        this.setStatus("Closing support request...", "info");
        window.mapUI.sendEvent("cad::supportRequest::close", {
            requestID: requestID,
        });
    },
};

window.cadDispatcher.init();

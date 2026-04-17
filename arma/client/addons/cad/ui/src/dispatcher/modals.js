window.cadDispatcherModals = {
    openOrderModal() {
        this.convertingRequestId = "";
        this.populateOrderModal();
        document.getElementById("dispatcherOrderModalTitle").textContent =
            "Create Support Order";
        document
            .getElementById("dispatcherOrderModal")
            .classList.remove("is-hidden");
    },
    closeOrderModal() {
        this.convertingRequestId = "";
        document.getElementById("dispatcherOrderNoteInput").value = "";
        document.getElementById("dispatcherOrderPrioritySelect").value =
            "priority";
        document.getElementById("dispatcherOrderModalTitle").textContent =
            "Create Support Order";
        document
            .getElementById("dispatcherOrderModal")
            .classList.add("is-hidden");
    },
    openRequestModal(requestID) {
        const request = this.requests.find(
            (entry) => entry.requestId === requestID,
        );
        if (!request) {
            return;
        }

        this.viewingRequestId = requestID;
        this.populateRequestModal(request);
        document
            .getElementById("dispatcherRequestModal")
            .classList.remove("is-hidden");
    },
    closeRequestModal() {
        this.viewingRequestId = "";
        document
            .getElementById("dispatcherRequestModal")
            .classList.add("is-hidden");
    },
    syncRequestModal() {
        if (!this.viewingRequestId) {
            return;
        }

        const request = this.requests.find(
            (entry) => entry.requestId === this.viewingRequestId,
        );
        if (!request) {
            this.closeRequestModal();
            return;
        }

        this.populateRequestModal(request);
    },
    populateRequestModal(request) {
        const fields =
            request.fields && typeof request.fields === "object"
                ? Object.entries(request.fields)
                : [];
        const fieldsHTML = fields.length
            ? fields
                  .map(
                      ([fieldID, value]) => `
                        <div class="dispatch-detail-row">
                            <span class="dispatch-detail-label">${this.formatRequestFieldLabel(fieldID)}</span>
                            <span class="dispatch-detail-value">${this.formatRequestFieldValue(value)}</span>
                        </div>
                    `,
                  )
                  .join("")
            : '<div class="placeholder-message"><p>No submitted fields.</p></div>';

        document.getElementById("dispatcherRequestTitle").textContent =
            request.title || request.requestId || "Support Request";
        document.getElementById("dispatcherRequestPriority").textContent = (
            request.priority || "priority"
        ).replaceAll("_", " ");
        document.getElementById("dispatcherRequestGroup").textContent =
            request.groupCallsign || request.groupId || "Unknown";
        document.getElementById("dispatcherRequestType").textContent =
            this.getRequestTypeLabel(request.type || "request");
        document.getElementById("dispatcherRequestSummary").textContent =
            request.summary || "No summary provided.";
        document.getElementById("dispatcherRequestFields").innerHTML =
            fieldsHTML;
    },
    convertRequestToOrder(requestID) {
        const request = this.requests.find(
            (entry) => (entry.requestId || "") === requestID,
        );
        if (!request) {
            this.setStatus("Selected request is no longer available.", "error");
            return;
        }

        const targetGroupID = request.groupId || "";
        if (!targetGroupID) {
            this.setStatus(
                "Selected request has no owning group to target.",
                "error",
            );
            return;
        }

        const targetGroup = this.groups.find(
            (group) => (group.groupId || "") === targetGroupID,
        );
        if (!targetGroup) {
            this.setStatus(
                "Selected request group is no longer available.",
                "error",
            );
            return;
        }

        this.convertingRequestId = requestID;
        this.populateOrderModal({
            selectedAssigneeID:
                this.getSortedGroups().find(
                    (group) => (group.groupId || "") !== targetGroupID,
                )?.groupId || "",
            selectedTargetID: targetGroupID,
            note: this.buildRequestOrderNote(request),
            priority: request.priority || "priority",
        });
        document.getElementById("dispatcherOrderModalTitle").textContent =
            "Create Order From Request";
        document
            .getElementById("dispatcherOrderModal")
            .classList.remove("is-hidden");
        this.setStatus("Preparing dispatch order from request...", "info");
    },
    convertViewedRequestToOrder() {
        if (!this.viewingRequestId) {
            return;
        }

        const requestID = this.viewingRequestId;
        this.closeRequestModal();
        this.convertRequestToOrder(requestID);
    },
    populateOrderModal(options = {}) {
        const sortedGroups = this.getSortedGroups();
        const assigneeSelect = document.getElementById(
            "dispatcherOrderAssigneeSelect",
        );
        const targetSelect = document.getElementById(
            "dispatcherOrderTargetSelect",
        );
        const noteInput = document.getElementById("dispatcherOrderNoteInput");
        const prioritySelect = document.getElementById(
            "dispatcherOrderPrioritySelect",
        );
        if (!assigneeSelect || !targetSelect) {
            return;
        }

        const selectedAssigneeID = options.selectedAssigneeID || "";
        const selectedTargetID = options.selectedTargetID || "";
        const fallbackAssignee =
            selectedAssigneeID ||
            sortedGroups.find(
                (group) => (group.groupId || "") !== selectedTargetID,
            )?.groupId ||
            sortedGroups[0]?.groupId ||
            "";
        const fallbackTarget =
            selectedTargetID ||
            sortedGroups.find(
                (group) => (group.groupId || "") !== fallbackAssignee,
            )?.groupId ||
            sortedGroups[0]?.groupId ||
            "";

        assigneeSelect.innerHTML = this.buildGroupOptions(fallbackAssignee);
        targetSelect.innerHTML = this.buildGroupOptions(fallbackTarget);
        if (noteInput) {
            noteInput.value = options.note || "";
        }
        if (prioritySelect) {
            prioritySelect.value = options.priority || "priority";
        }
    },
    syncOrderModal() {
        const modalEl = document.getElementById("dispatcherOrderModal");
        if (!modalEl || modalEl.classList.contains("is-hidden")) {
            return;
        }

        this.populateOrderModal({
            selectedAssigneeID:
                document.getElementById("dispatcherOrderAssigneeSelect")
                    ?.value || "",
            selectedTargetID:
                document.getElementById("dispatcherOrderTargetSelect")?.value ||
                "",
            note:
                document.getElementById("dispatcherOrderNoteInput")?.value ||
                "",
            priority:
                document.getElementById("dispatcherOrderPrioritySelect")
                    ?.value || "priority",
        });
    },
    openGroupModal(groupID) {
        const group = this.groups.find((entry) => entry.groupId === groupID);
        if (!group) {
            return;
        }

        this.editingGroupId = groupID;
        document.getElementById("dispatcherModalGroupCallsign").textContent =
            group.callsign || group.groupId || "Unknown";
        document.getElementById("dispatcherModalGroupLeader").textContent =
            group.leaderName || "Unknown";
        document.getElementById("dispatcherModalGroupTask").textContent =
            group.currentTaskId || "None";
        document.getElementById("dispatcherModalGroupOrg").textContent =
            group.orgId || "default";
        document.getElementById("dispatcherModalRoleSelect").innerHTML =
            this.roles
                .map(
                    (role) =>
                        `<option value="${role}" ${role === group.role ? "selected" : ""}>${role.replaceAll("_", " ")}</option>`,
                )
                .join("");
        document.getElementById("dispatcherModalStatusSelect").innerHTML =
            this.statuses
                .map(
                    (status) =>
                        `<option value="${status}" ${status === group.status ? "selected" : ""}>${status.replaceAll("_", " ")}</option>`,
                )
                .join("");

        document
            .getElementById("dispatcherGroupModal")
            .classList.remove("is-hidden");
    },
    closeGroupModal() {
        this.editingGroupId = "";
        document
            .getElementById("dispatcherGroupModal")
            .classList.add("is-hidden");
    },
    syncOpenModal() {
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

        document.getElementById("dispatcherModalGroupCallsign").textContent =
            group.callsign || group.groupId || "Unknown";
        document.getElementById("dispatcherModalGroupLeader").textContent =
            group.leaderName || "Unknown";
        document.getElementById("dispatcherModalGroupTask").textContent =
            group.currentTaskId || "None";
        document.getElementById("dispatcherModalGroupOrg").textContent =
            group.orgId || "default";
    },
};

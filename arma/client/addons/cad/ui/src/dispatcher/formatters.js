window.cadDispatcherFormatters = {
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
    getRequestTypeLabel(typeID) {
        switch (typeID) {
            case "medevac_9line":
                return "9-Line MEDEVAC";
            case "ace_lace":
                return "ACE/LACE";
            case "fire_support":
                return "Fire Support";
            case "air_support":
                return "Air Support";
            case "logreq":
                return "LOGREQ";
            default:
                return (typeID || "request").replaceAll("_", " ");
        }
    },
    buildGroupOptions(selectedGroupID) {
        return this.getSortedGroups()
            .map((group) => {
                const groupID = group.groupId || "";
                return `<option value="${groupID}" ${groupID === selectedGroupID ? "selected" : ""}>${group.callsign || groupID}</option>`;
            })
            .join("");
    },
    buildTaskTypeOptions(selectedTaskType) {
        return this.taskTypes
            .map((taskType) => {
                const value = taskType.value || "";
                const selected = value === selectedTaskType ? "selected" : "";
                return `<option value="${value}" ${selected}>${taskType.label || value}</option>`;
            })
            .join("");
    },
    formatRequestFieldLabel(fieldID) {
        return (fieldID || "field")
            .replaceAll("_", " ")
            .replace(/\b\w/g, (character) => character.toUpperCase());
    },
    formatRequestFieldValue(value) {
        if (Array.isArray(value)) {
            return value.join(", ");
        }

        if (value && typeof value === "object") {
            return JSON.stringify(value);
        }

        const text = String(value ?? "").trim();
        return text || "Not provided";
    },
    buildRequestOrderNote(request) {
        const typeLabel = this.getRequestTypeLabel(request.type || "request");
        const groupLabel =
            request.groupCallsign || request.groupId || "Unknown Group";
        const summary = (request.summary || "").trim();
        const fieldDetails =
            request.fields && typeof request.fields === "object"
                ? Object.entries(request.fields)
                      .map(([fieldID, value]) => {
                          const fieldValue =
                              this.formatRequestFieldValue(value);
                          if (fieldValue === "Not provided") {
                              return "";
                          }

                          return `${this.formatRequestFieldLabel(fieldID)} ${fieldValue}`;
                      })
                      .filter(Boolean)
                : [];
        const details = fieldDetails.length
            ? fieldDetails
            : [summary].filter(Boolean);

        return details.length
            ? `${typeLabel} requested by ${groupLabel}. ${details.join(" | ")}`
            : `${typeLabel} requested by ${groupLabel}.`;
    },
};

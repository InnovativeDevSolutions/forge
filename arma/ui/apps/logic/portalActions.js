(function () {
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    SharedLogic.createPortalActions = function createPortalActions({
        portalData,
        store,
        permissions,
        registryStore,
    }) {
        class OrgPortalActions {
            constructor() {
                this.treasuryNoticeTimer = null;
            }

            formatCurrency(value) {
                return "$" + value.toLocaleString();
            }

            formatVehicleType(type) {
                if (!type) {
                    return "";
                }

                return type.charAt(0).toUpperCase() + type.slice(1);
            }

            formatAssetType(type) {
                if (!type) {
                    return "";
                }

                return type.charAt(0).toUpperCase() + type.slice(1);
            }

            formatDisplayName(value) {
                if (!value) {
                    return "";
                }

                return String(value)
                    .trim()
                    .split(/\s+/)
                    .map((part) => {
                        if (!part) {
                            return "";
                        }

                        return (
                            part.charAt(0).toUpperCase() +
                            part.slice(1).toLowerCase()
                        );
                    })
                    .join(" ");
            }

            getAssetReadiness() {
                if (portalData.fleet.length === 0) {
                    return null;
                }

                const total = portalData.fleet.reduce(
                    (sum, unit) => sum + (100 - parseInt(unit.damage, 10)),
                    0,
                );
                return Math.round(total / portalData.fleet.length);
            }

            showTreasuryNotice(type, text) {
                store.setTreasuryNotice({ type, text });

                if (this.treasuryNoticeTimer) {
                    clearTimeout(this.treasuryNoticeTimer);
                }

                this.treasuryNoticeTimer = setTimeout(() => {
                    store.setTreasuryNotice({ type: "", text: "" });
                    this.treasuryNoticeTimer = null;
                }, 3500);
            }

            parseAmount(value) {
                const amount = Number(value);
                return Number.isFinite(amount) ? Math.round(amount) : 0;
            }

            getInputValue(id) {
                const el = document.getElementById(id);
                return el ? el.value : "";
            }

            isOwnerMember(memberName) {
                return (
                    String(memberName || "")
                        .trim()
                        .toLowerCase() ===
                    String(portalData.org.owner || "")
                        .trim()
                        .toLowerCase()
                );
            }

            closePortal() {
                if (
                    typeof A3API !== "undefined" &&
                    typeof A3API.SendAlert === "function"
                ) {
                    A3API.SendAlert(
                        JSON.stringify({
                            event: "org::close",
                            data: {},
                        }),
                    );
                    return;
                }

                if (registryStore) {
                    registryStore.setView("home");
                }
            }

            openModal(type) {
                if (
                    (type === "payroll" ||
                        type === "transfer" ||
                        type === "credit") &&
                    !permissions.canManageTreasury()
                ) {
                    this.showTreasuryNotice(
                        "error",
                        "Only the organization leader or CEO can manage treasury actions.",
                    );
                    return;
                }

                if (type === "disband" && !permissions.canDisbandOrg()) {
                    return;
                }

                store.setModal({ type });
            }

            closeModal() {
                store.setModal(null);
            }

            removeMember(memberName) {
                if (!permissions.canManageMembers()) {
                    return false;
                }

                if (this.isOwnerMember(memberName)) {
                    return false;
                }

                store.setMembers((currentMembers) =>
                    currentMembers.filter(
                        (member) => member.name !== memberName,
                    ),
                );
                store.setCreditLines((currentLines) =>
                    currentLines.filter((line) => line.member !== memberName),
                );
                return true;
            }

            disbandOrganization() {
                if (!permissions.canDisbandOrg()) {
                    return false;
                }

                store.setOrgDisbanded(true);
                this.closeModal();
                return true;
            }

            runPayroll(amountPerMember) {
                if (!permissions.canManageTreasury()) {
                    this.showTreasuryNotice(
                        "error",
                        "Only the organization leader or CEO can manage treasury actions.",
                    );
                    return false;
                }

                const members = store.getMembers();
                const funds = store.getFunds();

                if (members.length === 0) {
                    this.showTreasuryNotice(
                        "error",
                        "No members available for payroll.",
                    );
                    return false;
                }

                if (amountPerMember <= 0) {
                    this.showTreasuryNotice(
                        "error",
                        "Enter a valid payroll amount.",
                    );
                    return false;
                }

                const total = amountPerMember * members.length;
                if (total > funds) {
                    this.showTreasuryNotice(
                        "error",
                        "Insufficient org funds for payroll.",
                    );
                    return false;
                }

                store.setFunds(funds - total);
                this.showTreasuryNotice(
                    "success",
                    `Payroll sent to ${members.length} members for ${this.formatCurrency(total)}.`,
                );
                return true;
            }

            sendFundsToMember(memberName, amount) {
                if (!permissions.canManageTreasury()) {
                    this.showTreasuryNotice(
                        "error",
                        "Only the organization leader or CEO can manage treasury actions.",
                    );
                    return false;
                }

                const funds = store.getFunds();

                if (!memberName) {
                    this.showTreasuryNotice(
                        "error",
                        "Select a member to receive funds.",
                    );
                    return false;
                }

                if (amount <= 0) {
                    this.showTreasuryNotice(
                        "error",
                        "Enter a valid transfer amount.",
                    );
                    return false;
                }

                if (amount > funds) {
                    this.showTreasuryNotice(
                        "error",
                        "Insufficient org funds for this transfer.",
                    );
                    return false;
                }

                store.setFunds(funds - amount);
                this.showTreasuryNotice(
                    "success",
                    `${this.formatCurrency(amount)} sent to ${memberName}.`,
                );
                return true;
            }

            grantCreditLine(memberName, amount) {
                if (!permissions.canManageTreasury()) {
                    this.showTreasuryNotice(
                        "error",
                        "Only the organization leader or CEO can manage treasury actions.",
                    );
                    return false;
                }

                if (!memberName) {
                    this.showTreasuryNotice(
                        "error",
                        "Select a member for the credit line.",
                    );
                    return false;
                }

                if (amount <= 0) {
                    this.showTreasuryNotice(
                        "error",
                        "Enter a valid credit line amount.",
                    );
                    return false;
                }

                store.setCreditLines((currentLines) => {
                    const existingIndex = currentLines.findIndex(
                        (line) => line.member === memberName,
                    );
                    if (existingIndex === -1) {
                        return [
                            ...currentLines,
                            { member: memberName, amount },
                        ];
                    }

                    const updatedLines = [...currentLines];
                    updatedLines[existingIndex] = {
                        member: memberName,
                        amount,
                    };
                    return updatedLines;
                });

                this.showTreasuryNotice(
                    "success",
                    `Credit line of ${this.formatCurrency(amount)} assigned to ${memberName}.`,
                );
                return true;
            }
        }

        return new OrgPortalActions();
    };
})();

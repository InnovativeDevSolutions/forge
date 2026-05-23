(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { portalData } = OrgPortal.data;
    const store = OrgPortal.store;
    const getters = OrgPortal.getters;
    const registryStore = window.RegistryApp.store;

    class OrgPortalActions {
        constructor() {
            this.treasuryNoticeTimer = null;
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

        closePortal() {
            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (bridge && typeof bridge.close === "function") {
                bridge.close({});
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
                !getters.canManageTreasury()
            ) {
                this.showTreasuryNotice(
                    "error",
                    "Only the organization leader or CEO can manage treasury actions.",
                );
                return;
            }

            if (type === "invite" && !getters.canManageMembers()) {
                this.showTreasuryNotice(
                    "error",
                    "Only the organization leader or CEO can invite players.",
                );
                return;
            }

            if (type === "disband" && !getters.canDisbandOrg()) {
                return;
            }

            if (type === "leave" && !getters.canLeaveOrg()) {
                return;
            }

            store.setModal({ type });
        }

        closeModal() {
            store.setModal(null);
        }

        toggleInviteMenu() {
            store.setInviteMenuOpen(!store.getInviteMenuOpen());
        }

        closeInviteMenu() {
            store.setInviteMenuOpen(false);
        }

        removeMember(member) {
            if (!getters.canManageMembers()) {
                return false;
            }

            if (getters.isProtectedMember(member)) {
                return false;
            }

            const memberUid = getters.getMemberUid(member);
            const memberName = getters.getMemberName(member);

            store.setMembers((currentMembers) =>
                currentMembers.filter((entry) =>
                    memberUid
                        ? entry.uid !== memberUid
                        : entry.name !== memberName,
                ),
            );
            store.setCreditLines((currentLines) =>
                currentLines.filter((line) =>
                    memberUid
                        ? line.uid !== memberUid
                        : line.member !== memberName,
                ),
            );
            return true;
        }

        disbandOrganization() {
            if (!getters.canDisbandOrg()) {
                return false;
            }

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestDisbandOrg !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Disband bridge is unavailable.",
                );
                return false;
            }

            this.closeModal();
            bridge.requestDisbandOrg();
            return true;
        }

        leaveOrganization() {
            if (!getters.canLeaveOrg()) {
                return false;
            }

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestLeaveOrg !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Leave bridge is unavailable.",
                );
                return false;
            }

            this.closeModal();
            bridge.requestLeaveOrg();
            return true;
        }

        runPayroll(amountPerMember) {
            if (!getters.canManageTreasury()) {
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

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestPayroll !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Payroll bridge is unavailable.",
                );
                return false;
            }

            return bridge.requestPayroll({
                amount: amountPerMember,
            });
        }

        sendFundsToMember(memberUid, amount) {
            if (!getters.canManageTreasury()) {
                this.showTreasuryNotice(
                    "error",
                    "Only the organization leader or CEO can manage treasury actions.",
                );
                return false;
            }

            const funds = store.getFunds();

            if (!memberUid) {
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

            const member = store
                .getMembers()
                .find((entry) => getters.getMemberUid(entry) === memberUid);
            const memberName = member ? getters.getMemberName(member) : "";
            if (!memberName) {
                this.showTreasuryNotice(
                    "error",
                    "Selected member was not found in the organization roster.",
                );
                return false;
            }

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (
                !bridge ||
                typeof bridge.requestTreasuryTransfer !== "function"
            ) {
                this.showTreasuryNotice(
                    "error",
                    "Treasury transfer bridge is unavailable.",
                );
                return false;
            }

            return bridge.requestTreasuryTransfer({
                memberUid,
                memberName,
                amount,
            });
        }

        grantCreditLine(memberUid, amount) {
            if (!getters.canManageTreasury()) {
                this.showTreasuryNotice(
                    "error",
                    "Only the organization leader or CEO can manage treasury actions.",
                );
                return false;
            }

            if (!memberUid) {
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

            const member = store
                .getMembers()
                .find((entry) => getters.getMemberUid(entry) === memberUid);
            const memberName = member ? getters.getMemberName(member) : "";

            if (!memberName) {
                this.showTreasuryNotice(
                    "error",
                    "Selected member was not found in the organization roster.",
                );
                return false;
            }

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestCreditLine !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Credit line bridge is unavailable.",
                );
                return false;
            }

            return bridge.requestCreditLine({
                memberUid,
                memberName,
                amount,
            });
        }

        sendInvite(targetUid) {
            if (!getters.canManageMembers()) {
                this.showTreasuryNotice(
                    "error",
                    "Only the organization leader or CEO can invite players.",
                );
                return false;
            }

            const target = store
                .getInviteablePlayers()
                .find((entry) => String(entry.uid || "") === String(targetUid));

            if (!target) {
                this.showTreasuryNotice(
                    "error",
                    "Select an online player to invite.",
                );
                return false;
            }

            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestInvitePlayer !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Organization invite bridge is unavailable.",
                );
                return false;
            }

            return bridge.requestInvitePlayer({
                targetUid: String(target.uid || ""),
                targetName: String(target.name || ""),
            });
        }

        acceptInvite(orgId) {
            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestAcceptInvite !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Organization invite bridge is unavailable.",
                );
                return false;
            }

            this.closeInviteMenu();
            return bridge.requestAcceptInvite({ orgId });
        }

        declineInvite(orgId) {
            const bridge = window.RegistryApp
                ? window.RegistryApp.bridge
                : null;

            if (!bridge || typeof bridge.requestDeclineInvite !== "function") {
                this.showTreasuryNotice(
                    "error",
                    "Organization invite bridge is unavailable.",
                );
                return false;
            }

            this.closeInviteMenu();
            return bridge.requestDeclineInvite({ orgId });
        }
    }

    OrgPortal.actions = new OrgPortalActions();
})();

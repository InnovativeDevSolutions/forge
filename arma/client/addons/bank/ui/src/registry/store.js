(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { createSignal } = BankApp.runtime;

    class BankStore {
        constructor() {
            [this.getMode, this.setMode] = createSignal("bank");
            [this.getNotice, this.setNotice] = createSignal({
                text: "",
                type: "",
            });
            [this.getPendingAction, this.setPendingAction] = createSignal("");
            [this.getAtmView, this.setAtmView] = createSignal("pin");
            [this.getEnteredPin, this.setEnteredPin] = createSignal("");
            [this.getCustomAmount, this.setCustomAmount] = createSignal("");
            [this.getAccountVersion, this.setAccountVersion] = createSignal(0);
            [this.getSessionVersion, this.setSessionVersion] = createSignal(0);
        }

        finishAction() {
            this.setPendingAction("");
        }

        hydrateFromPayload(payload) {
            const mode = String(payload?.session?.mode || "bank")
                .trim()
                .toLowerCase();
            const atmAuthorized = Boolean(payload?.session?.atmAuthorized);
            const currentMode = this.getMode();
            const currentAtmView = this.getAtmView();
            const currentPendingAction = this.getPendingAction();

            this.setMode(mode === "atm" ? "atm" : "bank");
            this.setPendingAction("");
            this.setEnteredPin("");
            this.setCustomAmount("");
            this.setAccountVersion(this.getAccountVersion() + 1);
            this.setSessionVersion(this.getSessionVersion() + 1);

            if (mode === "atm") {
                if (!atmAuthorized) {
                    this.setAtmView("pin");
                    return;
                }

                if (
                    currentPendingAction === "deposit" ||
                    currentPendingAction === "withdraw" ||
                    currentAtmView === "pin" ||
                    currentMode !== "atm"
                ) {
                    this.setAtmView("menu");
                    return;
                }

                this.setAtmView(currentAtmView);
                return;
            }

            this.setAtmView("dashboard");
        }

        syncAccountPatch() {
            this.setPendingAction("");
            this.setAccountVersion(this.getAccountVersion() + 1);
        }

        resetAtm() {
            this.setEnteredPin("");
            this.setCustomAmount("");
            this.setAtmView("pin");
        }

        startAction(action) {
            this.setPendingAction(
                String(action || "")
                    .trim()
                    .toLowerCase(),
            );
        }
    }

    BankApp.store = new BankStore();
})();

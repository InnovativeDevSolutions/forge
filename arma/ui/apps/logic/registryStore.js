(function () {
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    SharedLogic.createRegistryStore = function createRegistryStore({
        createSignal,
        onHydratePortal,
    }) {
        class RegistryStore {
            constructor() {
                [this.getView, this.setView] = createSignal("home");
                [this.getIsAuthenticating, this.setIsAuthenticating] =
                    createSignal(false);
                [this.getLoginError, this.setLoginError] = createSignal("");
                [this.getIsCreating, this.setIsCreating] = createSignal(false);
                [this.getCreateError, this.setCreateError] = createSignal("");
            }

            startLogin() {
                this.setLoginError("");
                this.setIsAuthenticating(true);
            }

            startCreate() {
                this.setCreateError("");
                this.setIsCreating(true);
            }

            failLogin(message) {
                this.setIsAuthenticating(false);
                this.setLoginError(message || "Authentication failed.");
            }

            failCreate(message) {
                this.setIsCreating(false);
                this.setCreateError(
                    message || "Organization registration failed.",
                );
            }

            hydratePortal(payload) {
                return Boolean(onHydratePortal && onHydratePortal(payload));
            }

            completeLogin(payload) {
                if (!this.hydratePortal(payload)) {
                    this.failLogin("Login response was missing portal data.");
                    return;
                }

                this.setLoginError("");
                this.setIsAuthenticating(false);
            }

            completeCreate(payload) {
                if (!this.hydratePortal(payload)) {
                    this.failCreate(
                        "Organization registration response was missing portal data.",
                    );
                    return;
                }

                this.setCreateError("");
                this.setIsCreating(false);
            }
        }

        return new RegistryStore();
    };
})();

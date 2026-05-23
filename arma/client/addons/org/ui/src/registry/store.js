(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { createSignal } = RegistryApp.runtime;

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
            this.setCreateError(message || "Organization registration failed.");
        }

        hydratePortal(payload) {
            const portalApi =
                window.OrgPortal && window.OrgPortal.data
                    ? window.OrgPortal.data
                    : null;
            const portalStore =
                window.OrgPortal && window.OrgPortal.store
                    ? window.OrgPortal.store
                    : null;
            const portalData =
                payload && payload.portalData ? payload.portalData : null;
            const sessionData =
                payload && payload.session ? payload.session : null;

            if (
                !portalApi ||
                typeof portalApi.applyLoginPayload !== "function" ||
                !portalStore ||
                typeof portalStore.hydrateFromPayload !== "function" ||
                !portalData ||
                !sessionData
            ) {
                return false;
            }

            portalApi.applyLoginPayload(payload);
            portalStore.hydrateFromPayload(payload);
            return true;
        }

        completeLogin(payload) {
            if (!this.hydratePortal(payload)) {
                this.failLogin("Login response was missing portal data.");
                return;
            }

            this.setLoginError("");
            this.setIsAuthenticating(false);
            this.setView("portal");
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
            this.setView("portal");
        }
    }

    RegistryApp.store = new RegistryStore();
})();

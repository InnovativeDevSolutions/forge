(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { createSignal } = RegistryApp.runtime;
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    RegistryApp.store = SharedLogic.createRegistryStore({
        createSignal,
        onHydratePortal(payload) {
            const OrgPortal = window.OrgPortal;
            const portalData = payload?.portalData;
            const session = payload?.session;

            if (!OrgPortal || !portalData || !session) {
                return false;
            }

            OrgPortal.data.applyLoginPayload(payload);
            OrgPortal.store.hydrateFromPayload(payload);
            RegistryApp.store.setView("portal");
            return true;
        },
    });
})();

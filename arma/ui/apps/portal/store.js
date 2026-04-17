(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { createSignal } = window.RegistryApp.runtime;
    const { portalData } = OrgPortal.data;
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    OrgPortal.store = SharedLogic.createPortalStore({
        createSignal,
        portalData,
    });
})();

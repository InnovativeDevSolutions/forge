(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { portalData } = OrgPortal.data;
    const store = OrgPortal.store;
    const permissions = OrgPortal.permissions;
    const registryStore = window.RegistryApp.store;
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    OrgPortal.actions = SharedLogic.createPortalActions({
        portalData,
        store,
        permissions,
        registryStore,
    });
})();

(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { portalData, session } = OrgPortal.data;
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    OrgPortal.permissions = SharedLogic.createPortalPermissions({
        portalData,
        session,
    });
})();

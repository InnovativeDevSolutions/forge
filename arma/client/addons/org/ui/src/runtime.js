(function () {
    const runtime = window.ForgeWebUI;
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});

    RegistryApp.runtime = runtime;
    OrgPortal.runtime = runtime;
    window.AppRuntime = runtime;
})();

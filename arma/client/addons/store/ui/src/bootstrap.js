(function () {
    const ForgeWebUI = window.ForgeWebUI;
    const StorefrontApp = window.StorefrontApp;
    const app = ForgeWebUI.createApp({
        name: "store",
        root: "#app",
        setup({ root }) {
            ForgeWebUI.mount(root, () => StorefrontApp.components.App(), {
                preserveScroll: false,
            });

            if (StorefrontApp.bridge) {
                StorefrontApp.bridge.notifyReady();
            }
        },
    });

    app.start();
})();

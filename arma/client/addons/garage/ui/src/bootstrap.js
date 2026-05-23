(function () {
    const ForgeWebUI = window.ForgeWebUI;
    const GarageApp = window.GarageApp;
    const app = ForgeWebUI.createApp({
        name: "garage",
        root: "#app",
        setup({ root }) {
            ForgeWebUI.mount(root, () => GarageApp.components.App(), {
                preserveScroll: true,
            });

            if (GarageApp.bridge) {
                GarageApp.bridge.notifyReady();
            }
        },
    });

    app.start();
})();

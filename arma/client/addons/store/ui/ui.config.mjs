export default {
    addonName: "store",
    title: "FORGE Supply Exchange",
    logLabel: "Store UI",
    outputDir: "_site",
    jsBundles: [
        {
            name: "Store UI app",
            output: "store-ui.js",
            sources: [
                "src/runtime.js",
                "src/media.js",
                "src/data.js",
                "src/registry/store.js",
                "src/pages/StoreView.js",
                "src/bridge.js",
                "src/registry/events.js",
                "src/components/AppShell.js",
                "src/components/cards.js",
                "src/components/cart.js",
                "src/components/navbar.js",
                "src/bootstrap.js",
            ],
        },
    ],
    cssBundles: [
        {
            name: "Store UI styles",
            output: "store-ui.css",
            sources: ["src/styles.css"],
        },
    ],
    site: {
        styles: ["store-ui.css"],
        commonScripts: ["forge-webui.js"],
        scripts: ["store-ui.js"],
    },
};

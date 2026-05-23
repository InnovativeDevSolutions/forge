export default {
    addonName: "bank",
    title: "FORGE Banking Console",
    logLabel: "Bank UI",
    outputDir: "_site",
    jsBundles: [
        {
            name: "Bank UI app",
            output: "bank-ui.js",
            sources: [
                "src/runtime.js",
                "src/data.js",
                "src/registry/store.js",
                "src/bridge.js",
                "src/registry/events.js",
                "src/components/common.js",
                "src/components/BankSidebar.js",
                "src/components/Footer.js",
                "src/pages/BankView.js",
                "src/pages/ATMView.js",
                "src/components/AppShell.js",
                "src/bootstrap.js",
            ],
        },
    ],
    cssBundles: [
        {
            name: "Bank UI styles",
            output: "bank-ui.css",
            sources: ["src/styles.css"],
        },
    ],
    site: {
        styles: ["bank-ui.css"],
        commonScripts: ["forge-webui.js"],
        scripts: ["bank-ui.js"],
    },
};

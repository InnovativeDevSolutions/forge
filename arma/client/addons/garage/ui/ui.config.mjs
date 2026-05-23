export default {
    addonName: "garage",
    title: "FORGE Vehicle Garage",
    logLabel: "Garage UI",
    outputDir: "_site",
    jsBundles: [
        {
            name: "Garage UI app",
            output: "garage-ui.js",
            sources: [
                "src/runtime.js",
                "src/data.js",
                "src/registry/store.js",
                "src/bridge.js",
                "src/registry/events.js",
                "src/components/AppShell.js",
                "src/bootstrap.js",
            ],
        },
    ],
    cssBundles: [
        {
            name: "Garage UI styles",
            output: "garage-ui.css",
            sources: ["src/styles.css"],
        },
    ],
    site: {
        styles: ["garage-ui.css"],
        commonScripts: ["forge-webui.js"],
        scripts: ["garage-ui.js"],
    },
};

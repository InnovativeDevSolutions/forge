export default {
    addonName: "cad",
    title: "FORGE CAD",
    logLabel: "CAD UI",
    outputDir: "_site",
    generateIndex: false,
    jsBundles: [
        {
            name: "CAD shared bridge/runtime",
            output: "cad-shared.js",
            sources: ["src/shared.js"],
        },
        {
            name: "CAD topbar app",
            output: "cad-topbar.js",
            sources: ["src/topbar.js"],
        },
        {
            name: "CAD sidepanel app",
            output: "cad-sidepanel.js",
            sources: ["src/sidepanel.js"],
        },
        {
            name: "CAD dispatcher app",
            output: "cad-dispatcher.js",
            sources: [
                "src/dispatcher/formatters.js",
                "src/dispatcher/modals.js",
                "src/dispatcher/render.js",
                "src/dispatcher/index.js",
            ],
        },
        {
            name: "CAD bottombar app",
            output: "cad-bottombar.js",
            sources: ["src/bottombar.js"],
        },
    ],
    cssBundles: [
        {
            name: "CAD common styles",
            output: "cad-common.css",
            sources: ["src/styles/common.css"],
        },
        {
            name: "CAD topbar styles",
            output: "cad-topbar.css",
            sources: ["src/styles/topbar.css"],
        },
        {
            name: "CAD sidepanel styles",
            output: "cad-sidepanel.css",
            sources: ["src/styles/sidepanel.css"],
        },
        {
            name: "CAD dispatcher styles",
            output: "cad-dispatcher.css",
            sources: ["src/styles/dispatcher.css"],
        },
        {
            name: "CAD bottombar styles",
            output: "cad-bottombar.css",
            sources: ["src/styles/bottombar.css"],
        },
    ],
    htmlTemplates: [
        {
            name: "CAD topbar page",
            output: "topbar.html",
            source: "src/topbar.html",
        },
        {
            name: "CAD sidepanel page",
            output: "sidepanel.html",
            source: "src/sidepanel.html",
        },
        {
            name: "CAD dispatcher page",
            output: "dispatcher.html",
            source: "src/dispatcher.html",
        },
        {
            name: "CAD bottombar page",
            output: "bottombar.html",
            source: "src/bottombar.html",
        },
    ],
    site: {},
};

(function (global) {
    const ForgeSiteLoader = (global.ForgeSiteLoader =
        global.ForgeSiteLoader || {});
    const commonAddonRoot = "forge\\forge_client\\addons\\common\\ui\\_site\\";
    const defaultBrowserCommonBase = "../../../common/ui/_site/";

    function isArmaAvailable() {
        return (
            typeof A3API !== "undefined" &&
            A3API &&
            typeof A3API.RequestFile === "function"
        );
    }

    function isAbsoluteAddonPath(path) {
        return typeof path === "string" && path.startsWith("forge\\");
    }

    function normalizeAddonRoot(addonName) {
        return `forge\\forge_client\\addons\\${addonName}\\ui\\_site\\`;
    }

    function normalizeBrowserPath(basePath, assetPath) {
        const normalizedBase = String(basePath || "./").replace(/\\/g, "/");
        const normalizedAssetPath = String(assetPath || "").replace(/\\/g, "/");
        return `${normalizedBase}${normalizedAssetPath}`;
    }

    function requestText({ addonRoot, browserBase, assetPath }) {
        if (isArmaAvailable()) {
            const resolvedPath = isAbsoluteAddonPath(assetPath)
                ? assetPath
                : addonRoot + String(assetPath || "").replace(/\//g, "\\");
            return A3API.RequestFile(resolvedPath);
        }

        const browserPath = isAbsoluteAddonPath(assetPath)
            ? assetPath
            : normalizeBrowserPath(browserBase, assetPath);

        return fetch(browserPath).then((response) => {
            if (!response.ok) {
                throw new Error(`Failed to load ${browserPath}`);
            }

            return response.text();
        });
    }

    function appendStyle(cssText) {
        const style = document.createElement("style");
        style.textContent = cssText;
        document.head.appendChild(style);
    }

    function appendScript(jsText) {
        const script = document.createElement("script");
        script.text = jsText;
        document.head.appendChild(script);
    }

    async function boot(config) {
        const addonName = config && config.addonName ? config.addonName : "";

        if (!addonName) {
            throw new Error(
                "ForgeSiteLoader requires a config.addonName value.",
            );
        }

        const addonRoot = normalizeAddonRoot(addonName);
        const browserAddonBase = config.browserAddonBase || "./";
        const browserCommonBase =
            config.browserCommonBase || defaultBrowserCommonBase;
        const styles = Array.isArray(config.styles) ? config.styles : [];
        const commonScripts = Array.isArray(config.commonScripts)
            ? config.commonScripts
            : [];
        const scripts = Array.isArray(config.scripts) ? config.scripts : [];

        const styleChunks = await Promise.all(
            styles.map((assetPath) =>
                requestText({
                    addonRoot,
                    browserBase: browserAddonBase,
                    assetPath,
                }),
            ),
        );
        styleChunks.forEach(appendStyle);

        const commonScriptChunks = await Promise.all(
            commonScripts.map((assetPath) =>
                requestText({
                    addonRoot: commonAddonRoot,
                    browserBase: browserCommonBase,
                    assetPath,
                }),
            ),
        );
        commonScriptChunks.forEach(appendScript);

        const scriptChunks = await Promise.all(
            scripts.map((assetPath) =>
                requestText({
                    addonRoot,
                    browserBase: browserAddonBase,
                    assetPath,
                }),
            ),
        );
        scriptChunks.forEach(appendScript);
    }

    ForgeSiteLoader.boot = boot;

    if (global.ForgeSiteConfig && global.ForgeSiteConfig.autoBoot !== false) {
        boot(global.ForgeSiteConfig).catch((error) => {
            const logLabel =
                global.ForgeSiteConfig.logLabel ||
                global.ForgeSiteConfig.addonName ||
                "Forge UI";
            console.error(`[${logLabel}] Failed to load site assets.`, error);
        });
    }
})(window);

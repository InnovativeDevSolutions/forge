(function (global) {
    const ForgeWebUI = (global.ForgeWebUI = global.ForgeWebUI || {});

    function resolveRoot(root) {
        if (!root) {
            return null;
        }

        if (typeof root === "string") {
            return document.querySelector(root);
        }

        return root instanceof Element ? root : null;
    }

    function createApp(options = {}) {
        const name = options.name || "app";
        const root = options.root || "#app";
        const setup =
            typeof options.setup === "function" ? options.setup : () => {};
        let started = false;

        function start() {
            if (started) {
                return;
            }

            started = true;

            const boot = () => {
                const rootNode = resolveRoot(root);
                if (!rootNode) {
                    console.error(
                        `[ForgeWebUI] Root node not found for ${name}.`,
                    );
                    return;
                }

                setup({
                    name,
                    root: rootNode,
                    runtime: ForgeWebUI,
                });
            };

            if (document.readyState === "loading") {
                document.addEventListener("DOMContentLoaded", boot, {
                    once: true,
                });
                return;
            }

            boot();
        }

        return { start };
    }

    ForgeWebUI.createApp = createApp;
})(window);

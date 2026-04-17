(function (global) {
    const ForgeWebUI = (global.ForgeWebUI = global.ForgeWebUI || {});

    function createHost() {
        const api = global.A3API;

        return {
            isArma: Boolean(api),
            close(event = "ui::close", data = {}) {
                return this.send(event, data);
            },
            exec(statement) {
                if (
                    !api ||
                    typeof api.Exec !== "function" ||
                    typeof statement !== "string"
                ) {
                    return false;
                }

                api.Exec(statement);
                return true;
            },
            requestFile(path) {
                if (api && typeof api.RequestFile === "function") {
                    return api.RequestFile(path);
                }

                return fetch(path).then((response) => {
                    if (!response.ok) {
                        throw new Error(`Failed to load ${path}`);
                    }

                    return response.text();
                });
            },
            requestTexture(path, size = 512) {
                if (api && typeof api.RequestTexture === "function") {
                    return api.RequestTexture(path, size);
                }

                return Promise.reject(
                    new Error("Texture requests are unavailable outside Arma."),
                );
            },
            send(event, data = {}) {
                if (
                    !api ||
                    typeof api.SendAlert !== "function" ||
                    typeof event !== "string" ||
                    event === ""
                ) {
                    return false;
                }

                api.SendAlert(
                    JSON.stringify({
                        event,
                        data,
                    }),
                );
                return true;
            },
        };
    }

    ForgeWebUI.createHost = createHost;
})(window);

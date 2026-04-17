(function (global) {
    const ForgeWebUI = (global.ForgeWebUI = global.ForgeWebUI || {});

    function createBridge(options = {}) {
        const host =
            options.host && typeof options.host === "object"
                ? options.host
                : ForgeWebUI.createHost();
        const globalName = options.globalName || "ForgeBridge";
        const readyEvent = options.readyEvent || "ui::ready";
        const closeEvent = options.closeEvent || "ui::close";
        const listeners = new Map();

        function getListeners(eventName) {
            if (!listeners.has(eventName)) {
                listeners.set(eventName, new Set());
            }

            return listeners.get(eventName);
        }

        function emit(eventName, payload) {
            const eventListeners = listeners.get(eventName);
            if (!eventListeners || eventListeners.size === 0) {
                return;
            }

            eventListeners.forEach((listener) => {
                try {
                    listener(payload);
                } catch (error) {
                    console.error(
                        `[ForgeWebUI] Bridge listener failed for ${eventName}.`,
                        error,
                    );
                }
            });
        }

        function receive(eventOrPayload, data = {}) {
            const eventName =
                typeof eventOrPayload === "object" && eventOrPayload !== null
                    ? String(eventOrPayload.event || "")
                    : String(eventOrPayload || "");
            const payload =
                typeof eventOrPayload === "object" && eventOrPayload !== null
                    ? eventOrPayload.data || {}
                    : data;

            if (!eventName) {
                return false;
            }

            emit(eventName, payload);
            emit("*", { data: payload, event: eventName });
            return true;
        }

        function receiveMany(events) {
            if (!Array.isArray(events)) {
                return false;
            }

            events.forEach((payload) => receive(payload));
            return true;
        }

        const globalBridge = {
            ping() {
                return true;
            },
            receive,
            receiveMany,
            reset() {
                listeners.clear();
                return true;
            },
        };

        const api = {
            close(data = {}) {
                return host.send(closeEvent, data);
            },
            emit,
            host,
            installCompatibility(name) {
                if (name) {
                    global[name] = globalBridge;
                }

                return api;
            },
            off(eventName, listener) {
                const eventListeners = listeners.get(eventName);
                if (!eventListeners) {
                    return false;
                }

                eventListeners.delete(listener);
                if (eventListeners.size === 0) {
                    listeners.delete(eventName);
                }

                return true;
            },
            on(eventName, listener) {
                getListeners(eventName).add(listener);
                return () => api.off(eventName, listener);
            },
            ready(data = { loaded: true }) {
                return host.send(readyEvent, data);
            },
            receive,
            receiveMany,
            request(eventName, payload = {}) {
                return host.send(eventName, payload);
            },
            send(eventName, payload = {}) {
                return host.send(eventName, payload);
            },
        };

        global[globalName] = globalBridge;
        return api;
    }

    ForgeWebUI.createBridge = createBridge;
})(window);

(function () {
    const GarageApp = (window.GarageApp = window.GarageApp || {});
    const store = GarageApp.store;
    const bridge = window.ForgeWebUI.createBridge({
        closeEvent: "garage::close",
        globalName: "ForgeBridge",
        readyEvent: "garage::ready",
    });

    function requestClose() {
        return bridge.close({});
    }

    function requestRefresh() {
        return bridge.send("garage::refresh", {});
    }

    function requestRetrieve(payload) {
        return bridge.send("garage::vehicle::retrieve::request", payload);
    }

    function requestStore(payload) {
        return bridge.send("garage::vehicle::store::request", payload);
    }

    function requestRefuel(payload) {
        return bridge.send("garage::vehicle::refuel::request", payload);
    }

    function requestRepair(payload) {
        return bridge.send("garage::vehicle::repair::request", payload);
    }

    function requestRearm(payload) {
        return bridge.send("garage::vehicle::rearm::request", payload);
    }

    function notifyReady() {
        return bridge.ready({ loaded: true });
    }

    function hydrate(payloadData) {
        GarageApp.data.applyHydratePayload(payloadData);
        store.hydrateFromPayload(payloadData);
    }

    bridge.on("garage::hydrate", hydrate);
    bridge.on("garage::sync", hydrate);

    bridge.on("garage::retrieve::success", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "success",
                payloadData.message || "Vehicle retrieved from the garage.",
            );
        }
    });

    bridge.on("garage::retrieve::failure", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "error",
                payloadData.message || "Unable to retrieve vehicle.",
            );
        }
    });

    bridge.on("garage::store::success", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "success",
                payloadData.message || "Vehicle stored in the garage.",
            );
        }
    });

    bridge.on("garage::store::failure", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "error",
                payloadData.message || "Unable to store vehicle.",
            );
        }
    });

    bridge.on("garage::service::success", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "success",
                payloadData.message || "Service request sent.",
            );
        }
    });

    bridge.on("garage::service::failure", (payloadData) => {
        store.finishAction();
        if (GarageApp.actions) {
            GarageApp.actions.showNotice(
                "error",
                payloadData.message || "Unable to service vehicle.",
            );
        }
    });

    GarageApp.bridge = {
        notifyReady,
        receive: bridge.receive,
        requestClose,
        requestRefresh,
        requestRearm,
        requestRefuel,
        requestRepair,
        requestRetrieve,
        requestStore,
        sendEvent: bridge.send,
    };
})();

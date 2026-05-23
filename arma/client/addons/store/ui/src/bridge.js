(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const store = StorefrontApp.store;
    const bridge = window.ForgeWebUI.createBridge({
        closeEvent: "store::close",
        globalName: "StoreUIBridge",
        readyEvent: "store::ready",
    });

    function requestClose() {
        return bridge.close({});
    }

    function requestCheckout(payload) {
        return bridge.send("store::checkout::request", payload);
    }

    function requestCategory(payload) {
        return bridge.send("store::category::request", payload);
    }

    function notifyReady() {
        return bridge.ready({ loaded: true });
    }

    bridge.on("store::hydrate", (payloadData) => {
        StorefrontApp.data.applyHydratePayload(payloadData);
        store.hydrateFromPayload(payloadData);
    });

    bridge.on("store::config::hydrate", (payloadData) => {
        StorefrontApp.data.applyHydratePayload(payloadData);
        store.hydrateStoreConfig(payloadData);
    });

    bridge.on("store::checkout::success", (payloadData) => {
        store.setIsCheckingOut(false);
        store.setCartItems([]);
        store.setCartOpen(false);
        if (StorefrontApp.actions) {
            StorefrontApp.actions.showNotice(
                "success",
                payloadData.message || "Checkout completed.",
            );
        }
    });

    bridge.on("store::category::hydrate", (payloadData) => {
        store.hydrateCategoryItems(payloadData);
    });

    bridge.on("store::category::failure", (payloadData) => {
        store.finishCategoryRequest(payloadData.category || "");
        if (StorefrontApp.actions) {
            StorefrontApp.actions.showNotice(
                "error",
                payloadData.message || "Category request failed.",
            );
        }
    });

    bridge.on("store::checkout::failure", (payloadData) => {
        store.setIsCheckingOut(false);
        if (StorefrontApp.actions) {
            StorefrontApp.actions.showNotice(
                "error",
                payloadData.message || "Checkout failed.",
            );
        }
    });

    StorefrontApp.bridge = {
        close: bridge.close,
        requestClose,
        requestCheckout,
        requestCategory,
        notifyReady,
        receive: bridge.receive,
        sendEvent: bridge.send,
    };
})();

(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const store = BankApp.store;
    const bridge = window.ForgeWebUI.createBridge({
        closeEvent: "bank::close",
        globalName: "ForgeBridge",
        readyEvent: "bank::ready",
    });

    function hydrate(payloadData) {
        BankApp.data.applyHydratePayload(payloadData);
        store.hydrateFromPayload(payloadData);
    }

    function syncAccount(payloadData) {
        BankApp.data.applyAccountPatch(payloadData);
        store.syncAccountPatch();
    }

    bridge.on("bank::hydrate", hydrate);
    bridge.on("bank::sync", syncAccount);
    bridge.on("bank::notice", (payloadData) => {
        store.finishAction();
        if (BankApp.actions) {
            BankApp.actions.showNotice(
                payloadData.type || "error",
                payloadData.message || "Bank notice received.",
            );
        }
    });

    BankApp.bridge = {
        notifyReady() {
            return bridge.ready({ loaded: true });
        },
        receive: bridge.receive,
        requestClose() {
            return bridge.close({});
        },
        requestDeposit(payload) {
            return bridge.send("bank::deposit::request", payload);
        },
        requestDepositEarnings(payload) {
            return bridge.send("bank::depositEarnings::request", payload);
        },
        requestRepayCreditLine(payload) {
            return bridge.send("bank::repayCreditLine::request", payload);
        },
        requestRefresh() {
            return bridge.send("bank::refresh", {});
        },
        requestSubmitPin(payload) {
            return bridge.send("bank::pin::request", payload);
        },
        requestTransfer(payload) {
            return bridge.send("bank::transfer::request", payload);
        },
        requestWithdraw(payload) {
            return bridge.send("bank::withdraw::request", payload);
        },
        sendEvent: bridge.send,
    };
})();

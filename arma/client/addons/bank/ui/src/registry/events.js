(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const store = BankApp.store;

    let noticeTimer = null;

    function normalizeAmount(value) {
        const amount = Math.floor(Number(value || 0));
        return Number.isFinite(amount) ? amount : 0;
    }

    function showNotice(type, text) {
        store.setNotice({ type, text });

        if (noticeTimer) {
            clearTimeout(noticeTimer);
        }

        noticeTimer = setTimeout(() => {
            store.setNotice({ text: "", type: "" });
            noticeTimer = null;
        }, 3200);
    }

    function closeBank() {
        const bridge = BankApp.bridge;
        if (bridge && typeof bridge.requestClose === "function") {
            const sent = bridge.requestClose();
            if (sent) {
                return true;
            }
        }

        showNotice("error", "Bank bridge is unavailable.");
        return false;
    }

    function refreshBank() {
        const bridge = BankApp.bridge;
        if (bridge && typeof bridge.requestRefresh === "function") {
            const sent = bridge.requestRefresh();
            if (sent) {
                return true;
            }
        }

        showNotice("error", "Bank refresh bridge is unavailable.");
        return false;
    }

    function requestDeposit(amountValue) {
        const amount = normalizeAmount(amountValue);
        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestDeposit !== "function") {
            showNotice("error", "Deposit bridge is unavailable.");
            return false;
        }

        store.startAction("deposit");
        const sent = bridge.requestDeposit({ amount });
        if (!sent) {
            store.finishAction();
            showNotice("error", "Deposit bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestWithdraw(amountValue) {
        const amount = normalizeAmount(amountValue);
        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestWithdraw !== "function") {
            showNotice("error", "Withdraw bridge is unavailable.");
            return false;
        }

        store.startAction("withdraw");
        const sent = bridge.requestWithdraw({ amount });
        if (!sent) {
            store.finishAction();
            showNotice("error", "Withdraw bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestTransfer(targetUid, amountValue) {
        const amount = normalizeAmount(amountValue);
        const targetId = String(targetUid || "").trim();

        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestTransfer !== "function") {
            showNotice("error", "Transfer bridge is unavailable.");
            return false;
        }

        store.startAction("transfer");
        const sent = bridge.requestTransfer({
            amount,
            from: "bank",
            target: targetId,
        });
        if (!sent) {
            store.finishAction();
            showNotice("error", "Transfer bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestDepositEarnings(amountValue) {
        const amount = normalizeAmount(amountValue);
        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestDepositEarnings !== "function") {
            showNotice("error", "Earnings bridge is unavailable.");
            return false;
        }

        store.startAction("depositearnings");
        const sent = bridge.requestDepositEarnings({ amount });
        if (!sent) {
            store.finishAction();
            showNotice("error", "Earnings bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestRepayCreditLine(amountValue) {
        const amount = normalizeAmount(amountValue);
        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestRepayCreditLine !== "function") {
            showNotice("error", "Credit repayment bridge is unavailable.");
            return false;
        }

        store.startAction("repaycreditline");
        const sent = bridge.requestRepayCreditLine({ amount });
        if (!sent) {
            store.finishAction();
            showNotice("error", "Credit repayment bridge is unavailable.");
            return false;
        }

        return true;
    }

    function appendPinDigit(digit) {
        const nextDigit = String(digit || "").trim();
        if (!nextDigit) {
            return;
        }

        const currentPin = String(store.getEnteredPin() || "");
        if (currentPin.length >= 4) {
            return;
        }

        store.setEnteredPin(currentPin + nextDigit);
    }

    function backspacePin() {
        const currentPin = String(store.getEnteredPin() || "");
        store.setEnteredPin(currentPin.slice(0, -1));
    }

    function clearPin() {
        store.setEnteredPin("");
    }

    function submitPin() {
        const enteredPin = String(store.getEnteredPin() || "");
        const bridge = BankApp.bridge;
        if (!bridge || typeof bridge.requestSubmitPin !== "function") {
            showNotice("error", "PIN bridge is unavailable.");
            return false;
        }

        store.startAction("pin");
        const sent = bridge.requestSubmitPin({ pin: enteredPin });
        if (!sent) {
            store.finishAction();
            showNotice("error", "PIN bridge is unavailable.");
            return false;
        }

        clearPin();
        return true;
    }

    function selectAtmView(view) {
        const nextView = String(view || "").trim();
        if (!nextView) {
            return false;
        }

        if (nextView === "pin") {
            store.resetAtm();
            return true;
        }

        store.setCustomAmount("");
        store.setAtmView(nextView);
        return true;
    }

    function appendCustomAmountDigit(digit) {
        const nextDigit = String(digit || "").trim();
        if (!nextDigit) {
            return;
        }

        const currentValue = String(store.getCustomAmount() || "");
        if (currentValue.length >= 7) {
            return;
        }

        store.setCustomAmount(currentValue + nextDigit);
    }

    function backspaceCustomAmount() {
        const currentValue = String(store.getCustomAmount() || "");
        store.setCustomAmount(currentValue.slice(0, -1));
    }

    function clearCustomAmount() {
        store.setCustomAmount("");
    }

    function submitCustomAmount(kind) {
        const amount = normalizeAmount(store.getCustomAmount());
        const nextKind = String(kind || "")
            .trim()
            .toLowerCase();

        if (amount <= 0) {
            showNotice("error", "Enter a valid transaction amount.");
            return false;
        }

        const success =
            nextKind === "deposit"
                ? requestDeposit(amount)
                : requestWithdraw(amount);

        if (success) {
            store.setCustomAmount("");
        }

        return success;
    }

    function requestAtmAmount(kind, amount) {
        const nextKind = String(kind || "")
            .trim()
            .toLowerCase();
        const success =
            nextKind === "deposit"
                ? requestDeposit(amount)
                : requestWithdraw(amount);

        return success;
    }

    BankApp.actions = {
        appendCustomAmountDigit,
        appendPinDigit,
        backspaceCustomAmount,
        backspacePin,
        clearCustomAmount,
        clearPin,
        closeBank,
        refreshBank,
        requestAtmAmount,
        requestDeposit,
        requestDepositEarnings,
        requestRepayCreditLine,
        requestTransfer,
        requestWithdraw,
        selectAtmView,
        showNotice,
        submitCustomAmount,
        submitPin,
    };
})();

(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const store = BankApp.store;
    const { account } = BankApp.data;

    function formatCurrency(value) {
        return `$${Math.round(Number(value || 0)).toLocaleString()}`;
    }

    function pending(actionName) {
        return store.getPendingAction() === actionName;
    }

    function statCard(label, value, tone = "") {
        return h(
            "div",
            {
                className: tone
                    ? `bank-stat-card is-${tone}`
                    : "bank-stat-card",
            },
            h("span", { className: "bank-stat-label" }, label),
            h("span", { className: "bank-stat-value" }, value),
        );
    }

    function metricCard(label, value, copy, tone = "") {
        return h(
            "div",
            {
                className: tone
                    ? `bank-metric-card is-${tone}`
                    : "bank-metric-card",
            },
            h("span", { className: "bank-eyebrow" }, label),
            h("span", { className: "bank-metric-value" }, value),
            h("span", { className: "bank-metric-copy" }, copy),
        );
    }

    function pinIndicators(value) {
        const pin = String(value || "");

        return h(
            "div",
            { className: "bank-pin-indicators" },
            [0, 1, 2, 3].map((index) =>
                h("span", {
                    className:
                        index < pin.length
                            ? "bank-pin-indicator is-filled"
                            : "bank-pin-indicator",
                }),
            ),
        );
    }

    function readInputValue(id) {
        return document.getElementById(id)?.value || "";
    }

    function clearInputValue(id) {
        const input = document.getElementById(id);
        if (input) {
            input.value = "";
        }
    }

    function keypad(onDigit, onBackspace, onClear, onEnter) {
        const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];

        return h(
            "div",
            { className: "bank-keypad" },
            keys.map((digit) =>
                h(
                    "button",
                    {
                        type: "button",
                        className: "bank-key",
                        onClick: () => onDigit(digit),
                    },
                    digit,
                ),
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-key is-muted",
                    onClick: onClear,
                },
                "C",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-key",
                    onClick: () => onDigit("0"),
                },
                "0",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-key is-accent",
                    onClick: onEnter,
                },
                "Enter",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-key is-wide",
                    onClick: onBackspace,
                },
                "Backspace",
            ),
        );
    }

    function transactionRows() {
        const transactions = Array.isArray(account.transactions)
            ? account.transactions
            : [];

        if (transactions.length === 0) {
            return h(
                "div",
                { className: "bank-empty-state" },
                h("h3", { className: "bank-empty-title" }, "No transactions"),
                h(
                    "p",
                    { className: "bank-empty-copy" },
                    "Deposits, withdrawals, and transfers will appear here after the account begins moving funds.",
                ),
            );
        }

        return h(
            "div",
            { className: "bank-history-list" },
            transactions
                .slice(0, 8)
                .map((entry) =>
                    h(
                        "div",
                        { className: "bank-history-row" },
                        h(
                            "div",
                            { className: "bank-history-copy" },
                            h(
                                "span",
                                { className: "bank-history-title" },
                                entry.type || "Transaction",
                            ),
                            h(
                                "span",
                                { className: "bank-history-meta" },
                                entry.date || "Pending timestamp",
                            ),
                        ),
                        h(
                            "span",
                            { className: "bank-history-value" },
                            formatCurrency(entry.amount || 0),
                        ),
                    ),
                ),
        );
    }

    BankApp.componentFns = BankApp.componentFns || {};
    Object.assign(BankApp.componentFns, {
        clearInputValue,
        formatCurrency,
        keypad,
        metricCard,
        pending,
        pinIndicators,
        readInputValue,
        statCard,
        transactionRows,
    });
})();

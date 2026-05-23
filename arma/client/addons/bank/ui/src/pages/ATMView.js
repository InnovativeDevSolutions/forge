(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const store = BankApp.store;
    const actions = BankApp.actions;
    const { account } = BankApp.data;
    const { formatCurrency, keypad, pinIndicators } = BankApp.componentFns;

    function atmMenuCard() {
        return h(
            "div",
            { className: "bank-atm-action-grid" },
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-primary",
                    onClick: () => actions.selectAtmView("withdraw"),
                },
                "Withdraw Cash",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-primary",
                    onClick: () => actions.selectAtmView("deposit"),
                },
                "Deposit Cash",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-secondary",
                    onClick: () => actions.selectAtmView("balance"),
                },
                "Check Balance",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-secondary",
                    onClick: () => actions.closeBank(),
                },
                "Exit Terminal",
            ),
        );
    }

    function atmAmountMenu(kind) {
        const label = kind === "deposit" ? "Deposit" : "Withdraw";
        const amounts = [20, 50, 100, 500];

        return h(
            "div",
            { className: "bank-atm-action-grid" },
            amounts.map((amount) =>
                h(
                    "button",
                    {
                        type: "button",
                        className: "bank-btn bank-btn-primary",
                        onClick: () => actions.requestAtmAmount(kind, amount),
                    },
                    `${label} ${formatCurrency(amount)}`,
                ),
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-secondary",
                    onClick: () =>
                        actions.selectAtmView(
                            kind === "deposit"
                                ? "customDeposit"
                                : "customWithdraw",
                        ),
                },
                "Custom Amount",
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-secondary",
                    onClick: () => actions.selectAtmView("menu"),
                },
                "Back",
            ),
        );
    }

    function atmCustomAmount(kind) {
        const label = kind === "deposit" ? "Deposit" : "Withdraw";

        return h(
            "div",
            { className: "bank-atm-stack" },
            h(
                "div",
                { className: "bank-pin-display" },
                store.getCustomAmount()
                    ? formatCurrency(store.getCustomAmount())
                    : "$0",
            ),
            keypad(
                actions.appendCustomAmountDigit,
                actions.backspaceCustomAmount,
                actions.clearCustomAmount,
                () => actions.submitCustomAmount(kind),
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "bank-btn bank-btn-secondary",
                    onClick: () => actions.selectAtmView("menu"),
                },
                `Cancel ${label}`,
            ),
        );
    }

    BankApp.componentFns = BankApp.componentFns || {};
    BankApp.componentFns.ATMView = function ATMView() {
        store.getAccountVersion();
        const atmViewName = store.getAtmView();
        const enteredPin = String(store.getEnteredPin() || "");
        let title = "Terminal Access";
        let copy =
            "Authenticate with the four-digit account PIN before using the terminal.";
        let content = null;

        switch (atmViewName) {
            case "menu":
                title = "ATM Menu";
                copy =
                    "Select a banking action. The ATM can deposit, withdraw, and show the live account balance.";
                content = atmMenuCard();
                break;
            case "withdraw":
                title = "Withdraw Cash";
                copy =
                    "Choose a preset amount or enter a custom amount for withdrawal.";
                content = atmAmountMenu("withdraw");
                break;
            case "deposit":
                title = "Deposit Cash";
                copy =
                    "Move cash on hand back into the main bank balance from the terminal.";
                content = atmAmountMenu("deposit");
                break;
            case "customWithdraw":
                title = "Custom Withdraw";
                copy = "Enter the exact withdrawal amount.";
                content = atmCustomAmount("withdraw");
                break;
            case "customDeposit":
                title = "Custom Deposit";
                copy = "Enter the exact deposit amount.";
                content = atmCustomAmount("deposit");
                break;
            case "balance":
                title = "Available Balance";
                copy = "Current bank balance available at this terminal.";
                content = h(
                    "div",
                    { className: "bank-atm-stack" },
                    h(
                        "div",
                        { className: "bank-balance-display" },
                        formatCurrency(account.bank),
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-primary",
                            onClick: () => actions.selectAtmView("menu"),
                        },
                        "Return to Menu",
                    ),
                );
                break;
            default:
                content = h(
                    "div",
                    { className: "bank-atm-stack" },
                    h(
                        "div",
                        { className: "bank-pin-display" },
                        pinIndicators(enteredPin),
                    ),
                    keypad(
                        actions.appendPinDigit,
                        actions.backspacePin,
                        actions.clearPin,
                        actions.submitPin,
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-secondary",
                            onClick: () => actions.closeBank(),
                        },
                        "Exit Terminal",
                    ),
                );
                break;
        }

        return h(
            "div",
            { className: "bank-atm-shell" },
            h(
                "section",
                { className: "bank-atm-panel" },
                h(
                    "div",
                    { className: "bank-panel-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "ATM"),
                        h("h1", { className: "bank-title" }, title),
                    ),
                    h("span", { className: "bank-pill" }, "Secure Terminal"),
                ),
                h("p", { className: "bank-panel-copy" }, copy),
                content,
            ),
        );
    };
})();

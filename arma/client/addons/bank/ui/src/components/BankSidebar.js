(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const store = BankApp.store;
    const actions = BankApp.actions;
    const { account, session } = BankApp.data;
    const { formatCurrency, statCard } = BankApp.componentFns;

    BankApp.componentFns = BankApp.componentFns || {};
    BankApp.componentFns.BankSidebar = function BankSidebar() {
        store.getAccountVersion();
        store.getSessionVersion();

        return h(
            "aside",
            { className: "bank-sidebar" },
            h(
                "section",
                { className: "bank-module" },
                h(
                    "div",
                    { className: "bank-module-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Account"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Balances",
                        ),
                    ),
                    h("span", { className: "bank-pill" }, "Live"),
                ),
                h(
                    "div",
                    { className: "bank-summary-grid" },
                    statCard("Bank", formatCurrency(account.bank), "accent"),
                    statCard("Cash", formatCurrency(account.cash)),
                    statCard(
                        "Earnings",
                        formatCurrency(account.earnings),
                        account.earnings > 0 ? "warning" : "",
                    ),
                    statCard(
                        "Org Funds",
                        formatCurrency(session.orgFunds),
                        session.orgFunds > 0 ? "success" : "",
                    ),
                ),
            ),
            h(
                "section",
                { className: "bank-module" },
                h(
                    "div",
                    { className: "bank-module-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Profile"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Account Holder",
                        ),
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-secondary",
                            onClick: () => actions.refreshBank(),
                        },
                        "Refresh",
                    ),
                ),
                h(
                    "div",
                    { className: "bank-profile-stack" },
                    statCard("Name", session.playerName || "Unknown"),
                    statCard("UID", session.uid || "-"),
                    statCard(
                        "Organization",
                        session.orgName || "No active organization",
                    ),
                ),
            ),
        );
    };
})();

(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const store = BankApp.store;
    const actions = BankApp.actions;
    const { account, session } = BankApp.data;
    const {
        clearInputValue,
        formatCurrency,
        metricCard,
        pending,
        readInputValue,
        transactionRows,
    } = BankApp.componentFns;

    function trackAccount() {
        store.getAccountVersion();
    }

    function trackSession() {
        store.getSessionVersion();
    }

    function pageHeader() {
        trackSession();

        return h(
            "div",
            { className: "bank-page-header" },
            h(
                "div",
                null,
                h("span", { className: "bank-eyebrow" }, "Treasury Desk"),
                h("h1", { className: "bank-title" }, "Personal Banking"),
            ),
            h(
                "span",
                { className: "bank-pill" },
                session.playerName || "Account Holder",
            ),
        );
    }

    function summarySection() {
        trackAccount();
        trackSession();

        return h(
            "section",
            { className: "bank-page-section bank-summary-section" },
            h(
                "div",
                { className: "bank-section-header" },
                h(
                    "div",
                    null,
                    h("span", { className: "bank-eyebrow" }, "Overview"),
                    h(
                        "h2",
                        { className: "bank-section-title" },
                        "Financial Position",
                    ),
                ),
                h("span", { className: "bank-pill" }, "Banking Desk"),
            ),
            h(
                "div",
                { className: "bank-summary-band" },
                metricCard(
                    "Primary Balance",
                    formatCurrency(account.bank),
                    "Available for transfers and withdrawals.",
                    "accent",
                ),
                metricCard(
                    "Cash On Hand",
                    formatCurrency(account.cash),
                    "Funds currently carried by the player.",
                ),
                metricCard(
                    "Pending Earnings",
                    formatCurrency(account.earnings),
                    "Ready to sweep into the main account ledger.",
                    account.earnings > 0 ? "warning" : "",
                ),
                metricCard(
                    "Org Snapshot",
                    formatCurrency(session.orgFunds),
                    "Reference value pulled from the organization treasury.",
                    session.orgFunds > 0 ? "success" : "",
                ),
                metricCard(
                    "Credit Due",
                    formatCurrency(session.creditLine?.amountDue || 0),
                    Number(session.creditLine?.amountDue || 0) > 0
                        ? `Outstanding principal ${formatCurrency(session.creditLine?.outstandingPrincipal || 0)} at ${Math.round(Number(session.creditLine?.interestRate || 0) * 100)}% interest.`
                        : "No active credit repayment is currently due.",
                    Number(session.creditLine?.amountDue || 0) > 0
                        ? "warning"
                        : "",
                ),
            ),
        );
    }

    function actionSections() {
        trackSession();

        return h(
            "div",
            { className: "bank-action-sections" },
            h(
                "section",
                { className: "bank-page-section" },
                h(
                    "div",
                    { className: "bank-section-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Movement"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Deposit / Withdraw",
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "bank-form-stack" },
                    h("input", {
                        id: "bank-amount-input",
                        className: "bank-input",
                        type: "number",
                        min: "1",
                        placeholder: "Enter amount",
                    }),
                    h(
                        "div",
                        { className: "bank-action-row" },
                        h(
                            "button",
                            {
                                type: "button",
                                className: "bank-btn bank-btn-primary",
                                disabled: pending("deposit"),
                                onClick: () => {
                                    const sent = actions.requestDeposit(
                                        readInputValue("bank-amount-input"),
                                    );
                                    if (sent) {
                                        clearInputValue("bank-amount-input");
                                    }
                                },
                            },
                            pending("deposit") ? "Depositing..." : "Deposit",
                        ),
                        h(
                            "button",
                            {
                                type: "button",
                                className: "bank-btn bank-btn-secondary",
                                disabled: pending("withdraw"),
                                onClick: () => {
                                    const sent = actions.requestWithdraw(
                                        readInputValue("bank-amount-input"),
                                    );
                                    if (sent) {
                                        clearInputValue("bank-amount-input");
                                    }
                                },
                            },
                            pending("withdraw") ? "Withdrawing..." : "Withdraw",
                        ),
                    ),
                ),
            ),
            h(
                "section",
                { className: "bank-page-section" },
                h(
                    "div",
                    { className: "bank-section-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Transfer"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Wire Funds",
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "bank-form-stack" },
                    h(
                        "select",
                        {
                            id: "bank-transfer-target",
                            className: "bank-select",
                        },
                        h(
                            "option",
                            { value: "" },
                            session.transferTargets.length > 0
                                ? "Select recipient"
                                : "No available recipients",
                        ),
                        session.transferTargets.map((entry) =>
                            h(
                                "option",
                                { value: entry.uid },
                                entry.name || entry.uid,
                            ),
                        ),
                    ),
                    h("input", {
                        id: "bank-transfer-amount",
                        className: "bank-input",
                        type: "number",
                        min: "1",
                        placeholder: "Enter transfer amount",
                    }),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-primary",
                            disabled:
                                pending("transfer") ||
                                session.transferTargets.length === 0,
                            onClick: () => {
                                const sent = actions.requestTransfer(
                                    readInputValue("bank-transfer-target"),
                                    readInputValue("bank-transfer-amount"),
                                );
                                if (sent) {
                                    clearInputValue("bank-transfer-amount");
                                }
                            },
                        },
                        pending("transfer")
                            ? "Transferring..."
                            : "Transfer Funds",
                    ),
                ),
            ),
            h(
                "section",
                { className: "bank-page-section" },
                h(
                    "div",
                    { className: "bank-section-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Credit"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Repay Org Credit",
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "bank-form-stack" },
                    h(
                        "p",
                        { className: "bank-card-copy" },
                        Number(session.creditLine?.amountDue || 0) > 0
                            ? `Outstanding due ${formatCurrency(session.creditLine.amountDue || 0)}. Available reserved credit ${formatCurrency(session.creditLine.availableAmount || 0)}.`
                            : "No repayment is currently due on the assigned organization credit line.",
                    ),
                    h("input", {
                        id: "bank-credit-line-amount",
                        className: "bank-input",
                        type: "number",
                        min: "1",
                        placeholder: "Enter repayment amount",
                    }),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-primary",
                            disabled:
                                pending("repaycreditline") ||
                                Number(session.creditLine?.amountDue || 0) <= 0,
                            onClick: () => {
                                const sent = actions.requestRepayCreditLine(
                                    readInputValue("bank-credit-line-amount"),
                                );
                                if (sent) {
                                    clearInputValue("bank-credit-line-amount");
                                }
                            },
                        },
                        pending("repaycreditline")
                            ? "Posting Repayment..."
                            : "Repay Credit Line",
                    ),
                ),
            ),
        );
    }

    function supportSection() {
        trackAccount();

        return h(
            "div",
            { className: "bank-support-sections" },
            h(
                "section",
                { className: "bank-page-section" },
                h(
                    "div",
                    { className: "bank-section-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Sweep"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Deposit Earnings",
                        ),
                    ),
                ),
                h(
                    "p",
                    { className: "bank-card-copy" },
                    "Sweep pending earnings into the primary account when you want them reflected in the main balance.",
                ),
                h(
                    "button",
                    {
                        type: "button",
                        className: "bank-btn bank-btn-primary",
                        disabled:
                            pending("depositearnings") ||
                            Number(account.earnings || 0) <= 0,
                        onClick: () =>
                            actions.requestDepositEarnings(account.earnings),
                    },
                    pending("depositearnings")
                        ? "Depositing..."
                        : "Deposit Earnings",
                ),
            ),
            h(
                "section",
                { className: "bank-page-section" },
                h(
                    "div",
                    { className: "bank-section-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "bank-eyebrow" }, "Security"),
                        h(
                            "h2",
                            { className: "bank-section-title" },
                            "Change ATM PIN",
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "bank-form-stack" },
                    h("input", {
                        id: "bank-current-pin",
                        className: "bank-input",
                        type: "password",
                        inputMode: "numeric",
                        maxLength: "4",
                        placeholder: "Current PIN",
                    }),
                    h("input", {
                        id: "bank-new-pin",
                        className: "bank-input",
                        type: "password",
                        inputMode: "numeric",
                        maxLength: "4",
                        placeholder: "New PIN",
                    }),
                    h("input", {
                        id: "bank-confirm-pin",
                        className: "bank-input",
                        type: "password",
                        inputMode: "numeric",
                        maxLength: "4",
                        placeholder: "Confirm new PIN",
                    }),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "bank-btn bank-btn-primary",
                            disabled: pending("changepin"),
                            onClick: () => {
                                const sent = actions.requestChangePin(
                                    readInputValue("bank-current-pin"),
                                    readInputValue("bank-new-pin"),
                                    readInputValue("bank-confirm-pin"),
                                );
                                if (sent) {
                                    clearInputValue("bank-current-pin");
                                    clearInputValue("bank-new-pin");
                                    clearInputValue("bank-confirm-pin");
                                }
                            },
                        },
                        pending("changepin") ? "Updating PIN..." : "Update PIN",
                    ),
                ),
            ),
        );
    }

    function historySection() {
        trackAccount();

        return h(
            "section",
            { className: "bank-page-section bank-history-section" },
            h(
                "div",
                { className: "bank-section-header" },
                h(
                    "div",
                    null,
                    h("span", { className: "bank-eyebrow" }, "History"),
                    h(
                        "h2",
                        { className: "bank-section-title" },
                        "Recent Transactions",
                    ),
                ),
            ),
            transactionRows(),
        );
    }

    BankApp.componentFns = BankApp.componentFns || {};
    BankApp.componentFns.BankPageHeader = pageHeader;
    BankApp.componentFns.BankSummarySection = summarySection;
    BankApp.componentFns.BankActionSections = actionSections;
    BankApp.componentFns.BankSupportSection = supportSection;
    BankApp.componentFns.BankHistorySection = historySection;
})();

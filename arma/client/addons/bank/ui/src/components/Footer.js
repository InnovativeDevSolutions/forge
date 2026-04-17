(function () {
    const BankApp = (window.BankApp = window.BankApp || {});
    const { h } = BankApp.runtime;
    const store = BankApp.store;
    const { account, session } = BankApp.data;
    const { formatCurrency } = BankApp.componentFns;

    BankApp.componentFns = BankApp.componentFns || {};
    BankApp.componentFns.BankFooter = function BankFooter() {
        store.getAccountVersion();
        store.getSessionVersion();

        const sections = [
            {
                title: "Banking Resources",
                items: [
                    "Account Access Policy",
                    "Transfer & Wire Guidelines",
                    "Cash Handling Schedule",
                    "Terminal Security Notice",
                ],
            },
            {
                title: "Bank Support",
                items: session.orgName
                    ? [
                          `Organization: ${session.orgName}`,
                          `Treasury Reference: ${formatCurrency(session.orgFunds)}`,
                          `${session.transferTargets.length} transfer recipient(s) currently visible.`,
                          `Primary Ledger: ${formatCurrency(account.bank)}`,
                      ]
                    : [
                          "Organization: No active treasury link",
                          `${session.transferTargets.length} transfer recipient(s) currently visible.`,
                          `Primary Ledger: ${formatCurrency(account.bank)}`,
                          `Cash On Hand: ${formatCurrency(account.cash)}`,
                      ],
            },
        ];

        return h(
            "footer",
            { className: "bank-footer-bar" },
            h(
                "div",
                { className: "bank-footer" },
                ...sections.map((section) =>
                    h(
                        "div",
                        { className: "bank-footer-block" },
                        h(
                            "h3",
                            { className: "bank-footer-title" },
                            section.title,
                        ),
                        h(
                            "ul",
                            { className: "bank-footer-list" },
                            ...(section.items || []).map((item) =>
                                h(
                                    "li",
                                    { className: "bank-footer-copy" },
                                    item,
                                ),
                            ),
                        ),
                    ),
                ),
            ),
        );
    };
})();

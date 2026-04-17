(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle, createSignal } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const store = OrgPortal.store;
    const permissions = OrgPortal.permissions;
    const actions = OrgPortal.actions;
    const scopeAttr = "data-ui-treasury-card";
    const scopeSelector = `[${scopeAttr}]`;
    const [getTreasuryTab, setTreasuryTab] = createSignal("overview");
    const [getTreasuryMenuOpen, setTreasuryMenuOpen] = createSignal(false);
    const treasuryCardCss = `
${scopeSelector} .org-treasury-menu {
    position: relative;
}

${scopeSelector} .org-menu-btn {
    width: 2.75rem;
    height: 2.75rem;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    border: 1px solid var(--border);
    background: #f8fafc;
    color: var(--text-muted);
}

${scopeSelector} .org-menu-btn:hover {
    color: var(--primary-hover);
    border-color: rgb(148 163 184 / 0.65);
}

${scopeSelector} .org-menu-btn svg {
    width: 1.1rem;
    height: 1.1rem;
}

${scopeSelector} .org-menu-dropdown {
    position: absolute;
    top: calc(100% + 0.6rem);
    right: 0;
    min-width: 10.5rem;
    padding: 0.45rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #fff;
    box-shadow: 0 12px 28px rgb(15 23 42 / 0.12);
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
    z-index: 5;
}

${scopeSelector} .org-menu-option + .org-menu-option {
    margin-left: 0;
}

${scopeSelector} .org-menu-option {
    width: 100%;
    justify-content: flex-start;
    background: transparent;
    color: var(--text-main);
    border: 1px solid transparent;
}

${scopeSelector} .org-menu-option:hover {
    background: #f8fafc;
    border-color: rgb(148 163 184 / 0.35);
}

${scopeSelector} .org-menu-option.is-active {
    background: rgb(226 232 240 / 0.7);
    color: var(--primary-hover);
    border-color: rgb(148 163 184 / 0.35);
}

${scopeSelector} .org-finance-meta {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1rem;
    margin-bottom: 1.5rem;
}

${scopeSelector} .org-finance-meta > div {
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
}

${scopeSelector} .org-meta-label {
    font-size: 0.76rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
}

${scopeSelector} .org-action-grid {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1rem;
}

${scopeSelector} .org-action-grid button + button {
    margin-left: 0;
}

${scopeSelector} .org-action-grid button {
    width: 100%;
}

${scopeSelector} .org-access-note {
    margin: 0 0 1rem;
    color: var(--text-muted);
    font-size: 0.95rem;
}

${scopeSelector} .org-credit-summary {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    padding: 0.85rem 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-credit-summary strong {
    font-size: 1rem;
}

${scopeSelector} .org-credit-summary span:last-child {
    font-size: 0.92rem;
    line-height: 1.45;
}

${scopeSelector} .org-credit-lines-list {
    display: flex;
    flex-direction: column;
    gap: 0.85rem;
}

${scopeSelector} .org-credit-line-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-credit-line-row:nth-child(even) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(241 245 249) 100%);
    border-color: rgb(148 163 184 / 0.45);
}

${scopeSelector} .org-credit-line-member {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
}

${scopeSelector} .org-credit-line-label {
    font-size: 0.76rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
}

${scopeSelector} .org-credit-line-empty {
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
    color: var(--text-muted);
}

@media (max-width: 960px) {
    ${scopeSelector} .org-finance-meta {
        grid-template-columns: 1fr;
    }

    ${scopeSelector} .org-credit-line-row {
        flex-direction: column;
        align-items: flex-start;
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.TreasuryCard = function TreasuryCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        const creditLines = store.getCreditLines();
        const allowTreasuryActions = permissions.canManageTreasury();
        const activeTab = getTreasuryTab();
        const isMenuOpen = getTreasuryMenuOpen();
        const activeCreditLabel =
            creditLines.length === 1
                ? "1 active credit line"
                : `${creditLines.length} active credit lines`;
        ensureScopedStyle("portal-treasury-card", treasuryCardCss);

        return PanelCard({
            className: "org-span-5",
            title: "Treasury",
            subtitle: "Organization funds, reputation, and member payouts.",
            headerExtras: h(
                "div",
                { className: "org-treasury-menu" },
                h(
                    "button",
                    {
                        type: "button",
                        className: "org-menu-btn",
                        title: "Treasury views",
                        "aria-label": "Treasury views",
                        onClick: () => setTreasuryMenuOpen((open) => !open),
                    },
                    h(
                        "svg",
                        {
                            viewBox: "0 0 24 24",
                            fill: "none",
                            stroke: "currentColor",
                            "stroke-width": "2",
                            "stroke-linecap": "round",
                            "stroke-linejoin": "round",
                            "aria-hidden": "true",
                        },
                        h("line", { x1: "4", y1: "7", x2: "20", y2: "7" }),
                        h("line", { x1: "4", y1: "12", x2: "20", y2: "12" }),
                        h("line", { x1: "4", y1: "17", x2: "20", y2: "17" }),
                    ),
                ),
                isMenuOpen
                    ? h(
                          "div",
                          { className: "org-menu-dropdown" },
                          h(
                              "button",
                              {
                                  type: "button",
                                  className:
                                      activeTab === "overview"
                                          ? "org-menu-option is-active"
                                          : "org-menu-option",
                                  onClick: () => {
                                      setTreasuryTab("overview");
                                      setTreasuryMenuOpen(false);
                                  },
                              },
                              "Overview",
                          ),
                          h(
                              "button",
                              {
                                  type: "button",
                                  className:
                                      activeTab === "credit"
                                          ? "org-menu-option is-active"
                                          : "org-menu-option",
                                  onClick: () => {
                                      setTreasuryTab("credit");
                                      setTreasuryMenuOpen(false);
                                  },
                              },
                              "Credit Lines",
                          ),
                      )
                    : null,
            ),
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                null,
                activeTab === "credit"
                    ? creditLines.length > 0
                        ? h(
                              "div",
                              { className: "org-credit-lines-list" },
                              ...creditLines.map((line) =>
                                  h(
                                      "article",
                                      { className: "org-credit-line-row" },
                                      h(
                                          "div",
                                          {
                                              className:
                                                  "org-credit-line-member",
                                          },
                                          h(
                                              "span",
                                              {
                                                  className:
                                                      "org-credit-line-label",
                                              },
                                              "Member",
                                          ),
                                          h("strong", null, line.member),
                                      ),
                                      h(
                                          "div",
                                          {
                                              className:
                                                  "org-credit-line-member",
                                          },
                                          h(
                                              "span",
                                              {
                                                  className:
                                                      "org-credit-line-label",
                                              },
                                              "Amount",
                                          ),
                                          h(
                                              "strong",
                                              null,
                                              actions.formatCurrency(
                                                  line.amount,
                                              ),
                                          ),
                                      ),
                                  ),
                              ),
                          )
                        : h(
                              "div",
                              { className: "org-credit-line-empty" },
                              "No active credit lines.",
                          )
                    : h(
                          "div",
                          null,
                          h(
                              "div",
                              { className: "org-finance-meta" },
                              h(
                                  "div",
                                  null,
                                  h(
                                      "span",
                                      { className: "org-meta-label" },
                                      "Funds",
                                  ),
                                  h(
                                      "strong",
                                      null,
                                      actions.formatCurrency(store.getFunds()),
                                  ),
                              ),
                              h(
                                  "div",
                                  null,
                                  h(
                                      "span",
                                      { className: "org-meta-label" },
                                      "Reputation",
                                  ),
                                  h("strong", null, `${portalData.reputation}`),
                              ),
                          ),
                          allowTreasuryActions
                              ? h(
                                    "div",
                                    { className: "org-action-grid" },
                                    h(
                                        "button",
                                        {
                                            type: "button",
                                            onClick: () =>
                                                actions.openModal("payroll"),
                                        },
                                        "Run Payroll",
                                    ),
                                    h(
                                        "button",
                                        {
                                            type: "button",
                                            className: "org-secondary-btn",
                                            onClick: () =>
                                                actions.openModal("transfer"),
                                        },
                                        "Send Funds",
                                    ),
                                    h(
                                        "button",
                                        {
                                            type: "button",
                                            className: "org-secondary-btn",
                                            onClick: () =>
                                                actions.openModal("credit"),
                                        },
                                        "Credit Line",
                                    ),
                                )
                              : h(
                                    "p",
                                    { className: "org-access-note" },
                                    "Only the organization leader or CEO can manage treasury actions.",
                                ),
                          h(
                              "div",
                              { className: "org-credit-summary" },
                              h(
                                  "span",
                                  { className: "org-meta-label" },
                                  "Credit Line Status",
                              ),
                              h("strong", null, activeCreditLabel),
                              h(
                                  "span",
                                  null,
                                  creditLines.length > 0
                                      ? "Open the Credit Lines tab to review assigned members and amounts."
                                      : "Assign a credit line to create the first approved member limit.",
                              ),
                          ),
                      ),
            ),
        });
    };
})();

(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const { h, ensureScopedStyle } = StorefrontApp.runtime;
    const store = StorefrontApp.store;
    const getters = StorefrontApp.getters;
    const actions = StorefrontApp.actions;
    const { storeConfig } = StorefrontApp.data;
    const scopeAttr = "data-ui-store-cart";
    const scopeSelector = `[${scopeAttr}]`;
    const cartCss = `
${scopeSelector} {
    position: absolute;
    inset: 0;
    z-index: 4;
    pointer-events: none;
}

${scopeSelector}.is-open {
    pointer-events: auto;
}

${scopeSelector} .store-cart {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
    bottom: 0.5rem;
    width: min(24rem, calc(100% - 1rem));
    transform: translateX(calc(100% + 1rem));
    transition: transform 180ms ease;
}

${scopeSelector}.is-open .store-cart {
    transform: translateX(0);
}

${scopeSelector} .cart-card {
    height: 100%;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem;
    border-radius: 1.5rem;
    border: 1px solid var(--store-border);
    background: linear-gradient(180deg, var(--store-surface) 0%, var(--store-surface-alt) 100%);
    box-shadow:
        0 18px 40px rgb(11 27 46 / 0.16),
        0 4px 12px rgb(11 27 46 / 0.08);
}

${scopeSelector} .cart-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
}

${scopeSelector} .cart-close {
    min-width: 2.1rem;
    height: 2.1rem;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0;
    border-radius: 0.6rem;
    border: 1px solid var(--store-border-strong);
    background: rgb(255 255 255 / 0.78);
    color: var(--store-accent);
    font-size: 0.92rem;
    font-weight: 800;
    line-height: 1;
    box-shadow: 0 6px 16px rgb(18 54 93 / 0.08);
}

${scopeSelector} .cart-close:hover {
    background: var(--store-accent-soft);
    border-color: rgb(18 54 93 / 0.24);
    color: var(--store-accent);
}

${scopeSelector} .cart-close:focus-visible {
    outline: 2px solid rgb(18 54 93 / 0.25);
}

${scopeSelector} .cart-status,
${scopeSelector} .cart-kpi-card,
${scopeSelector} .cart-line {
    border-radius: 0.95rem;
    background: rgb(255 255 255 / 0.58);
    border: 1px solid var(--store-border);
}

${scopeSelector} .cart-status,
${scopeSelector} .cart-kpi-card,
${scopeSelector} .cart-line {
    padding: 0.95rem;
}

${scopeSelector} .cart-kpi {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 0.75rem;
}

${scopeSelector} .kpi-label {
    display: block;
    margin-bottom: 0.3rem;
    font-size: 0.68rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    font-weight: 700;
    color: var(--store-text-subtle);
}

${scopeSelector} .kpi-value {
    font-size: 1rem;
    font-weight: 700;
}

${scopeSelector} .cart-lines {
    flex: 1;
    min-height: 0;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    overflow-y: auto;
    overflow-x: hidden;
    scrollbar-gutter: stable;
    scrollbar-width: auto;
    scrollbar-color: rgb(120 136 155 / 0.9) rgb(255 255 255 / 0.55);
}

${scopeSelector} .cart-lines::-webkit-scrollbar {
    width: 12px;
}

${scopeSelector} .cart-lines::-webkit-scrollbar-track {
    background: rgb(255 255 255 / 0.55);
    border-radius: 999px;
}

${scopeSelector} .cart-lines::-webkit-scrollbar-thumb {
    background: rgb(120 136 155 / 0.9);
    border-radius: 999px;
    border: 2px solid rgb(255 255 255 / 0.55);
}

${scopeSelector} .cart-line {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

${scopeSelector} .cart-line-copy {
    min-width: 0;
    display: grid;
    gap: 0.18rem;
}

${scopeSelector} .cart-line-top,
${scopeSelector} .cart-line-controls,
${scopeSelector} .summary-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
}

${scopeSelector} .cart-line-title {
    font-size: 0.92rem;
    font-weight: 700;
    line-height: 1.32;
    overflow-wrap: anywhere;
    word-break: break-word;
}

${scopeSelector} .qty-controls {
    display: inline-flex;
    align-items: center;
    gap: 0.45rem;
}

${scopeSelector} .qty-badge {
    min-width: 1.9rem;
    text-align: center;
    font-weight: 700;
}

${scopeSelector} .qty-btn,
${scopeSelector} .remove-btn {
    min-width: 2rem;
    height: 2rem;
    padding: 0 0.65rem;
}

${scopeSelector} .cart-summary {
    padding-top: 0.25rem;
    border-top: 1px solid var(--store-accent-line);
    display: grid;
    gap: 0.7rem;
}

${scopeSelector} .payment-source-field {
    display: grid;
    gap: 0.65rem;
}

${scopeSelector} .payment-source-select {
    width: 100%;
    min-height: 2.9rem;
    padding: 0 0.95rem;
    border-radius: 0.8rem;
    border: 1px solid var(--store-border);
    background: rgb(255 255 255 / 0.78);
    color: var(--store-text-main);
}

${scopeSelector} .payment-source-meta,
${scopeSelector} .payment-source-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
}

${scopeSelector} .payment-source-meta {
    padding: 0.85rem 0.9rem;
    border-radius: 0.95rem;
    border: 1px solid var(--store-border);
    background: rgb(255 255 255 / 0.44);
}

${scopeSelector} .payment-source-detail {
    margin: 0.2rem 0 0;
    font-size: 0.82rem;
    line-height: 1.4;
    color: var(--store-text-muted);
}

${scopeSelector} .payment-source-label {
    font-weight: 700;
    color: var(--store-text-main);
}

${scopeSelector} .payment-source-balance {
    font-weight: 700;
    color: var(--store-success);
}

${scopeSelector} .payment-source-state {
    font-size: 0.7rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--store-text-subtle);
}

${scopeSelector} .summary-row.total {
    font-size: 1rem;
    font-weight: 700;
}

${scopeSelector} .summary-label,
${scopeSelector} .cart-line-meta {
    color: var(--store-text-muted);
}

${scopeSelector} .summary-value {
    font-weight: 700;
}

${scopeSelector} .summary-actions {
    display: grid;
    gap: 0.65rem;
}

${scopeSelector} .cart-empty {
    padding: 1rem;
    border-radius: 0.95rem;
    border: 1px dashed var(--store-border);
    color: var(--store-text-muted);
    background: rgb(255 255 255 / 0.38);
}

@media (max-width: 1120px) {
    ${scopeSelector} .store-cart {
        top: 0;
        right: 0;
        bottom: 0;
        width: min(24rem, 100%);
    }
}
`;

    StorefrontApp.componentFns = StorefrontApp.componentFns || {};

    StorefrontApp.componentFns.Cart = function Cart() {
        const state = getters.getStoreState(store);
        const summary = getters.summarizeCart(state.cartItems);
        const paymentSources = getters.getPaymentSources(storeConfig);
        const selectedPaymentSource =
            getters.getPaymentSourceById(
                storeConfig,
                state.selectedPaymentSource,
            ) ||
            paymentSources[0] ||
            null;
        const availablePaymentSourceCount = paymentSources.filter(
            (source) => source.enabled !== false,
        ).length;
        const selectedPaymentLabel = selectedPaymentSource
            ? selectedPaymentSource.label
            : "Unavailable";
        const selectedPaymentBalance = selectedPaymentSource
            ? Number(selectedPaymentSource.balance || 0)
            : 0;
        const remainingSourceBalance = Math.max(
            0,
            selectedPaymentBalance - summary.total,
        );

        ensureScopedStyle("storefront-cart", cartCss);

        return h(
            "div",
            {
                className: state.cartOpen ? "is-open" : "",
                [scopeAttr]: "",
                "aria-hidden": state.cartOpen ? "false" : "true",
            },
            h(
                "aside",
                { className: "store-cart" },
                h(
                    "section",
                    { className: "cart-card" },
                    h(
                        "div",
                        { className: "cart-header" },
                        h(
                            "div",
                            null,
                            h("span", { className: "eyebrow" }, "Cart"),
                            h(
                                "h2",
                                { className: "section-title" },
                                "Acquisition Queue",
                            ),
                        ),
                        h(
                            "button",
                            {
                                type: "button",
                                className: "cart-close",
                                "aria-label": "Close cart",
                                title: "Close cart",
                                onClick: () => actions.closeCart(),
                            },
                            "X",
                        ),
                    ),
                    h(
                        "div",
                        { className: "cart-kpi" },
                        h(
                            "div",
                            { className: "cart-kpi-card" },
                            h("span", { className: "kpi-label" }, "Items"),
                            h(
                                "span",
                                { className: "kpi-value" },
                                summary.lineCount,
                            ),
                        ),
                        h(
                            "div",
                            { className: "cart-kpi-card" },
                            h("span", { className: "kpi-label" }, "Payment"),
                            h(
                                "span",
                                { className: "kpi-value" },
                                selectedPaymentLabel,
                            ),
                        ),
                    ),
                    h(
                        "div",
                        { className: "cart-status" },
                        h("span", { className: "eyebrow" }, "Payment Source"),
                        h(
                            "div",
                            { className: "payment-source-field" },
                            h(
                                "select",
                                {
                                    className: "payment-source-select",
                                    value: state.selectedPaymentSource,
                                    onChange: (event) =>
                                        actions.selectPaymentSource(
                                            event.target.value,
                                        ),
                                },
                                paymentSources.map((source) =>
                                    h(
                                        "option",
                                        {
                                            value: source.id,
                                            disabled: source.enabled === false,
                                        },
                                        source.enabled === false
                                            ? `${source.label} (Locked)`
                                            : source.label,
                                    ),
                                ),
                            ),
                            selectedPaymentSource
                                ? h(
                                      "div",
                                      {
                                          className: "payment-source-meta",
                                      },
                                      h(
                                          "div",
                                          null,
                                          h(
                                              "div",
                                              {
                                                  className:
                                                      "payment-source-row",
                                              },
                                              h(
                                                  "span",
                                                  {
                                                      className:
                                                          "payment-source-label",
                                                  },
                                                  selectedPaymentSource.label,
                                              ),
                                              h(
                                                  "span",
                                                  {
                                                      className:
                                                          "payment-source-balance",
                                                  },
                                                  getters.formatCurrency(
                                                      selectedPaymentSource.balance,
                                                  ),
                                              ),
                                          ),
                                          h(
                                              "p",
                                              {
                                                  className:
                                                      "payment-source-detail",
                                              },
                                              selectedPaymentSource.detail,
                                          ),
                                      ),
                                      h(
                                          "span",
                                          {
                                              className: "payment-source-state",
                                          },
                                          availablePaymentSourceCount > 0
                                              ? selectedPaymentSource.enabled ===
                                                false
                                                  ? "Locked"
                                                  : "Available"
                                              : "Unavailable",
                                      ),
                                  )
                                : null,
                        ),
                    ),
                    h(
                        "div",
                        {
                            className: "cart-lines",
                            "data-preserve-scroll-id": "cart-lines",
                        },
                        summary.lineCount > 0
                            ? state.cartItems.map((item) =>
                                  h(
                                      "div",
                                      { className: "cart-line" },
                                      h(
                                          "div",
                                          { className: "cart-line-top" },
                                          h(
                                              "div",
                                              {
                                                  className: "cart-line-copy",
                                              },
                                              h(
                                                  "div",
                                                  {
                                                      className:
                                                          "cart-line-title",
                                                  },
                                                  item.name,
                                              ),
                                          ),
                                          h(
                                              "strong",
                                              null,
                                              getters.formatCurrency(
                                                  getters.parsePrice(
                                                      item.price,
                                                  ) * item.quantity,
                                              ),
                                          ),
                                      ),
                                      h(
                                          "div",
                                          { className: "cart-line-controls" },
                                          h(
                                              "div",
                                              { className: "qty-controls" },
                                              h(
                                                  "button",
                                                  {
                                                      type: "button",
                                                      className:
                                                          "store-btn store-btn-secondary qty-btn",
                                                      onClick: () =>
                                                          actions.decrementCartItem(
                                                              item.code,
                                                          ),
                                                  },
                                                  "-",
                                              ),
                                              h(
                                                  "span",
                                                  { className: "qty-badge" },
                                                  item.quantity,
                                              ),
                                              h(
                                                  "button",
                                                  {
                                                      type: "button",
                                                      className:
                                                          "store-btn store-btn-secondary qty-btn",
                                                      onClick: () =>
                                                          actions.incrementCartItem(
                                                              item.code,
                                                          ),
                                                  },
                                                  "+",
                                              ),
                                          ),
                                          h(
                                              "button",
                                              {
                                                  type: "button",
                                                  className:
                                                      "store-btn store-btn-secondary remove-btn",
                                                  onClick: () =>
                                                      actions.removeCartItem(
                                                          item.code,
                                                      ),
                                              },
                                              "Remove",
                                          ),
                                      ),
                                  ),
                              )
                            : h(
                                  "div",
                                  { className: "cart-empty" },
                                  "No items are queued yet. Add products from the catalog to build a checkout payload.",
                              ),
                    ),
                    h(
                        "div",
                        { className: "cart-summary" },
                        h(
                            "div",
                            { className: "summary-row" },
                            h("span", { className: "summary-label" }, "Items"),
                            h(
                                "span",
                                { className: "summary-value" },
                                summary.itemCount,
                            ),
                        ),
                        h(
                            "div",
                            { className: "summary-row" },
                            h(
                                "span",
                                { className: "summary-label" },
                                "Subtotal",
                            ),
                            h(
                                "span",
                                { className: "summary-value" },
                                getters.formatCurrency(summary.subtotal),
                            ),
                        ),
                        h(
                            "div",
                            { className: "summary-row" },
                            h(
                                "span",
                                { className: "summary-label" },
                                "Remaining Source",
                            ),
                            h(
                                "span",
                                { className: "summary-value" },
                                getters.formatCurrency(remainingSourceBalance),
                            ),
                        ),
                        h(
                            "div",
                            { className: "summary-row total" },
                            h("span", { className: "summary-label" }, "Total"),
                            h(
                                "span",
                                { className: "summary-value" },
                                getters.formatCurrency(summary.total),
                            ),
                        ),
                    ),
                    h(
                        "div",
                        { className: "summary-actions" },
                        h(
                            "button",
                            {
                                type: "button",
                                className: "store-btn store-btn-primary",
                                disabled:
                                    summary.lineCount === 0 ||
                                    state.isCheckingOut,
                                onClick: () => actions.requestCheckout(),
                            },
                            state.isCheckingOut
                                ? "Submitting Request..."
                                : "Submit Checkout",
                        ),
                    ),
                ),
            ),
        );
    };
})();

(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const { h, ensureScopedStyle } = StorefrontApp.runtime;
    const getters = StorefrontApp.getters;
    const store = StorefrontApp.store;
    const actions = StorefrontApp.actions;
    const scopeAttr = "data-ui-store-navbar";
    const scopeSelector = `[${scopeAttr}]`;
    const navbarCss = `
${scopeSelector} {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.9rem 1rem;
    margin-bottom: 0.95rem;
    border-bottom: 1px solid var(--store-accent-line);
    background:
        linear-gradient(180deg, rgb(255 255 255 / 0.52) 0%, transparent 100%),
        linear-gradient(180deg, rgb(236 241 246 / 0.52) 0%, rgb(245 243 239 / 0.2) 100%);
}

${scopeSelector} .store-breadcrumbs {
    display: flex;
    align-items: center;
    gap: 0.55rem;
    min-width: 0;
    flex-wrap: wrap;
}

${scopeSelector} .breadcrumb-link,
${scopeSelector} .breadcrumb-current,
${scopeSelector} .breadcrumb-separator {
    font-size: 0.78rem;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    font-weight: 700;
}

${scopeSelector} .breadcrumb-link {
    padding: 0;
    border: 0;
    background: transparent;
    color: var(--store-text-subtle);
}

${scopeSelector} .breadcrumb-link:hover {
    color: var(--store-accent);
}

${scopeSelector} .breadcrumb-current {
    color: var(--store-accent);
}

${scopeSelector} .breadcrumb-separator {
    color: rgb(124 138 155 / 0.72);
}

${scopeSelector} .store-cart-btn {
    position: relative;
    width: 2.6rem;
    height: 2.6rem;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex: 0 0 auto;
    border-radius: 0.7rem;
    border: 1px solid var(--store-border-strong);
    background: rgb(255 255 255 / 0.68);
    color: var(--store-accent);
    box-shadow: inset 0 1px 0 rgb(255 255 255 / 0.75);
}

${scopeSelector} .store-cart-btn:hover {
    background: rgb(219 231 243 / 0.88);
}

${scopeSelector} .cart-toggle-icon {
    position: relative;
    width: 0.95rem;
    height: 0.8rem;
    border: 1.5px solid currentColor;
    border-radius: 0.16rem 0.16rem 0.24rem 0.24rem;
}

${scopeSelector} .cart-toggle-icon::before {
    content: "";
    position: absolute;
    top: -0.34rem;
    left: 0.2rem;
    width: 0.5rem;
    height: 0.3rem;
    border: 1.5px solid currentColor;
    border-bottom: 0;
    border-radius: 0.35rem 0.35rem 0 0;
}

${scopeSelector} .cart-count {
    position: absolute;
    top: -0.35rem;
    right: -0.35rem;
    min-width: 1.25rem;
    height: 1.25rem;
    padding: 0 0.3rem;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    border-radius: 999px;
    background: var(--store-accent);
    color: #fff;
    font-size: 0.68rem;
    font-weight: 700;
}

@media (max-width: 1120px) {
    ${scopeSelector} {
        align-items: flex-start;
    }
}
`;

    StorefrontApp.componentFns = StorefrontApp.componentFns || {};

    StorefrontApp.componentFns.Navbar = function Navbar() {
        const state = getters.getStoreState(store);
        const items = getters.getStoreBreadcrumbs(state);
        const cartSummary = getters.summarizeCart(state.cartItems);

        ensureScopedStyle("storefront-navbar", navbarCss);

        return h(
            "nav",
            { [scopeAttr]: "" },
            h(
                "div",
                {
                    className: "store-breadcrumbs",
                    "aria-label": "Store navigation",
                },
                items.map((item, index) => {
                    const isCurrent = index === items.length - 1;

                    if (isCurrent) {
                        return h(
                            "span",
                            { className: "breadcrumb-current" },
                            item.label,
                        );
                    }

                    return [
                        h(
                            "button",
                            {
                                type: "button",
                                className: "breadcrumb-link",
                                onClick: () =>
                                    actions.navigateToBreadcrumb(item.id),
                            },
                            item.label,
                        ),
                        h("span", { className: "breadcrumb-separator" }, "/"),
                    ];
                }),
            ),
            h(
                "button",
                {
                    type: "button",
                    className: "store-cart-btn",
                    onClick: () => actions.toggleCart(),
                    title: state.cartOpen ? "Close cart" : "Open cart",
                    "aria-label": state.cartOpen ? "Close cart" : "Open cart",
                },
                h("span", {
                    className: "cart-toggle-icon",
                    "aria-hidden": "true",
                }),
                cartSummary.itemCount > 0
                    ? h(
                          "span",
                          { className: "cart-count" },
                          cartSummary.itemCount,
                      )
                    : null,
            ),
        );
    };
})();

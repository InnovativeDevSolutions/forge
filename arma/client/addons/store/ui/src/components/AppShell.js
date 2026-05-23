(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const { h, ensureScopedStyle } = StorefrontApp.runtime;
    const WindowTitleBar = window.SharedUI.componentFns.WindowTitleBar;
    const store = StorefrontApp.store;
    const getters = StorefrontApp.getters;
    const actions = StorefrontApp.actions;
    const { catalog, session, storeConfig } = StorefrontApp.data;
    const scopeAttr = "data-ui-store-app-shell";
    const scopeSelector = `[${scopeAttr}]`;
    const appShellCss = `
${scopeSelector} {
    display: flex;
    flex-direction: column;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background: var(--store-shell-bg);
}

${scopeSelector} .footer-title,
${scopeSelector} .eyebrow {
    font-size: 0.68rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--store-text-subtle);
    font-weight: 700;
}

${scopeSelector} .module-header,
${scopeSelector} .store-panel-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
}

${scopeSelector} .store-app {
    flex: 1;
    min-height: 0;
    width: min(100%, 1613px);
    margin: 0 auto;
    display: grid;
    grid-template-columns: 308px minmax(0, 1fr);
    gap: 1.25rem;
    padding: 1.25rem;
}

${scopeSelector} .store-sidebar,
${scopeSelector} .store-main {
    min-height: 0;
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

${scopeSelector} .store-main {
    position: relative;
    overflow: hidden;
}

${scopeSelector} .module-card,
${scopeSelector} .store-panel {
    background: linear-gradient(180deg, var(--store-surface) 0%, var(--store-surface-alt) 100%);
    border: 1px solid var(--store-border);
    border-radius: 1.35rem;
}

${scopeSelector} .module-card {
    padding: 1rem;
}

${scopeSelector} .store-panel {
    min-height: 0;
    flex: 1 1 auto;
    display: flex;
    flex-direction: column;
    width: min(100%, 1280px);
    overflow: hidden;
}

${scopeSelector} .module-header {
    margin-bottom: 0.85rem;
}

${scopeSelector} .store-panel-header {
    padding: 1rem 1rem 0;
}

${scopeSelector} .section-title {
    margin: 0;
    font-size: 1.1rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: var(--store-text-main);
}

${scopeSelector} .section-copy,
${scopeSelector} .footer-copy {
    margin: 0.2rem 0 0;
    font-size: 0.9rem;
    line-height: 1.45;
    color: var(--store-text-muted);
}

${scopeSelector} .pill {
    padding: 0.48rem 0.8rem;
    border-radius: 999px;
    background: var(--store-accent-soft);
    color: var(--store-accent);
    font-size: 0.74rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
}

${scopeSelector} .search-module {
    display: flex;
    flex-direction: column;
    gap: 0.8rem;
}

${scopeSelector} .search-form {
    display: grid;
    gap: 0.7rem;
}

${scopeSelector} .search-input {
    width: 100%;
    height: 2.9rem;
    padding: 0 0.95rem;
    border-radius: 0.8rem;
    border: 1px solid var(--store-border);
    background: rgb(255 255 255 / 0.75);
    color: var(--store-text-main);
}

${scopeSelector} .quick-tags {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
}

${scopeSelector} .quick-tag {
    padding: 0.55rem 0.72rem;
    border-radius: 999px;
    border: 1px solid var(--store-border);
    background: rgb(255 255 255 / 0.52);
    color: var(--store-text-muted);
    font-size: 0.75rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

${scopeSelector} .filter-stack {
    display: grid;
    gap: 0.85rem;
}

${scopeSelector} .filter-group {
    padding: 0.95rem;
    border-radius: 0.8rem;
    background: rgb(255 255 255 / 0.48);
    border: 1px solid var(--store-border);
}

${scopeSelector} .filter-label {
    display: block;
    margin-bottom: 0.55rem;
    font-size: 0.72rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--store-text-subtle);
    font-weight: 700;
}

${scopeSelector} .filter-value {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    color: var(--store-text-main);
    font-size: 0.92rem;
    font-weight: 600;
}

${scopeSelector} .filter-placeholder {
    color: var(--store-text-muted);
    font-weight: 500;
}

${scopeSelector} .store-panel-intro {
    padding: 0 1rem 1rem;
    border-bottom: 1px solid var(--store-accent-line);
}

${scopeSelector} .store-footer-bar {
    width: 100%;
    border-top: 1px solid rgb(18 54 93 / 0.1);
    background: transparent;
}

${scopeSelector} .store-footer {
    width: min(100%, 1613px);
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 1rem;
    padding: 0.95rem 1.25rem 1.15rem;
}

${scopeSelector} .footer-block {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
}

${scopeSelector} .store-toast-stack {
    position: fixed;
    top: 1.2rem;
    right: 1.5rem;
    z-index: 10;
    display: flex;
    flex-direction: column;
    gap: 0.65rem;
}

${scopeSelector} .store-toast {
    max-width: 24rem;
    padding: 0.85rem 1rem;
    border-radius: 0.9rem;
    border: 1px solid var(--store-border);
    background: #fff;
    box-shadow: 0 14px 28px rgb(16 34 56 / 0.14);
    font-size: 0.92rem;
}

${scopeSelector} .store-toast.is-success {
    background: #ecfdf5;
    border-color: #bbf7d0;
    color: #166534;
}

${scopeSelector} .store-toast.is-error {
    background: #fef2f2;
    border-color: #fecaca;
    color: #991b1b;
}

@media (max-width: 1440px) {
    ${scopeSelector} .store-app {
        grid-template-columns: 284px minmax(0, 1fr);
    }
}

@media (max-width: 1120px) {
    ${scopeSelector} .store-app {
        grid-template-columns: 1fr;
        overflow: auto;
    }

    ${scopeSelector} .store-sidebar,
    ${scopeSelector} .store-main {
        min-height: auto;
    }

    ${scopeSelector} .store-main {
        overflow: visible;
    }

    ${scopeSelector} .store-footer {
        grid-template-columns: 1fr;
    }

    ${scopeSelector} .store-toast-stack {
        right: 1rem;
        left: 1rem;
    }
}
`;

    StorefrontApp.components = StorefrontApp.components || {};
    StorefrontApp.componentFns = StorefrontApp.componentFns || {};

    function renderStoreBody(state) {
        const {
            CategoryCard,
            SubcategoryCard,
            ProductCard,
            EmptyStateCard,
            CategoryGrid,
            SubcategoryGrid,
            ProductGrid,
            CatalogPager,
        } = StorefrontApp.componentFns;

        if (state.view === "weapons" || state.view === "vehicles") {
            const slotType = state.view === "vehicles" ? "vehicle" : "weapon";
            const items = getters.getVisibleSubcategoryCards(state, catalog);

            return SubcategoryGrid(
                items.length > 0
                    ? items.map((category) =>
                          SubcategoryCard(category, slotType),
                      )
                    : EmptyStateCard({
                          title: "No matching slots",
                          copy: "Try a different search query or clear the current filter.",
                          actionLabel: "Clear Search",
                          onAction: () => actions.clearSearch(),
                      }),
            );
        }

        if (state.view === "items") {
            const items = getters.getVisibleItems(state, catalog);
            const pagedItems = getters.getVisibleItemsPage(state, catalog);
            const pagination = getters.getCatalogPagination(state, catalog);
            const quantityByCode = state.cartItems.reduce((acc, item) => {
                acc[item.code] = item.quantity;
                return acc;
            }, {});
            const selectionKey = String(
                getters.getSelectionKey(state) || "",
            ).toLowerCase();

            return [
                ProductGrid(
                    state.isCatalogLoading &&
                        state.catalogRequestKey === selectionKey &&
                        items.length === 0
                        ? EmptyStateCard({
                              title: "Loading inventory",
                              copy: "Pulling live category items from the game engine.",
                          })
                        : items.length > 0
                          ? pagedItems.map((item) =>
                                ProductCard(
                                    item,
                                    quantityByCode[item.code] || 0,
                                ),
                            )
                          : EmptyStateCard({
                                title: "No category items",
                                copy: state.searchQuery
                                    ? "Your search filter excluded the live inventory returned for this category."
                                    : "The game engine did not return any items for this category yet.",
                                actionLabel: "Clear Search",
                                onAction: () => actions.clearSearch(),
                            }),
                ),
                items.length > 0 ? CatalogPager(pagination) : null,
            ];
        }

        const items = getters.getVisibleCategoryCards(state, catalog);
        return CategoryGrid(
            items.length > 0
                ? items.map((category) => CategoryCard(category))
                : EmptyStateCard({
                      title: "No matching departments",
                      copy: "Your search filter excluded every top-level department.",
                      actionLabel: "Clear Search",
                      onAction: () => actions.clearSearch(),
                  }),
        );
    }

    StorefrontApp.components.App = function App() {
        const Navbar = StorefrontApp.componentFns.Navbar;
        const Cart = StorefrontApp.componentFns.Cart;
        const state = getters.getStoreState(store);
        const header = getters.getStoreHeader(state);
        const notice = store.getNotice();
        const activeQuery = state.searchQuery;
        const paymentSources = getters.getPaymentSources(storeConfig);
        const availablePaymentSourceCount = paymentSources.filter(
            (source) => source.enabled !== false,
        ).length;
        const filterDepartment =
            state.view === "items"
                ? actions.formatTitle(
                      getters.getSelectionKey(state) || "Catalog",
                  )
                : actions.formatTitle(state.view);
        const selectedPaymentSource =
            getters.getPaymentSourceById(
                storeConfig,
                state.selectedPaymentSource,
            ) || null;

        ensureScopedStyle("storefront-app-shell", appShellCss);

        return h(
            "div",
            { [scopeAttr]: "" },
            WindowTitleBar({
                kicker: "FORGE Logistics",
                title: "Supply Exchange",
                onClose: () => actions.closeStore(),
                closeLabel: "Close store interface",
            }),
            notice.text
                ? h(
                      "div",
                      { className: "store-toast-stack" },
                      h(
                          "div",
                          {
                              className:
                                  notice.type === "error"
                                      ? "store-toast is-error"
                                      : "store-toast is-success",
                          },
                          notice.text,
                      ),
                  )
                : null,
            h(
                "div",
                { className: "store-app" },
                h(
                    "aside",
                    { className: "store-sidebar" },
                    h(
                        "section",
                        { className: "module-card search-module" },
                        h(
                            "div",
                            { className: "module-header" },
                            h(
                                "div",
                                null,
                                h("span", { className: "eyebrow" }, "Search"),
                                h(
                                    "h2",
                                    { className: "section-title" },
                                    "Inventory Search",
                                ),
                            ),
                            h("span", { className: "pill" }, "Live"),
                        ),
                        h(
                            "div",
                            { className: "search-form" },
                            h("input", {
                                id: "store-search-input",
                                type: "text",
                                className: "search-input",
                                placeholder:
                                    "Search inventory, classes, or suppliers",
                                value: activeQuery,
                            }),
                            h(
                                "div",
                                {
                                    style: {
                                        display: "flex",
                                        gap: "0.65rem",
                                    },
                                },
                                h(
                                    "button",
                                    {
                                        type: "button",
                                        className:
                                            "store-btn store-btn-primary",
                                        onClick: () =>
                                            actions.applySearchQuery(
                                                document.getElementById(
                                                    "store-search-input",
                                                )?.value || "",
                                            ),
                                    },
                                    "Apply Search",
                                ),
                                h(
                                    "button",
                                    {
                                        type: "button",
                                        className:
                                            "store-btn store-btn-secondary",
                                        onClick: () => actions.clearSearch(),
                                    },
                                    "Clear",
                                ),
                            ),
                        ),
                        h(
                            "div",
                            { className: "quick-tags" },
                            (storeConfig.searchTags || []).map((tag) =>
                                h("span", { className: "quick-tag" }, tag),
                            ),
                        ),
                    ),
                    h(
                        "section",
                        { className: "module-card" },
                        h(
                            "div",
                            { className: "module-header" },
                            h(
                                "div",
                                null,
                                h("span", { className: "eyebrow" }, "Filter"),
                                h(
                                    "h2",
                                    { className: "section-title" },
                                    "Procurement Filters",
                                ),
                            ),
                            h(
                                "span",
                                { className: "pill" },
                                storeConfig.moduleState,
                            ),
                        ),
                        h(
                            "div",
                            { className: "filter-stack" },
                            h(
                                "div",
                                { className: "filter-group" },
                                h(
                                    "span",
                                    { className: "filter-label" },
                                    "Department",
                                ),
                                h(
                                    "div",
                                    { className: "filter-value" },
                                    h(
                                        "span",
                                        { className: "filter-placeholder" },
                                        filterDepartment,
                                    ),
                                ),
                            ),
                            h(
                                "div",
                                { className: "filter-group" },
                                h(
                                    "span",
                                    { className: "filter-label" },
                                    "Availability",
                                ),
                                h(
                                    "div",
                                    { className: "filter-value" },
                                    h(
                                        "span",
                                        { className: "filter-placeholder" },
                                        storeConfig.availability,
                                    ),
                                ),
                            ),
                            h(
                                "div",
                                { className: "filter-group" },
                                h(
                                    "span",
                                    { className: "filter-label" },
                                    "Payment",
                                ),
                                h(
                                    "div",
                                    { className: "filter-value" },
                                    h(
                                        "span",
                                        { className: "filter-placeholder" },
                                        selectedPaymentSource
                                            ? selectedPaymentSource.label
                                            : "Cash",
                                    ),
                                ),
                            ),
                        ),
                    ),
                ),
                h(
                    "main",
                    { className: "store-main" },
                    h(
                        "section",
                        { className: "store-panel" },
                        Navbar(),
                        h(
                            "div",
                            { className: "store-panel-header" },
                            h(
                                "div",
                                null,
                                h(
                                    "span",
                                    { className: "eyebrow" },
                                    header.eyebrow,
                                ),
                                h(
                                    "h1",
                                    { className: "section-title" },
                                    header.title,
                                ),
                            ),
                            h("span", { className: "pill" }, header.badge),
                        ),
                        h(
                            "div",
                            { className: "store-panel-intro" },
                            h("p", { className: "section-copy" }, header.copy),
                        ),
                        renderStoreBody(state),
                    ),
                    Cart(),
                ),
            ),
            h(
                "footer",
                { className: "store-footer-bar" },
                h(
                    "div",
                    { className: "store-footer" },
                    h(
                        "div",
                        { className: "footer-block" },
                        h(
                            "span",
                            { className: "footer-title" },
                            "Procurement Desk",
                        ),
                        h(
                            "span",
                            { className: "footer-copy" },
                            "Authorized supply browsing for personnel loadout preparation and mission staging.",
                        ),
                    ),
                    h(
                        "div",
                        { className: "footer-block" },
                        h(
                            "span",
                            { className: "footer-title" },
                            "Catalog Scope",
                        ),
                        h(
                            "span",
                            { className: "footer-copy" },
                            "Uniforms, protective gear, weapon slots, vehicles, ammunition groups, and general support inventory.",
                        ),
                    ),
                    h(
                        "div",
                        { className: "footer-block" },
                        h(
                            "span",
                            { className: "footer-title" },
                            "Purchase Access",
                        ),
                        h(
                            "span",
                            { className: "footer-copy" },
                            `${session.approval} approval. ${availablePaymentSourceCount} payment source(s) currently available${session.orgName ? ` for ${session.orgName}.` : "."}`,
                        ),
                    ),
                ),
            ),
        );
    };
})();

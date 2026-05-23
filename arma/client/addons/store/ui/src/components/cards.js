(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const { h, ensureScopedStyle } = StorefrontApp.runtime;
    const actions = StorefrontApp.actions;
    const media = StorefrontApp.media;
    const scopeAttr = "data-ui-store-cards";
    const scopeSelector = `[${scopeAttr}]`;
    const cardsCss = `
${scopeSelector}.catalog-grid-shell {
    flex: 1;
    min-height: 0;
    display: flex;
}

${scopeSelector}.catalog-pager-shell {
    display: block;
}

${scopeSelector} .catalog-grid {
    flex: 1;
    min-height: 0;
    width: 100%;
    padding: 1rem;
    display: grid;
    gap: 1rem;
    align-content: start;
    overflow-y: auto;
    overflow-x: hidden;
    scrollbar-gutter: stable;
    scrollbar-width: auto;
    scrollbar-color: rgb(120 136 155 / 0.9) rgb(255 255 255 / 0.45);
}

${scopeSelector} .catalog-grid::-webkit-scrollbar {
    width: 12px;
}

${scopeSelector} .catalog-grid::-webkit-scrollbar-track {
    background: rgb(255 255 255 / 0.45);
    border-radius: 999px;
}

${scopeSelector} .catalog-grid::-webkit-scrollbar-thumb {
    background: rgb(120 136 155 / 0.9);
    border-radius: 999px;
    border: 2px solid rgb(255 255 255 / 0.45);
}

${scopeSelector} .catalog-grid.is-categories,
${scopeSelector} .catalog-grid.is-products {
    grid-template-columns: repeat(3, minmax(0, 1fr));
}

${scopeSelector} .catalog-grid.is-subcategories {
    grid-template-columns: repeat(2, minmax(0, 1fr));
}

${scopeSelector} .card-button,
${scopeSelector} .product-card,
${scopeSelector} .empty-state {
    border: 1px solid var(--store-border);
    border-radius: 1.15rem;
    background:
        linear-gradient(180deg, rgb(255 255 255 / 0.72) 0%, rgb(226 233 239 / 0.9) 100%),
        var(--store-surface-strong);
    color: var(--store-accent);
    box-shadow:
        inset 0 1px 0 rgb(255 255 255 / 0.8),
        0 10px 24px rgb(16 34 56 / 0.06);
}

${scopeSelector} .card-button {
    min-height: 12.5rem;
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.75rem;
    padding: 1.35rem;
    text-align: left;
    transition:
        transform 120ms ease,
        box-shadow 120ms ease,
        border-color 120ms ease;
}

${scopeSelector} .card-button:hover,
${scopeSelector} .product-card:hover {
    transform: translateY(-2px);
    border-color: rgb(18 54 93 / 0.32);
    box-shadow:
        0 16px 28px rgb(16 34 56 / 0.11),
        inset 0 1px 0 rgb(255 255 255 / 0.88);
}

${scopeSelector} .card-kicker,
${scopeSelector} .product-code,
${scopeSelector} .empty-state-kicker {
    font-size: 0.72rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    font-weight: 700;
    color: var(--store-text-subtle);
}

${scopeSelector} .card-label {
    font-size: 1.08rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
}

${scopeSelector} .card-copy,
${scopeSelector} .product-copy,
${scopeSelector} .empty-state-copy {
    margin: 0;
    color: var(--store-text-muted);
    line-height: 1.45;
}

${scopeSelector} .product-copy {
    white-space: pre-line;
}

${scopeSelector} .product-card {
    min-height: 15.5rem;
    padding: 0.8rem;
    display: flex;
    flex-direction: column;
    gap: 0.65rem;
}

${scopeSelector} .product-image {
    height: 5.9rem;
    border-radius: 0.95rem;
    border: 1px dashed rgb(18 54 93 / 0.24);
    background: linear-gradient(135deg, rgb(235 240 245) 0%, rgb(221 228 235) 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--store-text-subtle);
    font-size: 0.78rem;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    overflow: hidden;
}

${scopeSelector} .product-image-asset {
    width: 100%;
    height: 100%;
    object-fit: contain;
}

${scopeSelector} .product-meta {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
}

${scopeSelector} .product-name {
    font-size: 0.96rem;
    font-weight: 700;
    color: var(--store-text-main);
    line-height: 1.3;
}

${scopeSelector} .product-footer {
    margin-top: auto;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
}

${scopeSelector} .product-price {
    font-size: 0.96rem;
    font-weight: 700;
    color: var(--store-success);
}

${scopeSelector} .product-qty {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 1.85rem;
    height: 1.85rem;
    border-radius: 999px;
    background: var(--store-accent-soft);
    color: var(--store-accent);
    font-size: 0.76rem;
    font-weight: 700;
}

${scopeSelector} .empty-state {
    padding: 1.35rem;
    display: flex;
    flex-direction: column;
    gap: 0.65rem;
}

${scopeSelector} .catalog-pager {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 0.9rem;
    padding: 0.55rem 0.9rem 0.75rem;
    border-top: 1px solid var(--store-accent-line);
}

${scopeSelector} .catalog-pager-meta {
    display: flex;
    flex-direction: column;
    gap: 0.15rem;
}

${scopeSelector} .catalog-pager-summary {
    font-size: 0.86rem;
    color: var(--store-text-muted);
}

${scopeSelector} .catalog-pager-actions {
    display: inline-flex;
    align-items: center;
    gap: 0.6rem;
}

${scopeSelector} .catalog-pager-page {
    min-width: 5.75rem;
    text-align: center;
    font-size: 0.82rem;
    font-weight: 700;
    color: var(--store-accent);
    letter-spacing: 0.08em;
    text-transform: uppercase;
}

${scopeSelector} .product-copy {
    display: -webkit-box;
    overflow: hidden;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
}

@media (max-width: 1440px) {
    ${scopeSelector} .catalog-grid.is-categories,
    ${scopeSelector} .catalog-grid.is-products {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@media (max-width: 1120px) {
    ${scopeSelector} .catalog-grid.is-categories,
    ${scopeSelector} .catalog-grid.is-subcategories,
    ${scopeSelector} .catalog-grid.is-products {
        grid-template-columns: 1fr;
    }
}
`;

    StorefrontApp.componentFns = StorefrontApp.componentFns || {};

    function createGrid(className, children) {
        ensureScopedStyle("storefront-cards", cardsCss);

        if (
            className === "is-products" &&
            media &&
            typeof media.scheduleTextureObservation === "function"
        ) {
            media.scheduleTextureObservation();
        }

        return h(
            "div",
            {
                [scopeAttr]: "",
                className: "catalog-grid-shell",
            },
            h(
                "div",
                {
                    className: `catalog-grid ${className}`,
                    "data-preserve-scroll-id": "catalog-grid",
                },
                children,
            ),
        );
    }

    function formatDescription(description, fallbackValue) {
        const rawDescription = String(description || "").trim();
        if (!rawDescription) {
            return fallbackValue;
        }

        const htmlDescription = rawDescription
            .replace(/<\s*br\s*\/?\s*>/gi, "\n")
            .replace(/<\/\s*p\s*>/gi, "\n")
            .replace(/<\s*li\s*>/gi, "- ")
            .replace(/<\/\s*li\s*>/gi, "\n");
        const scratch = document.createElement("div");
        scratch.innerHTML = htmlDescription;

        const textDescription = String(
            scratch.textContent || scratch.innerText || "",
        )
            .replace(/\u00a0/g, " ")
            .replace(/[ \t]+\n/g, "\n")
            .replace(/\n{3,}/g, "\n\n")
            .trim();

        return textDescription || fallbackValue;
    }

    StorefrontApp.componentFns.CategoryCard = function CategoryCard(category) {
        return h(
            "button",
            {
                type: "button",
                className: "card-button",
                onClick: () => actions.selectCategory(category.id),
            },
            h("span", { className: "card-kicker" }, "Department"),
            h("strong", { className: "card-label" }, category.label),
            h(
                "p",
                { className: "card-copy" },
                "Open this department and move into staged inventory browsing.",
            ),
        );
    };

    StorefrontApp.componentFns.SubcategoryCard = function SubcategoryCard(
        category,
        slotType,
    ) {
        return h(
            "button",
            {
                type: "button",
                className: "card-button",
                onClick: () => actions.selectSubcategory(category.id, slotType),
            },
            h(
                "span",
                { className: "card-kicker" },
                slotType === "vehicle" ? "Vehicle Class" : "Weapon Slot",
            ),
            h("strong", { className: "card-label" }, category.label),
            h(
                "p",
                { className: "card-copy" },
                "Open the next tier and review product previews for this selection.",
            ),
        );
    };

    StorefrontApp.componentFns.ProductCard = function ProductCard(
        item,
        quantityInCart,
    ) {
        const textureState =
            media && typeof media.getTextureState === "function"
                ? media.getTextureState(item.image)
                : { isVisible: true };
        const textureSource =
            media && typeof media.getTextureSource === "function"
                ? media.getTextureSource(item.image)
                : "";
        const description = formatDescription(
            item.description,
            item.className || item.code,
        );

        return h(
            "article",
            { className: "product-card" },
            h(
                "div",
                {
                    className: "product-image",
                    "data-store-texture-path": item.image || "",
                },
                textureSource
                    ? h("img", {
                          className: "product-image-asset",
                          src: textureSource,
                          alt: item.name,
                          loading: "lazy",
                      })
                    : textureState.isVisible
                      ? "Loading Image"
                      : "Image Placeholder",
            ),
            h(
                "div",
                { className: "product-meta" },
                h(
                    "span",
                    { className: "product-code" },
                    item.type || item.code || item.className,
                ),
                h("strong", { className: "product-name" }, item.name),
            ),
            h("p", { className: "product-copy" }, description),
            h(
                "div",
                { className: "product-footer" },
                h(
                    "span",
                    { className: "product-price" },
                    item.price || "Pending",
                ),
                h(
                    "div",
                    {
                        style: {
                            display: "flex",
                            alignItems: "center",
                            gap: "0.55rem",
                        },
                    },
                    quantityInCart > 0
                        ? h(
                              "span",
                              { className: "product-qty" },
                              quantityInCart,
                          )
                        : null,
                    h(
                        "button",
                        {
                            type: "button",
                            className: "store-btn store-btn-primary",
                            onClick: () => actions.addToCart(item),
                        },
                        "Add to Cart",
                    ),
                ),
            ),
        );
    };

    StorefrontApp.componentFns.EmptyStateCard = function EmptyStateCard({
        title,
        copy,
        actionLabel,
        onAction,
    }) {
        return h(
            "article",
            { className: "empty-state" },
            h("span", { className: "empty-state-kicker" }, "No Results"),
            h("strong", { className: "card-label" }, title),
            h("p", { className: "empty-state-copy" }, copy),
            actionLabel && typeof onAction === "function"
                ? h(
                      "button",
                      {
                          type: "button",
                          className: "store-btn store-btn-secondary",
                          onClick: onAction,
                      },
                      actionLabel,
                  )
                : null,
        );
    };

    StorefrontApp.componentFns.CategoryGrid = function CategoryGrid(children) {
        return createGrid("is-categories", children);
    };

    StorefrontApp.componentFns.SubcategoryGrid = function SubcategoryGrid(
        children,
    ) {
        return createGrid("is-subcategories", children);
    };

    StorefrontApp.componentFns.ProductGrid = function ProductGrid(children) {
        return createGrid("is-products", children);
    };

    StorefrontApp.componentFns.CatalogPager = function CatalogPager({
        currentPage,
        totalPages,
        startIndex,
        endIndex,
        totalItems,
    }) {
        ensureScopedStyle("storefront-cards", cardsCss);

        return h(
            "div",
            {
                [scopeAttr]: "",
                className: "catalog-pager-shell",
            },
            h(
                "div",
                { className: "catalog-pager" },
                h(
                    "div",
                    { className: "catalog-pager-meta" },
                    h("span", { className: "card-kicker" }, "Catalog Page"),
                    h(
                        "span",
                        { className: "catalog-pager-summary" },
                        totalItems > 0
                            ? `Showing ${startIndex}-${endIndex} of ${totalItems} items`
                            : "No items available",
                    ),
                ),
                h(
                    "div",
                    { className: "catalog-pager-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "store-btn store-btn-secondary",
                            disabled: currentPage <= 1,
                            onClick: () => actions.goToPreviousCatalogPage(),
                        },
                        "Previous",
                    ),
                    h(
                        "span",
                        { className: "catalog-pager-page" },
                        `Page ${currentPage} / ${totalPages}`,
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "store-btn store-btn-secondary",
                            disabled: currentPage >= totalPages,
                            onClick: () =>
                                actions.goToNextCatalogPage(totalPages),
                        },
                        "Next",
                    ),
                ),
            ),
        );
    };
})();

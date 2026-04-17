(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const actions = OrgPortal.actions;
    const scopeAttr = "data-ui-assets-card";
    const scopeSelector = `[${scopeAttr}]`;
    const assetsCardCss = `
${scopeSelector} .org-simple-list {
    display: flex;
    flex-direction: column;
    flex: 1;
    gap: 0.85rem;
    min-height: 0;
    overflow: auto;
    padding-right: 0.35rem;
    scrollbar-width: thin;
    scrollbar-color: #94a3b8 #e2e8f0;
}

${scopeSelector} .org-simple-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-simple-row:nth-child(even) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(241 245 249) 100%);
    border-color: rgb(148 163 184 / 0.45);
}

${scopeSelector} .org-simple-name {
    color: var(--primary-hover);
}

${scopeSelector} .org-simple-meta {
    display: flex;
    flex-wrap: wrap;
    justify-content: flex-end;
    gap: 1rem;
}

@media (max-width: 960px) {
    ${scopeSelector} .org-simple-row {
        flex-direction: column;
        align-items: flex-start;
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.AssetsCard = function AssetsCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        const SimpleStat = OrgPortal.componentFns.SimpleStat;
        ensureScopedStyle("portal-assets-card", assetsCardCss);

        return PanelCard({
            className: "org-scroll-panel org-span-7",
            title: "Assets",
            subtitle: "Inventory supplies and equipment with quantity totals.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-simple-list" },
                ...portalData.assets.map((asset) =>
                    h(
                        "article",
                        { className: "org-simple-row" },
                        h(
                            "strong",
                            { className: "org-simple-name" },
                            asset.name,
                        ),
                        h(
                            "div",
                            { className: "org-simple-meta" },
                            SimpleStat(
                                "Type",
                                actions.formatAssetType(asset.type),
                            ),
                            SimpleStat("Quantity", asset.quantity),
                        ),
                    ),
                ),
            ),
        });
    };
})();

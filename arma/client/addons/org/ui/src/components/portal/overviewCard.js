(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const store = OrgPortal.store;
    const getters = OrgPortal.getters;
    const scopeAttr = "data-ui-overview-card";
    const scopeSelector = `[${scopeAttr}]`;
    const overviewCardCss = `
${scopeSelector} .org-hero-grid {
    display: grid;
    grid-template-columns: 1.3fr 1fr;
    gap: 1.5rem;
    align-items: start;
}

${scopeSelector} .org-summary {
    margin: 0;
    font-size: 1.05rem;
    color: var(--text-main);
}

${scopeSelector} .org-meta-row {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 1rem;
    margin-top: 1.5rem;
}

${scopeSelector} .org-meta-item {
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-meta-item:nth-child(even) {
    background: linear-gradient(180deg, rgb(241 245 249) 0%, rgb(226 232 240) 100%);
    border-color: rgb(148 163 184 / 0.45);
}

${scopeSelector} .org-meta-label {
    font-size: 0.76rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
}

${scopeSelector} .org-meta-value {
    font-size: 1rem;
    font-weight: 600;
    color: var(--primary-hover);
}

${scopeSelector} .org-metric-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1rem;
}

@media (max-width: 960px) {
    ${scopeSelector} .org-hero-grid,
    ${scopeSelector} .org-meta-row,
    ${scopeSelector} .org-metric-grid {
        grid-template-columns: 1fr;
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.OverviewCard = function OverviewCard() {
        const MetricCard = OrgPortal.componentFns.MetricCard;
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        const readiness = getters.getAssetReadiness();
        const headquarters = portalData.org.headquarters || "ArmA Verse";
        const assetCount = store.getAssets().length;
        const fleetCount = store.getFleet().length;
        const funds = store.getFunds();
        const memberCount = store.getMembers().length;
        const reputation = store.getReputation();
        ensureScopedStyle("portal-overview-card", overviewCardCss);

        return PanelCard({
            className: "org-span-12",
            eyebrow: portalData.org.tag,
            title: "Organization Overview",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-hero-grid" },
                h(
                    "div",
                    { className: "org-hero-copy" },
                    h(
                        "p",
                        { className: "org-summary" },
                        portalData.org.type,
                        " operating from ",
                        headquarters,
                        ". Treasury, fleet status, inventory, and roster management are surfaced here first.",
                    ),
                    h(
                        "div",
                        { className: "org-meta-row" },
                        h(
                            "div",
                            { className: "org-meta-item" },
                            h(
                                "span",
                                { className: "org-meta-label" },
                                "Director",
                            ),
                            h(
                                "span",
                                { className: "org-meta-value" },
                                getters.formatDisplayName(portalData.org.owner),
                            ),
                        ),
                        h(
                            "div",
                            { className: "org-meta-item" },
                            h(
                                "span",
                                { className: "org-meta-label" },
                                "Active Members",
                            ),
                            h(
                                "span",
                                { className: "org-meta-value" },
                                `${memberCount} total`,
                            ),
                        ),
                        h(
                            "div",
                            { className: "org-meta-item" },
                            h(
                                "span",
                                { className: "org-meta-label" },
                                "Fleet Readiness",
                            ),
                            h(
                                "span",
                                { className: "org-meta-value" },
                                readiness === null ? "N/A" : `${readiness}%`,
                            ),
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "org-metric-grid" },
                    MetricCard(
                        "Org Funds",
                        getters.formatCurrency(funds),
                        "Organization treasury balance",
                    ),
                    MetricCard(
                        "Reputation",
                        reputation,
                        "Organization standing",
                    ),
                    MetricCard(
                        "Asset Lines",
                        assetCount,
                        "Tracked supply and equipment entries",
                    ),
                    MetricCard(
                        "Fleet Vehicles",
                        fleetCount,
                        "Tracked air, ground, and naval vehicles",
                    ),
                ),
            ),
        });
    };
})();

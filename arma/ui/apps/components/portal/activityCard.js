(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const scopeAttr = "data-ui-activity-card";
    const scopeSelector = `[${scopeAttr}]`;
    const activityCardCss = `
${scopeSelector} .org-activity-list {
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

${scopeSelector} .org-activity-row {
    padding: 1rem;
    border: 1px solid var(--border);
    border-left: 3px solid #94a3b8;
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-activity-row:nth-child(even) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(241 245 249) 100%);
    border-color: rgb(148 163 184 / 0.45);
    border-left-color: #64748b;
}

${scopeSelector} .org-activity-row p {
    margin: 0;
    color: var(--text-main);
}

${scopeSelector} .org-activity-time {
    display: inline-block;
    margin-bottom: 0.35rem;
    color: var(--text-muted);
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.ActivityCard = function ActivityCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        ensureScopedStyle("portal-activity-card", activityCardCss);

        return PanelCard({
            className: "org-scroll-panel org-span-6",
            title: "Command Feed",
            subtitle: "Recent organization-level actions and updates.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-activity-list" },
                ...portalData.activity.map((item) =>
                    h(
                        "article",
                        { className: "org-activity-row" },
                        h(
                            "span",
                            { className: "org-activity-time" },
                            item.time,
                        ),
                        h("p", null, item.text),
                    ),
                ),
            ),
        });
    };
})();

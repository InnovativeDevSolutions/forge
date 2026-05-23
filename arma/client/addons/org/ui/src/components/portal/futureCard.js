(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const scopeAttr = "data-ui-future-card";
    const ROADMAP = [
        {
            name: "Contracts Board",
            status: "Planned",
            detail: "Track payouts, assignments, and claim approvals.",
        },
        {
            name: "Diplomacy",
            status: "Future Review",
            detail: "Possible future module pending a full design and scope review.",
        },
        {
            name: "Logistics Queue",
            status: "Future Review",
            detail: "Possible future module pending a full design and scope review.",
        },
        {
            name: "Permissions",
            status: "Future Review",
            detail: "Possible future module pending a full design and scope review.",
        },
    ];
    const scopeSelector = `[${scopeAttr}]`;
    const futureCardCss = `
${scopeSelector} .org-roadmap-grid {
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1rem;
    flex: 1;
    min-height: 0;
    overflow: auto;
    padding-right: 0.35rem;
    scrollbar-width: thin;
    scrollbar-color: #94a3b8 #e2e8f0;
}

${scopeSelector} .org-roadmap-card {
    padding: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.7rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-roadmap-card:nth-child(4n + 2),
${scopeSelector} .org-roadmap-card:nth-child(4n + 3) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(241 245 249) 100%);
    border-color: rgb(100 116 139 / 0.4);
}

${scopeSelector} .org-roadmap-card p {
    margin: 0;
    color: var(--text-main);
}

${scopeSelector} .org-list-tag {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 0.2rem 0.55rem;
    border-radius: 999px;
    font-size: 0.72rem;
    font-weight: 700;
    letter-spacing: 0.06em;
    text-transform: uppercase;
    background: #e2e8f0;
    color: var(--primary-hover);
}

${scopeSelector} .org-roadmap-card:nth-child(4n + 2) .org-list-tag,
${scopeSelector} .org-roadmap-card:nth-child(4n + 3) .org-list-tag {
    background: #cbd5e1;
    color: #1e293b;
}

@media (max-width: 960px) {
    ${scopeSelector} .org-roadmap-grid {
        grid-template-columns: 1fr;
    }

    ${scopeSelector} .org-roadmap-card:nth-child(4n + 3) {
        background: #f8fafc;
        border-color: var(--border);
    }

    ${scopeSelector} .org-roadmap-card:nth-child(4n + 3) .org-list-tag {
        background: #e2e8f0;
        color: var(--primary-hover);
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.FutureCard = function FutureCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        ensureScopedStyle("portal-future-card", futureCardCss);

        return PanelCard({
            className: "org-scroll-panel org-span-6",
            title: "Expansion Slots",
            subtitle:
                "Potential modules are tagged by status such as Planned, In Design, In Review, and Future Review.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-roadmap-grid" },
                ...ROADMAP.map((item) =>
                    h(
                        "article",
                        { className: "org-roadmap-card" },
                        h("span", { className: "org-list-tag" }, item.status),
                        h("strong", null, item.name),
                        h("p", null, item.detail),
                    ),
                ),
            ),
        });
    };
})();

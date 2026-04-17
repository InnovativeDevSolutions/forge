(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const permissions = OrgPortal.permissions;
    const actions = OrgPortal.actions;
    const scopeAttr = "data-ui-danger-card";
    const scopeSelector = `[${scopeAttr}]`;
    const dangerCardCss = `
${scopeSelector} {
    border-color: #fecaca;
    background: linear-gradient(180deg, #ffffff 0%, #fff7f7 100%);
}

${scopeSelector} .org-danger-copy {
    margin-bottom: 1rem;
}

${scopeSelector} .org-danger-copy strong,
${scopeSelector} .org-danger-copy p {
    display: block;
}

${scopeSelector} .org-danger-copy p {
    margin: 0.4rem 0 0;
    color: var(--text-muted);
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.DangerCard = function DangerCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        ensureScopedStyle("portal-danger-card", dangerCardCss);

        if (!permissions.canDisbandOrg()) {
            return null;
        }

        return PanelCard({
            className: "org-span-12 org-danger-panel",
            title: "Organization Controls",
            subtitle:
                "Leader-only actions for membership and permanent organization removal.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                null,
                h(
                    "div",
                    { className: "org-danger-copy" },
                    h("strong", null, "Disband organization"),
                    h(
                        "p",
                        null,
                        "This removes the organization and revokes access to the portal for all members.",
                    ),
                ),
                h(
                    "button",
                    {
                        type: "button",
                        className: "org-danger-btn",
                        onClick: () => actions.openModal("disband"),
                    },
                    "Disband Organization",
                ),
            ),
        });
    };
})();

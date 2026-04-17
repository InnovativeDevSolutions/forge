(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const store = OrgPortal.store;
    const permissions = OrgPortal.permissions;
    const actions = OrgPortal.actions;
    const scopeAttr = "data-ui-members-card";
    const scopeSelector = `[${scopeAttr}]`;
    const membersCardCss = `
${scopeSelector} .org-name-list {
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

${scopeSelector} .org-name-row {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    gap: 1rem;
    padding: 1rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: #f8fafc;
}

${scopeSelector} .org-name-row:nth-child(even) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(241 245 249) 100%);
    border-color: rgb(148 163 184 / 0.45);
}

${scopeSelector} .org-name-row button {
    margin-left: auto;
}

@media (max-width: 960px) {
    ${scopeSelector} .org-name-row {
        flex-direction: column;
        align-items: flex-start;
    }

    ${scopeSelector} .org-name-row button {
        margin-left: 0;
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.MembersCard = function MembersCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        const members = store.getMembers();
        const allowMemberManagement = permissions.canManageMembers();
        ensureScopedStyle("portal-members-card", membersCardCss);

        return PanelCard({
            className: "org-scroll-panel org-span-5",
            title: "Members",
            subtitle:
                "Current roster listing. The organization owner cannot be removed.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-name-list" },
                ...members.map((member) => {
                    const canRemoveMember =
                        allowMemberManagement &&
                        !actions.isOwnerMember(member.name);

                    return h(
                        "article",
                        { className: "org-name-row" },
                        h("strong", null, member.name),
                        canRemoveMember
                            ? h(
                                  "button",
                                  {
                                      type: "button",
                                      className: "org-danger-btn org-icon-btn",
                                      title: `Remove ${member.name}`,
                                      "aria-label": `Remove ${member.name}`,
                                      onClick: () =>
                                          actions.removeMember(member.name),
                                  },
                                  h(
                                      "svg",
                                      {
                                          className: "org-icon",
                                          viewBox: "0 0 24 24",
                                          fill: "none",
                                          stroke: "currentColor",
                                          "stroke-width": "2",
                                          "stroke-linecap": "round",
                                          "stroke-linejoin": "round",
                                          "aria-hidden": "true",
                                      },
                                      h("path", { d: "M9 3h6" }),
                                      h("path", { d: "M4 7h16" }),
                                      h("path", { d: "M6 7l1 13h10l1-13" }),
                                      h("path", { d: "M10 11v6" }),
                                      h("path", { d: "M14 11v6" }),
                                  ),
                              )
                            : null,
                    );
                }),
            ),
        });
    };
})();

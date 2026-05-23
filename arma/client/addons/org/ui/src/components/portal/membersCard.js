(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const store = OrgPortal.store;
    const getters = OrgPortal.getters;
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

${scopeSelector} .org-members-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 1rem;
    position: relative;
}

${scopeSelector} .org-members-copy {
    display: flex;
    flex-direction: column;
    gap: 0.35rem;
}

${scopeSelector} .org-members-kicker {
    margin: 0;
    font-size: 0.85rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-muted);
}

${scopeSelector} .org-members-subtitle {
    margin: 0;
    font-size: 0.9rem;
    color: var(--text-muted);
}

${scopeSelector} .org-members-tools {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-left: auto;
}

${scopeSelector} .org-tool-btn {
    position: relative;
    width: 2.4rem;
    height: 2.4rem;
    padding: 0;
    display: inline-flex;
    align-items: center;
    justify-content: center;
}

${scopeSelector} .org-tool-badge {
    position: absolute;
    top: -0.25rem;
    right: -0.25rem;
    min-width: 1.1rem;
    height: 1.1rem;
    padding: 0 0.2rem;
    border-radius: 999px;
    background: #b91c1c;
    color: white;
    font-size: 0.68rem;
    font-weight: 700;
    display: inline-flex;
    align-items: center;
    justify-content: center;
}

${scopeSelector} .org-invite-menu {
    position: absolute;
    top: calc(100% + 0.5rem);
    right: 0;
    width: min(24rem, 100%);
    max-height: 22rem;
    overflow: auto;
    padding: 0.75rem;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    background: white;
    box-shadow: 0 18px 45px rgb(15 23 42 / 0.18);
    z-index: 4;
}

${scopeSelector} .org-invite-menu-head {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 0.75rem;
}

${scopeSelector} .org-invite-menu-title {
    margin: 0;
    font-size: 0.85rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
}

${scopeSelector} .org-invite-menu-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

${scopeSelector} .org-invite-row,
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

${scopeSelector} .org-name-copy {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
}

${scopeSelector} .org-name-meta {
    font-size: 0.8rem;
    color: var(--text-muted);
}

${scopeSelector} .org-inline-actions,
${scopeSelector} .org-invite-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-left: auto;
}

${scopeSelector} .org-members-empty {
    margin: 0;
    font-size: 0.9rem;
    color: var(--text-muted);
}

@media (max-width: 960px) {
    ${scopeSelector} .org-members-head {
        flex-direction: column;
        align-items: flex-start;
    }

    ${scopeSelector} .org-members-tools {
        margin-left: 0;
    }

    ${scopeSelector} .org-invite-menu {
        left: 0;
        right: auto;
        width: 100%;
    }

    ${scopeSelector} .org-name-row,
    ${scopeSelector} .org-invite-row {
        flex-direction: column;
        align-items: flex-start;
    }

    ${scopeSelector} .org-name-row button,
    ${scopeSelector} .org-inline-actions,
    ${scopeSelector} .org-invite-actions {
        margin-left: 0;
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.MembersCard = function MembersCard() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;
        const members = store.getMembers();
        const pendingInvites = store.getPendingInvites();
        const inviteMenuOpen = store.getInviteMenuOpen();
        const allowMemberManagement = getters.canManageMembers();
        ensureScopedStyle("portal-members-card", membersCardCss);

        return PanelCard({
            className: "org-scroll-panel org-span-5",
            title: "Members",
            subtitle:
                "Current roster listing. The organization owner and your own member entry cannot be removed.",
            rootProps: { [scopeAttr]: "" },
            body: h(
                "div",
                { className: "org-name-list" },
                h(
                    "div",
                    { className: "org-members-head" },
                    h(
                        "div",
                        { className: "org-members-copy" },
                        h("h4", { className: "org-members-kicker" }, "Roster"),
                        h(
                            "p",
                            { className: "org-members-subtitle" },
                            "Manage membership and review incoming organization invites.",
                        ),
                    ),
                    h(
                        "div",
                        { className: "org-members-tools" },
                        h(
                            "button",
                            {
                                type: "button",
                                className:
                                    "org-secondary-btn org-icon-btn org-tool-btn",
                                title: "Pending invitations",
                                "aria-label": "Pending invitations",
                                onClick: () => actions.toggleInviteMenu(),
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
                                h("path", {
                                    d: "M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2a2 2 0 0 1-.6 1.4L4 17h5",
                                }),
                                h("path", { d: "M9.73 21a2 2 0 0 0 4.54 0" }),
                            ),
                            pendingInvites.length > 0
                                ? h(
                                      "span",
                                      { className: "org-tool-badge" },
                                      String(pendingInvites.length),
                                  )
                                : null,
                        ),
                        allowMemberManagement
                            ? h(
                                  "button",
                                  {
                                      type: "button",
                                      className:
                                          "org-secondary-btn org-icon-btn org-tool-btn",
                                      title: "Invite player",
                                      "aria-label": "Invite player",
                                      onClick: () =>
                                          actions.openModal("invite"),
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
                                      h("path", { d: "M12 5v14" }),
                                      h("path", { d: "M5 12h14" }),
                                  ),
                              )
                            : null,
                        inviteMenuOpen
                            ? h(
                                  "div",
                                  { className: "org-invite-menu" },
                                  h(
                                      "div",
                                      { className: "org-invite-menu-head" },
                                      h(
                                          "h4",
                                          {
                                              className:
                                                  "org-invite-menu-title",
                                          },
                                          "Pending Invites",
                                      ),
                                      h(
                                          "button",
                                          {
                                              type: "button",
                                              className:
                                                  "org-secondary-btn org-icon-btn org-tool-btn",
                                              title: "Close invites",
                                              "aria-label": "Close invites",
                                              onClick: () =>
                                                  actions.closeInviteMenu(),
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
                                              h("path", { d: "M18 6 6 18" }),
                                              h("path", { d: "m6 6 12 12" }),
                                          ),
                                      ),
                                  ),
                                  pendingInvites.length === 0
                                      ? h(
                                            "p",
                                            {
                                                className: "org-members-empty",
                                            },
                                            "No incoming organization invites.",
                                        )
                                      : h(
                                            "div",
                                            {
                                                className:
                                                    "org-invite-menu-list",
                                            },
                                            ...pendingInvites.map((invite) =>
                                                h(
                                                    "article",
                                                    {
                                                        className:
                                                            "org-invite-row",
                                                    },
                                                    h(
                                                        "div",
                                                        {
                                                            className:
                                                                "org-name-copy",
                                                        },
                                                        h(
                                                            "strong",
                                                            null,
                                                            invite.orgName ||
                                                                "Unknown Organization",
                                                        ),
                                                        h(
                                                            "span",
                                                            {
                                                                className:
                                                                    "org-name-meta",
                                                            },
                                                            "Invited by ",
                                                            invite.inviterName ||
                                                                "Unknown",
                                                        ),
                                                    ),
                                                    h(
                                                        "div",
                                                        {
                                                            className:
                                                                "org-invite-actions",
                                                        },
                                                        h(
                                                            "button",
                                                            {
                                                                type: "button",
                                                                className:
                                                                    "org-secondary-btn",
                                                                onClick: () =>
                                                                    actions.declineInvite(
                                                                        String(
                                                                            invite.orgId ||
                                                                                "",
                                                                        ),
                                                                    ),
                                                            },
                                                            "Decline",
                                                        ),
                                                        h(
                                                            "button",
                                                            {
                                                                type: "button",
                                                                onClick: () =>
                                                                    actions.acceptInvite(
                                                                        String(
                                                                            invite.orgId ||
                                                                                "",
                                                                        ),
                                                                    ),
                                                            },
                                                            "Accept",
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ),
                              )
                            : null,
                    ),
                ),
                ...members.map((member) => {
                    const canRemoveMember =
                        allowMemberManagement &&
                        !getters.isProtectedMember(member);

                    return h(
                        "article",
                        { className: "org-name-row" },
                        h(
                            "div",
                            { className: "org-name-copy" },
                            h("strong", null, member.name),
                            member.uid
                                ? h(
                                      "span",
                                      { className: "org-name-meta" },
                                      member.uid,
                                  )
                                : null,
                        ),
                        canRemoveMember
                            ? h(
                                  "button",
                                  {
                                      type: "button",
                                      className: "org-danger-btn org-icon-btn",
                                      title: `Remove ${member.name}`,
                                      "aria-label": `Remove ${member.name}`,
                                      onClick: () =>
                                          actions.removeMember(member),
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

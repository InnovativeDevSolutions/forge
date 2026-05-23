(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const store = OrgPortal.store;
    const actions = OrgPortal.actions;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.ModalLayer = function ModalLayer() {
        const Modal = window.SharedUI.componentFns.Modal;
        const modal = store.getModal();
        if (!modal) {
            return null;
        }

        const members = store.getMembers();
        const inviteablePlayers = store.getInviteablePlayers();
        const memberSelectProps =
            members.length === 0 ? { disabled: true } : {};
        const inviteSelectProps =
            inviteablePlayers.length === 0 ? { disabled: true } : {};

        let title = "";
        let body = null;

        if (modal.type === "payroll") {
            title = "Run Payroll";
            body = h(
                "div",
                { className: "app-modal-form" },
                h(
                    "div",
                    null,
                    h("label", null, "Amount Per Member"),
                    h("input", {
                        id: "treasury-payroll-amount",
                        type: "number",
                        min: "1",
                        placeholder: "500",
                        autofocus: "true",
                    }),
                ),
                h(
                    "div",
                    { className: "app-modal-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            onClick: () => {
                                if (
                                    actions.runPayroll(
                                        actions.parseAmount(
                                            actions.getInputValue(
                                                "treasury-payroll-amount",
                                            ),
                                        ),
                                    )
                                ) {
                                    actions.closeModal();
                                }
                            },
                        },
                        "Run Payroll",
                    ),
                ),
            );
        } else if (modal.type === "transfer") {
            title = "Send Funds";
            body = h(
                "div",
                { className: "app-modal-form" },
                h(
                    "div",
                    null,
                    h("label", null, "Member"),
                    h(
                        "select",
                        {
                            id: "treasury-transfer-member",
                            ...memberSelectProps,
                        },
                        ...members.map((member) =>
                            h("option", { value: member.uid }, member.name),
                        ),
                    ),
                ),
                h(
                    "div",
                    null,
                    h("label", null, "Amount"),
                    h("input", {
                        id: "treasury-transfer-amount",
                        type: "number",
                        min: "1",
                        placeholder: "1500",
                    }),
                ),
                h(
                    "div",
                    { className: "app-modal-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            ...memberSelectProps,
                            onClick: () => {
                                if (
                                    actions.sendFundsToMember(
                                        String(
                                            actions.getInputValue(
                                                "treasury-transfer-member",
                                            ) || "",
                                        ),
                                        actions.parseAmount(
                                            actions.getInputValue(
                                                "treasury-transfer-amount",
                                            ),
                                        ),
                                    )
                                ) {
                                    actions.closeModal();
                                }
                            },
                        },
                        "Send Funds",
                    ),
                ),
            );
        } else if (modal.type === "credit") {
            title = "Assign Credit Line";
            body = h(
                "div",
                { className: "app-modal-form" },
                h(
                    "div",
                    null,
                    h("label", null, "Member"),
                    h(
                        "select",
                        { id: "treasury-credit-member", ...memberSelectProps },
                        ...members.map((member) =>
                            h("option", { value: member.uid }, member.name),
                        ),
                    ),
                ),
                h(
                    "div",
                    null,
                    h("label", null, "Credit Amount"),
                    h("input", {
                        id: "treasury-credit-amount",
                        type: "number",
                        min: "1",
                        placeholder: "5000",
                    }),
                ),
                h(
                    "div",
                    { className: "app-modal-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            ...memberSelectProps,
                            onClick: () => {
                                if (
                                    actions.grantCreditLine(
                                        String(
                                            actions.getInputValue(
                                                "treasury-credit-member",
                                            ) || "",
                                        ),
                                        actions.parseAmount(
                                            actions.getInputValue(
                                                "treasury-credit-amount",
                                            ),
                                        ),
                                    )
                                ) {
                                    actions.closeModal();
                                }
                            },
                        },
                        "Assign Credit Line",
                    ),
                ),
            );
        } else if (modal.type === "invite") {
            title = "Invite Player";
            body = h(
                "div",
                { className: "app-modal-form" },
                h(
                    "div",
                    null,
                    h("label", null, "Online Player"),
                    h(
                        "select",
                        {
                            id: "org-invite-player",
                            ...inviteSelectProps,
                        },
                        ...inviteablePlayers.map((player) =>
                            h(
                                "option",
                                { value: player.uid },
                                player.name || player.uid,
                            ),
                        ),
                    ),
                ),
                inviteablePlayers.length === 0
                    ? h(
                          "p",
                          null,
                          "No eligible online players are currently available for invites.",
                      )
                    : null,
                h(
                    "div",
                    { className: "app-modal-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            ...inviteSelectProps,
                            onClick: () => {
                                if (
                                    actions.sendInvite(
                                        String(
                                            actions.getInputValue(
                                                "org-invite-player",
                                            ) || "",
                                        ),
                                    )
                                ) {
                                    actions.closeModal();
                                }
                            },
                        },
                        "Send Invite",
                    ),
                ),
            );
        } else if (modal.type === "disband") {
            title = "Disband Organization";
            body = h(
                "div",
                { className: "app-modal-danger" },
                h(
                    "p",
                    null,
                    "This action is permanent. Disband ",
                    portalData.org.name,
                    "?",
                ),
                h(
                    "div",
                    { className: "app-modal-danger-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-danger-btn",
                            onClick: () => actions.disbandOrganization(),
                        },
                        "Confirm Disband",
                    ),
                ),
            );
        } else if (modal.type === "leave") {
            title = "Leave Organization";
            body = h(
                "div",
                { className: "app-modal-danger" },
                h(
                    "p",
                    null,
                    "Leave ",
                    portalData.org.name,
                    " and return to the default organization?",
                ),
                h(
                    "div",
                    { className: "app-modal-danger-actions" },
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-secondary-btn",
                            onClick: () => actions.closeModal(),
                        },
                        "Cancel",
                    ),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "org-danger-btn",
                            onClick: () => actions.leaveOrganization(),
                        },
                        "Confirm Leave",
                    ),
                ),
            );
        }

        return Modal({
            title,
            body,
            onClose: () => actions.closeModal(),
        });
    };
})();

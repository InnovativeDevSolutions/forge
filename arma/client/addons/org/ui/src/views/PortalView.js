(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const { portalData, session } = OrgPortal.data;
    const store = OrgPortal.store;
    const portalViewScope = "[data-ui-portal-view]";

    ensureScopedStyle(
        "portal-view",
        `
            ${portalViewScope} {
                --org-row-card-max-height: 36rem;
            }

            ${portalViewScope} .org-toast-stack {
                position: fixed;
                top: 1.5rem;
                right: 2rem;
                z-index: 20;
                display: flex;
                flex-direction: column;
                gap: 0.75rem;
                pointer-events: none;
            }

            ${portalViewScope} .org-toast {
                max-width: 24rem;
                padding: 0.9rem 1rem;
                border-radius: var(--radius);
                border: 1px solid var(--border);
                background: #fff;
                box-shadow: 0 12px 28px rgb(15 23 42 / 0.14);
                font-size: 0.92rem;
                pointer-events: auto;
            }

            ${portalViewScope} .org-toast.is-success {
                background: #ecfdf5;
                border-color: #bbf7d0;
                color: #166534;
            }

            ${portalViewScope} .org-toast.is-error {
                background: #fef2f2;
                border-color: #fecaca;
                color: #991b1b;
            }

            ${portalViewScope} .org-dashboard-grid {
                display: grid;
                grid-template-columns: repeat(12, minmax(0, 1fr));
                gap: 1.5rem;
                align-items: stretch;
            }

            ${portalViewScope} .org-panel {
                margin-bottom: 0;
                text-align: left;
            }

            ${portalViewScope} .org-scroll-panel {
                display: flex;
                flex-direction: column;
                min-height: 0;
                max-height: var(--org-row-card-max-height);
                overflow: hidden;
            }

            ${portalViewScope} .org-island-root {
                display: flex;
                align-self: stretch;
                min-height: 0;
                min-width: 0;
            }

            ${portalViewScope} .org-island-root > .org-panel {
                height: 100%;
                width: 100%;
            }

            ${portalViewScope} .org-span-12 {
                grid-column: span 12;
            }

            ${portalViewScope} .org-span-7 {
                grid-column: span 7;
            }

            ${portalViewScope} .org-span-6 {
                grid-column: span 6;
            }

            ${portalViewScope} .org-span-5 {
                grid-column: span 5;
            }

            @media (max-width: 960px) {
                ${portalViewScope} .org-toast-stack {
                    top: 1rem;
                    right: 1rem;
                    left: 1rem;
                }

                ${portalViewScope} .org-toast {
                    max-width: none;
                }

                ${portalViewScope} .org-span-12,
                ${portalViewScope} .org-span-7,
                ${portalViewScope} .org-span-6,
                ${portalViewScope} .org-span-5 {
                    grid-column: span 12;
                }

                ${portalViewScope} .org-scroll-panel {
                    max-height: none;
                }

            }
        `,
    );

    OrgPortal.components = OrgPortal.components || {};
    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.TreasuryNoticeLayer =
        function TreasuryNoticeLayer() {
            const treasuryNotice = store.getTreasuryNotice();
            if (!treasuryNotice.text) {
                return null;
            }

            return h(
                "div",
                { className: "org-toast-stack" },
                h(
                    "div",
                    {
                        className:
                            treasuryNotice.type === "error"
                                ? "org-toast is-error"
                                : "org-toast is-success",
                    },
                    treasuryNotice.text,
                ),
            );
        };

    OrgPortal.components.App = function App() {
        const Hero = window.SharedUI.componentFns.Hero;
        const Footer = window.SharedUI.componentFns.Footer;
        const FutureCard = OrgPortal.componentFns.FutureCard;
        const DangerCard = OrgPortal.componentFns.DangerCard;
        const DisbandedView = OrgPortal.componentFns.DisbandedView;
        const footerSections = [
            {
                title: "Organization Controls",
                items: [
                    "Roster Management",
                    "Fleet Assignment",
                    "Treasury Permissions",
                    "Asset Registry",
                ],
            },
            {
                title: "Planned Extensions",
                items: [
                    "Contracts Board",
                    "Diplomacy Layer",
                    "Procurement Queue",
                    "Reputation History",
                ],
            },
        ];
        if (store.getOrgDisbanded()) {
            return h(
                "main",
                { "data-ui-portal-view": "" },
                h(
                    "div",
                    { className: "container" },
                    h(
                        "div",
                        { className: "org-dashboard-grid" },
                        Hero({
                            kicker: portalData.org.tag,
                            title: portalData.org.name,
                            subtitle: "Player organization command portal",
                            meta: `${session.actorName} - ${session.role}`,
                        }),
                        DisbandedView(),
                    ),
                ),
                h("div", { id: "org-portal-modal-root" }),
                Footer({ sections: footerSections }),
            );
        }

        return h(
            "main",
            { "data-ui-portal-view": "" },
            h("div", { id: "org-portal-toast-root" }),
            h(
                "div",
                { className: "container" },
                h(
                    "div",
                    { className: "org-dashboard-grid" },
                    Hero({
                        kicker: portalData.org.tag,
                        title: portalData.org.name,
                        subtitle: "Player organization command portal",
                        meta: `${session.actorName} - ${session.role}`,
                    }),
                    h("div", {
                        className: "org-island-root org-span-12",
                        id: "org-overview-card-root",
                    }),
                    h("div", {
                        className: "org-island-root org-span-7",
                        id: "org-fleet-card-root",
                    }),
                    h("div", {
                        className: "org-island-root org-span-5",
                        id: "org-treasury-card-root",
                    }),
                    h("div", {
                        className: "org-island-root org-span-5",
                        id: "org-members-card-root",
                    }),
                    h("div", {
                        className: "org-island-root org-span-7",
                        id: "org-assets-card-root",
                    }),
                    h("div", {
                        className: "org-island-root org-span-6",
                        id: "org-activity-card-root",
                    }),
                    FutureCard(),
                    DangerCard(),
                ),
            ),
            h("div", { id: "org-portal-modal-root" }),
            Footer({ sections: footerSections }),
        );
    };
})();

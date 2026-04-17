(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h } = OrgPortal.runtime;
    const { portalData } = OrgPortal.data;
    const registryStore = window.RegistryApp.store;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.DisbandedView = function DisbandedView() {
        const PanelCard = window.SharedUI.componentFns.PanelCard;

        return PanelCard({
            className: "org-span-12 org-empty-state",
            eyebrow: "Organization Removed",
            title: portalData.org.name,
            body: h(
                "div",
                null,
                h(
                    "p",
                    { className: "org-summary" },
                    "This organization has been disbanded. Member access, assets, and fleet management are no longer available from this portal preview.",
                ),
                h(
                    "button",
                    {
                        type: "button",
                        className: "org-secondary-btn",
                        onClick: () => registryStore.setView("home"),
                    },
                    "Return to Registry",
                ),
            ),
        });
    };
})();

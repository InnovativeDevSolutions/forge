(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h } = RegistryApp.runtime;
    const store = RegistryApp.store;

    RegistryApp.components = RegistryApp.components || {};

    RegistryApp.components.App = function App() {
        const Navbar = window.SharedUI.componentFns.Navbar;
        const Header = window.SharedUI.componentFns.Header;
        const Footer = window.SharedUI.componentFns.Footer;
        const WindowTitleBar = window.SharedUI.componentFns.WindowTitleBar;
        const HomeView = RegistryApp.componentFns.HomeView;
        const RegistrationView = RegistryApp.componentFns.RegistrationView;
        const PortalApp =
            window.OrgPortal && window.OrgPortal.components
                ? window.OrgPortal.components.App
                : null;

        const view = store.getView();
        const portalGetters =
            window.OrgPortal && window.OrgPortal.getters
                ? window.OrgPortal.getters
                : null;
        const portalActions =
            window.OrgPortal && window.OrgPortal.actions
                ? window.OrgPortal.actions
                : null;
        const viewLabel =
            view === "create"
                ? "Organization Registration"
                : view === "portal"
                  ? "Organization Portal"
                  : "Entry Hub";
        const footerSections = [
            {
                title: "Registry Resources",
                items: [
                    "Registration Guidelines",
                    "Tax & Fee Schedule",
                    "Legal Compliance",
                    "Trademark Database",
                ],
            },
            {
                title: "Bureau Support",
                items: [
                    "Office: Sector 7 Admin Block",
                    "Hours: 0800 - 1600 (GST)",
                    "Helpdesk: 555-01-REGISTRY",
                    "support@org-bureau.gov",
                ],
            },
        ];

        function closeRegistry() {
            if (
                RegistryApp.bridge &&
                typeof RegistryApp.bridge.close === "function"
            ) {
                RegistryApp.bridge.close({});
                return;
            }

            store.setView("home");
        }

        if (view === "portal" && PortalApp) {
            const canLeaveOrg =
                portalGetters &&
                typeof portalGetters.canLeaveOrg === "function" &&
                portalGetters.canLeaveOrg();

            return h(
                "div",
                { className: "app-shell" },
                WindowTitleBar({
                    kicker: "FORGE ORBIS",
                    title: "Global Organization Network",
                    onClose: closeRegistry,
                    closeLabel: "Close organization interface",
                }),
                Navbar({
                    title: "Global Organization Network",
                    viewLabel,
                    actionLabel: canLeaveOrg ? "Leave Organization" : "",
                    onAction:
                        canLeaveOrg &&
                        portalActions &&
                        typeof portalActions.openModal === "function"
                            ? () => portalActions.openModal("leave")
                            : null,
                }),
                h("div", { id: "org-portal-frame-root" }),
            );
        }

        let mainContent;
        if (view === "home") {
            mainContent = HomeView();
        } else if (view === "create") {
            mainContent = RegistrationView();
        }

        return h(
            "div",
            { className: "app-shell" },
            WindowTitleBar({
                kicker: "FORGE ORBIS",
                title: "Global Organization Network",
                onClose: closeRegistry,
                closeLabel: "Close organization interface",
            }),
            h(
                "main",
                null,
                Navbar({
                    title: "Global Organization Network",
                    viewLabel,
                }),
                h(
                    "div",
                    { className: "container" },
                    Header({
                        title: "Global Organization Network",
                        onTitleClick: () => store.setView("home"),
                    }),
                    mainContent,
                ),
                Footer({ sections: footerSections }),
            ),
        );
    };
})();

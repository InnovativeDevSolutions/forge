(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h } = RegistryApp.runtime;
    const store = RegistryApp.store;

    RegistryApp.components = RegistryApp.components || {};

    RegistryApp.components.App = function App() {
        const Navbar = window.SharedUI.componentFns.Navbar;
        const Header = window.SharedUI.componentFns.Header;
        const Footer = window.SharedUI.componentFns.Footer;
        const HomeView = RegistryApp.componentFns.HomeView;
        const RegistrationView = RegistryApp.componentFns.RegistrationView;
        const PortalApp =
            window.OrgPortal && window.OrgPortal.components
                ? window.OrgPortal.components.App
                : null;

        const view = store.getView();
        const viewLabel =
            view === "create"
                ? "Organization Registration"
                : view === "portal"
                  ? "Organization Portal"
                  : "Entry Hub";
        const actionLabel = view === "portal" ? "Sign Out" : "Close";
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
                typeof A3API !== "undefined" &&
                typeof A3API.SendAlert === "function"
            ) {
                A3API.SendAlert(
                    JSON.stringify({
                        event: "org::close",
                        data: {},
                    }),
                );
                return;
            }

            store.setView("home");
        }

        if (view === "portal" && PortalApp) {
            return h(
                "div",
                null,
                Navbar({
                    title: "Global Organization Network",
                    viewLabel,
                    actionLabel,
                    onAction: closeRegistry,
                }),
                PortalApp(),
            );
        }

        let mainContent;
        if (view === "home") {
            mainContent = HomeView();
        } else if (view === "create") {
            mainContent = RegistrationView();
        }

        return h(
            "main",
            null,
            Navbar({
                title: "Global Organization Network",
                viewLabel,
                actionLabel,
                onAction: closeRegistry,
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
        );
    };
})();

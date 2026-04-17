(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h, ensureScopedStyle } = RegistryApp.runtime;
    const store = RegistryApp.store;
    const bridge = RegistryApp.bridge;
    const scopeAttr = "data-ui-home-view";
    const scopeSelector = `[${scopeAttr}]`;
    const homeViewCss = `
${scopeSelector} {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
    margin-bottom: 2rem;
}

${scopeSelector} .home-span-full {
    grid-column: span 2;
}

${scopeSelector} .home-feedback {
    padding: 0.85rem 1rem;
    border-radius: var(--radius);
    font-size: 0.92rem;
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #991b1b;
}

@media (max-width: 960px) {
    ${scopeSelector} {
        grid-template-columns: 1fr;
    }

    ${scopeSelector} .home-span-full {
        grid-column: span 1;
    }
}
`;

    RegistryApp.componentFns = RegistryApp.componentFns || {};

    RegistryApp.componentFns.HomeView = function HomeView() {
        const isAuthenticating = store.getIsAuthenticating();
        const loginError = store.getLoginError();
        ensureScopedStyle("main-home-view", homeViewCss);

        return h(
            "div",
            { className: "content", [scopeAttr]: "" },
            h(
                "div",
                { className: "card" },
                h("h2", null, "Create Organization"),
                h(
                    "p",
                    null,
                    "Establish your Task Force, PMC, or Milsim unit with the Global Organization Network. Receive your official unit designator and TO&E authorization instantly.",
                ),
                h(
                    "button",
                    { onClick: () => store.setView("create") },
                    "Register",
                ),
            ),
            h(
                "div",
                { className: "card" },
                h("h2", null, "Organization Portal"),
                h(
                    "p",
                    null,
                    "Access your unit dashboard to modify rosters, adjust active deployments, and submit after-action reports through the secure field uplink.",
                ),
                loginError
                    ? h("div", { className: "home-feedback" }, loginError)
                    : null,
                h(
                    "button",
                    {
                        disabled: isAuthenticating,
                        onClick: () => {
                            if (!bridge) {
                                store.failLogin(
                                    "Login bridge is not available.",
                                );
                                return;
                            }

                            bridge.requestLogin({});
                        },
                    },
                    isAuthenticating ? "Opening Portal..." : "Login",
                ),
            ),
        );
    };
})();

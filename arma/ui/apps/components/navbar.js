(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h, ensureScopedStyle } = RegistryApp.runtime;
    const scopeAttr = "data-ui-navbar";
    const scopeSelector = `[${scopeAttr}]`;
    const navbarCss = `
${scopeSelector} {
    background: var(--bg-surface);
    border-bottom: 1px solid var(--border);
    box-shadow: var(--shadow);
}

${scopeSelector} .app-navbar-inner {
    display: flex;
    justify-content: space-between;
    align-items: center;
    max-width: 1200px;
    width: 100%;
    margin: 0 auto;
    padding: 1rem 2rem;
    box-sizing: border-box;
}

${scopeSelector} .app-navbar-brand {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
}

${scopeSelector} .app-navbar-kicker {
    font-size: 0.7rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
    font-weight: 600;
}

${scopeSelector} .app-navbar-title {
    font-size: 1.25rem;
    font-weight: 700;
    color: var(--primary-hover);
    letter-spacing: -0.025em;
}

${scopeSelector} .app-navbar-actions {
    display: flex;
    align-items: center;
    gap: 1.5rem;
}

${scopeSelector} .app-navbar-view {
    font-size: 0.8rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    font-weight: 600;
}

${scopeSelector} .app-close-btn {
    background: transparent;
    color: var(--text-muted);
    border: 1px solid var(--border);
    padding: 0.5rem 1rem;
    font-size: 0.85rem;
}

${scopeSelector} .app-close-btn:hover {
    background: var(--bg-surface-hover);
    color: var(--primary-hover);
    border-color: var(--primary);
    transform: none;
    box-shadow: none;
}

@media (max-width: 960px) {
    ${scopeSelector} .app-navbar-inner {
        flex-direction: column;
        align-items: flex-start;
        padding: 1rem 1.5rem;
    }

    ${scopeSelector} .app-navbar-actions {
        align-items: flex-start;
    }
}
`;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.Navbar = function Navbar({
        kicker = "ORBIS",
        title = "",
        viewLabel = "",
        actionLabel = "",
        onAction = null,
    }) {
        ensureScopedStyle("shared-navbar", navbarCss);

        return h(
            "nav",
            { className: "app-navbar", [scopeAttr]: "" },
            h(
                "div",
                { className: "app-navbar-inner" },
                h(
                    "div",
                    { className: "app-navbar-brand" },
                    h("span", { className: "app-navbar-kicker" }, kicker),
                    h("span", { className: "app-navbar-title" }, title),
                ),
                h(
                    "div",
                    { className: "app-navbar-actions" },
                    h("span", { className: "app-navbar-view" }, viewLabel),
                    h(
                        "button",
                        {
                            type: "button",
                            className: "app-close-btn",
                            onClick: onAction,
                        },
                        actionLabel,
                    ),
                ),
            ),
        );
    };
})();

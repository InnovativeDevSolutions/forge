(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h, ensureScopedStyle } = RegistryApp.runtime;
    const scopeAttr = "data-ui-panel-card";
    const scopeSelector = `[${scopeAttr}]`;
    const panelCardCss = `
${scopeSelector} .org-panel-head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    margin-bottom: 1.5rem;
}

${scopeSelector} .org-eyebrow {
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.12em;
    text-transform: uppercase;
    color: var(--text-muted);
    margin-bottom: 0.4rem;
}

${scopeSelector} .org-panel-title {
    margin: 0;
    color: var(--primary-hover);
    font-size: 1.45rem;
}

${scopeSelector} .org-panel-subtitle {
    margin: 0.35rem 0 0;
    color: var(--text-muted);
    font-size: 0.95rem;
}

@media (max-width: 960px) {
    ${scopeSelector} .org-panel-head {
        flex-direction: column;
        align-items: flex-start;
    }
}
`;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.PanelCard = function PanelCard({
        className = "",
        eyebrow = "",
        title = "",
        subtitle = "",
        headerExtras = null,
        body = null,
        rootProps = {},
    }) {
        const finalClassName = ["card org-panel", className]
            .filter(Boolean)
            .join(" ");
        ensureScopedStyle("shared-panel-card", panelCardCss);

        return h(
            "section",
            { className: finalClassName, [scopeAttr]: "", ...rootProps },
            h(
                "div",
                { className: "org-panel-head" },
                h(
                    "div",
                    null,
                    eyebrow
                        ? h("div", { className: "org-eyebrow" }, eyebrow)
                        : null,
                    h("h2", { className: "org-panel-title" }, title),
                    subtitle
                        ? h("p", { className: "org-panel-subtitle" }, subtitle)
                        : null,
                ),
                headerExtras,
            ),
            body,
        );
    };
})();

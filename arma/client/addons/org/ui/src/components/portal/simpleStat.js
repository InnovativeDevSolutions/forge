(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const scopeAttr = "data-ui-simple-stat";
    const scopeSelector = `[${scopeAttr}]`;
    const simpleStatCss = `
${scopeSelector} {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
    min-width: 90px;
}

${scopeSelector} .org-simple-label {
    font-size: 0.72rem;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-muted);
}

${scopeSelector} .org-simple-value {
    font-size: 0.95rem;
    color: var(--text-main);
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.SimpleStat = function SimpleStat(label, value) {
        ensureScopedStyle("portal-simple-stat", simpleStatCss);

        return h(
            "div",
            { className: "org-simple-stat", [scopeAttr]: "" },
            h("span", { className: "org-simple-label" }, label),
            h("strong", { className: "org-simple-value" }, value),
        );
    };
})();

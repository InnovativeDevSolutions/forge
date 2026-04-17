(function () {
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h, ensureScopedStyle } = OrgPortal.runtime;
    const scopeAttr = "data-ui-metric-card";
    const scopeSelector = `[${scopeAttr}]`;
    const metricCardCss = `
${scopeSelector} {
    display: flex;
    flex-direction: column;
    gap: 0.45rem;
    padding: 1rem;
    border-radius: var(--radius);
    border: 1px solid var(--border);
    background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

${scopeSelector}:nth-child(4n + 2),
${scopeSelector}:nth-child(4n + 3) {
    background: linear-gradient(180deg, rgb(248 250 252) 0%, rgb(226 232 240) 100%);
    border-color: rgb(100 116 139 / 0.35);
    box-shadow: inset 0 1px 0 rgb(255 255 255 / 0.6);
}

${scopeSelector} .org-metric-label {
    font-size: 0.76rem;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-muted);
}

${scopeSelector} .org-metric-value {
    font-size: 1.8rem;
    color: var(--primary-hover);
    line-height: 1.1;
}

${scopeSelector}:nth-child(4n + 2) .org-metric-value,
${scopeSelector}:nth-child(4n + 3) .org-metric-value {
    color: #334155;
}

${scopeSelector} .org-metric-note {
    color: var(--text-muted);
    font-size: 0.9rem;
}

@media (max-width: 960px) {
    ${scopeSelector}:nth-child(4n + 3) {
        background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
        border-color: var(--border);
        box-shadow: none;
    }

    ${scopeSelector}:nth-child(4n + 3) .org-metric-value {
        color: var(--primary-hover);
    }
}
`;

    OrgPortal.componentFns = OrgPortal.componentFns || {};

    OrgPortal.componentFns.MetricCard = function MetricCard(
        label,
        value,
        note,
    ) {
        ensureScopedStyle("portal-metric-card", metricCardCss);

        return h(
            "div",
            { className: "org-metric-card", [scopeAttr]: "" },
            h("span", { className: "org-metric-label" }, label),
            h("strong", { className: "org-metric-value" }, value),
            h("span", { className: "org-metric-note" }, note),
        );
    };
})();

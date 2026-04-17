(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});
    const { h } = OrgPortal.runtime;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.Hero = function Hero({
        className = "",
        kicker = "",
        title = "",
        subtitle = "",
        meta = "",
    }) {
        const finalClassName = [
            "card org-panel org-span-12 org-page-header",
            className,
        ]
            .filter(Boolean)
            .join(" ");

        return h(
            "section",
            { className: finalClassName },
            h(
                "div",
                { className: "org-page-heading" },
                h("span", { className: "org-page-kicker" }, kicker),
                h("h1", { className: "org-page-title" }, title),
                h("p", { className: "org-page-subtitle" }, subtitle),
                h("span", { className: "org-page-meta" }, meta),
            ),
        );
    };
})();

(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h } = RegistryApp.runtime;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.Footer = function Footer({ sections = [] }) {
        return h(
            "div",
            { className: "footer" },
            h(
                "div",
                { className: "wrapper" },
                ...sections.map((section) =>
                    h(
                        "div",
                        null,
                        h("h3", null, section.title),
                        h(
                            "ul",
                            { style: { listStyleType: "none", padding: 0 } },
                            ...(section.items || []).map((item) =>
                                h("li", null, item),
                            ),
                        ),
                    ),
                ),
            ),
        );
    };
})();

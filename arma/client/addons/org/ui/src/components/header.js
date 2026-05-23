(function () {
    const SharedUI = (window.SharedUI = window.SharedUI || {});
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const { h } = RegistryApp.runtime;

    SharedUI.componentFns = SharedUI.componentFns || {};

    SharedUI.componentFns.Header = function Header({
        title,
        subtitle = "Organization Registration & Management Portal",
        onTitleClick = null,
    }) {
        return h(
            "div",
            { className: "header" },
            h(
                "h1",
                {
                    style: { cursor: onTitleClick ? "pointer" : "default" },
                    onClick: onTitleClick,
                },
                title,
            ),
            h("p", null, subtitle),
        );
    };
})();

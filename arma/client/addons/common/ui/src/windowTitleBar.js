(function (global) {
    const ForgeWebUI = global.ForgeWebUI;
    const SharedUI = (global.SharedUI = global.SharedUI || {});
    const { h, ensureScopedStyle } = ForgeWebUI;
    const titleBarCss = `
.ui-window-titlebar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    min-height: var(--ui-titlebar-min-height, 3.5rem);
    padding: var(--ui-titlebar-padding, 0.65rem 0.8rem 0.7rem 0.95rem);
    background: var(
        --ui-titlebar-bg,
        linear-gradient(180deg, #12325b 0%, #0d2643 100%)
    );
    color: var(--ui-titlebar-text, #f4f8fd);
    border-bottom: 1px solid var(--ui-titlebar-border, rgb(33 73 120 / 1));
    box-shadow: var(--ui-titlebar-shadow, 0 8px 18px rgb(18 50 91 / 0.18));
    position: var(--ui-titlebar-position, relative);
    top: var(--ui-titlebar-top, auto);
    z-index: var(--ui-titlebar-z-index, 5);
    flex-shrink: 0;
}

.ui-window-titlebar-brand {
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 0.1rem;
    min-width: 0;
}

.ui-window-titlebar-kicker {
    font-size: 0.64rem;
    font-weight: 700;
    line-height: 1;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--ui-titlebar-kicker-color, rgb(214 227 241 / 0.72));
}

.ui-window-titlebar-title {
    font-size: var(--ui-titlebar-title-size, 1rem);
    font-weight: 700;
    line-height: 1.1;
    letter-spacing: var(--ui-titlebar-title-spacing, -0.03em);
    color: inherit;
}

.ui-window-titlebar-controls {
    display: flex;
    align-items: center;
    gap: 0.12rem;
}

.ui-window-control-btn {
    min-width: 2rem;
    height: 2rem;
    margin: 0;
    padding: 0;
    border-radius: 0.38rem;
    border: 1px solid var(--ui-window-control-border, rgb(197 220 243 / 0.16));
    background: var(--ui-window-control-bg, rgb(255 255 255 / 0.04));
    color: var(--ui-window-control-text, rgb(237 244 251 / 0.88));
    line-height: 1;
    font-size: 0.82rem;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    box-shadow: none;
    transform: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
}

.ui-window-control-btn + .ui-window-control-btn {
    margin-left: 0;
}

.ui-window-control-btn:hover {
    background: var(--ui-window-control-hover-bg, rgb(255 255 255 / 0.04));
    box-shadow: none;
    transform: none;
}

.ui-window-control-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.ui-window-control-btn.is-close {
    cursor: pointer;
    opacity: 1;
    background: var(--ui-window-control-close-bg, rgb(255 255 255 / 0.1));
}

.ui-window-control-btn.is-close:hover {
    background: var(
        --ui-window-control-close-hover-bg,
        rgb(185 67 67 / 0.9)
    );
    border-color: var(
        --ui-window-control-close-hover-border,
        rgb(255 222 222 / 0.45)
    );
}

.ui-window-control-icon {
    width: 0.78rem;
    height: 0.78rem;
    stroke: currentColor;
    fill: none;
    stroke-width: 1.5;
    stroke-linecap: round;
    stroke-linejoin: round;
    pointer-events: none;
}

@media (max-width: 960px) {
    .ui-window-titlebar {
        flex-direction: column;
        align-items: flex-start;
    }

    .ui-window-titlebar-controls {
        width: 100%;
        justify-content: flex-end;
    }
}
`;

    SharedUI.componentFns = SharedUI.componentFns || {};

    function WindowControlIcon({ type }) {
        if (type === "minimize") {
            return h(
                "svg",
                {
                    className: "ui-window-control-icon",
                    viewBox: "0 0 16 16",
                    "aria-hidden": "true",
                },
                h("line", { x1: "3", y1: "8", x2: "13", y2: "8" }),
            );
        }

        if (type === "maximize") {
            return h(
                "svg",
                {
                    className: "ui-window-control-icon",
                    viewBox: "0 0 16 16",
                    "aria-hidden": "true",
                },
                h("rect", { x: "3.5", y: "3.5", width: "9", height: "9" }),
            );
        }

        return h(
            "svg",
            {
                className: "ui-window-control-icon",
                viewBox: "0 0 16 16",
                "aria-hidden": "true",
            },
            h("line", { x1: "4", y1: "4", x2: "12", y2: "12" }),
            h("line", { x1: "12", y1: "4", x2: "4", y2: "12" }),
        );
    }

    SharedUI.componentFns.WindowTitleBar = function WindowTitleBar({
        kicker = "",
        title = "",
        onClose = null,
        closeLabel = "Close interface",
        minimizeLabel = "Minimize unavailable",
        maximizeLabel = "Maximize unavailable",
    } = {}) {
        ensureScopedStyle("shared-window-titlebar", titleBarCss);

        return h(
            "div",
            { className: "ui-window-titlebar" },
            h(
                "div",
                { className: "ui-window-titlebar-brand" },
                kicker
                    ? h(
                          "span",
                          { className: "ui-window-titlebar-kicker" },
                          kicker,
                      )
                    : null,
                h("span", { className: "ui-window-titlebar-title" }, title),
            ),
            h(
                "div",
                { className: "ui-window-titlebar-controls" },
                h(
                    "button",
                    {
                        type: "button",
                        className: "ui-window-control-btn",
                        disabled: true,
                        title: minimizeLabel,
                        "aria-label": minimizeLabel,
                    },
                    WindowControlIcon({ type: "minimize" }),
                ),
                h(
                    "button",
                    {
                        type: "button",
                        className: "ui-window-control-btn",
                        disabled: true,
                        title: maximizeLabel,
                        "aria-label": maximizeLabel,
                    },
                    WindowControlIcon({ type: "maximize" }),
                ),
                h(
                    "button",
                    {
                        type: "button",
                        className: "ui-window-control-btn is-close",
                        title: "Close",
                        "aria-label": closeLabel,
                        onClick:
                            typeof onClose === "function" ? onClose : () => {},
                    },
                    WindowControlIcon({ type: "close" }),
                ),
            ),
        );
    };
})(window);

(function () {
    const RegistryApp = (window.RegistryApp = window.RegistryApp || {});
    const OrgPortal = (window.OrgPortal = window.OrgPortal || {});

    const SVG_NS = "http://www.w3.org/2000/svg";
    const SVG_TAGS = new Set([
        "svg",
        "path",
        "circle",
        "rect",
        "line",
        "polyline",
        "polygon",
        "g",
        "defs",
        "use",
        "text",
        "tspan",
        "clipPath",
        "mask",
    ]);

    function h(tag, props = {}, ...children) {
        const isSvg = SVG_TAGS.has(tag);
        const el = isSvg
            ? document.createElementNS(SVG_NS, tag)
            : document.createElement(tag);

        if (props) {
            Object.entries(props).forEach(([key, value]) => {
                if (key.startsWith("on") && typeof value === "function") {
                    el.addEventListener(key.substring(2).toLowerCase(), value);
                } else if (key === "className") {
                    if (isSvg) {
                        el.setAttribute("class", value);
                    } else {
                        el.className = value;
                    }
                } else if (key === "style" && typeof value === "object") {
                    Object.assign(el.style, value);
                } else if (typeof value === "boolean") {
                    if (value) {
                        el.setAttribute(key, "");
                    } else {
                        el.removeAttribute(key);
                    }
                } else if (value === null || value === undefined) {
                    el.removeAttribute(key);
                } else {
                    el.setAttribute(key, value);
                }
            });
        }

        children.forEach((child) => {
            if (typeof child === "string" || typeof child === "number") {
                el.appendChild(document.createTextNode(child));
            } else if (child instanceof Node) {
                el.appendChild(child);
            } else if (Array.isArray(child)) {
                child.forEach((c) => el.appendChild(c));
            }
        });

        return el;
    }

    let rootContainer = null;
    let rootComponent = null;
    const injectedStyles = new Set();

    function render(component, container) {
        rootContainer = container;
        rootComponent = component;
        rerender();
    }

    function rerender() {
        if (!rootContainer || !rootComponent) {
            return;
        }

        rootContainer.innerHTML = "";
        rootContainer.appendChild(rootComponent());
    }

    function ensureScopedStyle(id, cssText) {
        if (!id || !cssText || injectedStyles.has(id)) {
            return;
        }

        const style = document.createElement("style");
        style.setAttribute("data-ui-style", id);
        style.textContent = cssText;
        document.head.appendChild(style);
        injectedStyles.add(id);
    }

    function createSignal(initialValue) {
        let value = initialValue;

        const getValue = () => value;
        const setValue = (newValue) => {
            value = typeof newValue === "function" ? newValue(value) : newValue;
            rerender();
        };

        return [getValue, setValue];
    }

    const runtime = {
        h,
        render,
        createSignal,
        ensureScopedStyle,
        rerender,
    };

    RegistryApp.runtime = runtime;
    OrgPortal.runtime = runtime;
    window.AppRuntime = runtime;
})();

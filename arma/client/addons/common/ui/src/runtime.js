(function (global) {
    const ForgeWebUI = (global.ForgeWebUI = global.ForgeWebUI || {});

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

    const injectedStyles = new Set();
    const scheduledObservers = new Set();
    let activeObserver = null;
    let batchDepth = 0;
    let flushQueued = false;

    function queueFlush() {
        if (flushQueued || batchDepth > 0) {
            return;
        }

        flushQueued = true;
        queueMicrotask(() => {
            flushQueued = false;
            flushObservers();
        });
    }

    function flushObservers() {
        while (scheduledObservers.size > 0) {
            const queue = Array.from(scheduledObservers);
            scheduledObservers.clear();
            queue.forEach((observer) => runObserver(observer));
        }
    }

    function cleanupObserver(observer) {
        if (typeof observer.cleanup === "function") {
            try {
                observer.cleanup();
            } catch (error) {
                console.error("[ForgeWebUI] Observer cleanup failed.", error);
            }
        }

        observer.cleanup = null;
        observer.dependencies.forEach((dependency) => {
            dependency.delete(observer);
        });
        observer.dependencies.clear();
    }

    function runObserver(observer) {
        if (!observer || observer.disposed) {
            return;
        }

        cleanupObserver(observer);

        const previousObserver = activeObserver;
        activeObserver = observer;

        try {
            const cleanup = observer.fn();
            if (typeof cleanup === "function") {
                observer.cleanup = cleanup;
            }
        } catch (error) {
            console.error("[ForgeWebUI] Observer execution failed.", error);
        } finally {
            activeObserver = previousObserver;
        }
    }

    function scheduleObserver(observer) {
        if (!observer || observer.disposed) {
            return;
        }

        scheduledObservers.add(observer);
        queueFlush();
    }

    function trackDependency(dependency) {
        if (!activeObserver) {
            return;
        }

        dependency.add(activeObserver);
        activeObserver.dependencies.add(dependency);
    }

    function createSignalValue(initialValue) {
        let value = initialValue;
        const subscribers = new Set();

        function read() {
            trackDependency(subscribers);
            return value;
        }

        read.peek = () => value;
        read.set = (nextValue) => {
            const resolvedValue =
                typeof nextValue === "function" ? nextValue(value) : nextValue;

            if (Object.is(resolvedValue, value)) {
                return value;
            }

            value = resolvedValue;
            subscribers.forEach((observer) => scheduleObserver(observer));
            return value;
        };
        read.update = (updater) => read.set(updater);
        read.subscribe = (listener) =>
            effect(() => {
                listener(read());
            });

        return read;
    }

    function createSignal(initialValue) {
        const signal = createSignalValue(initialValue);
        return [signal, signal.set];
    }

    function computed(factory) {
        const valueSignal = createSignalValue(undefined);
        let initialized = false;

        effect(() => {
            const nextValue = factory();
            if (!initialized || !Object.is(nextValue, valueSignal.peek())) {
                initialized = true;
                valueSignal.set(nextValue);
            }
        });

        return valueSignal;
    }

    function effect(fn) {
        const observer = {
            cleanup: null,
            dependencies: new Set(),
            disposed: false,
            fn,
        };

        observer.dispose = () => {
            if (observer.disposed) {
                return;
            }

            observer.disposed = true;
            scheduledObservers.delete(observer);
            cleanupObserver(observer);
        };

        runObserver(observer);
        return observer.dispose;
    }

    function batch(fn) {
        batchDepth += 1;

        try {
            return fn();
        } finally {
            batchDepth = Math.max(0, batchDepth - 1);
            if (batchDepth === 0) {
                flushObservers();
            }
        }
    }

    function appendChild(node, child) {
        if (child === null || child === undefined || child === false) {
            return;
        }

        if (Array.isArray(child)) {
            child.forEach((entry) => appendChild(node, entry));
            return;
        }

        if (
            typeof child === "string" ||
            typeof child === "number" ||
            typeof child === "bigint"
        ) {
            node.appendChild(document.createTextNode(String(child)));
            return;
        }

        if (child instanceof Node) {
            node.appendChild(child);
        }
    }

    function fragment(...children) {
        const node = document.createDocumentFragment();
        children.forEach((child) => appendChild(node, child));
        return node;
    }

    function text(value) {
        return document.createTextNode(String(value ?? ""));
    }

    function applyProp(node, key, value, isSvg) {
        if (key === "key") {
            return;
        }

        if (key === "ref" && typeof value === "function") {
            value(node);
            return;
        }

        if (key === "className") {
            if (isSvg) {
                node.setAttribute("class", value || "");
            } else {
                node.className = value || "";
            }
            return;
        }

        if (key === "style" && value && typeof value === "object") {
            Object.assign(node.style, value);
            return;
        }

        if (key === "dataset" && value && typeof value === "object") {
            Object.entries(value).forEach(([name, datasetValue]) => {
                node.dataset[name] = datasetValue;
            });
            return;
        }

        if (key.startsWith("on") && typeof value === "function") {
            node.addEventListener(key.slice(2).toLowerCase(), value);
            return;
        }

        if (key === "value" && "value" in node) {
            node.value = value ?? "";
            return;
        }

        if (key === "checked" && "checked" in node) {
            node.checked = Boolean(value);
            return;
        }

        if (key === "selected" && "selected" in node) {
            node.selected = Boolean(value);
            return;
        }

        if (typeof value === "boolean") {
            if (value) {
                node.setAttribute(key, "");
            } else {
                node.removeAttribute(key);
            }
            return;
        }

        if (value === null || value === undefined) {
            node.removeAttribute(key);
            return;
        }

        node.setAttribute(key, value);
    }

    function h(tag, props = {}, ...children) {
        const isSvg = SVG_TAGS.has(tag);
        const node = isSvg
            ? document.createElementNS(SVG_NS, tag)
            : document.createElement(tag);

        if (props && typeof props === "object") {
            Object.entries(props).forEach(([key, value]) => {
                applyProp(node, key, value, isSvg);
            });
        }

        children.forEach((child) => appendChild(node, child));
        return node;
    }

    function normalizeNode(node) {
        if (node === null || node === undefined || node === false) {
            return document.createDocumentFragment();
        }

        if (Array.isArray(node)) {
            return fragment(...node);
        }

        if (
            typeof node === "string" ||
            typeof node === "number" ||
            typeof node === "bigint"
        ) {
            return text(node);
        }

        if (node instanceof Node) {
            return node;
        }

        return document.createDocumentFragment();
    }

    function captureScrollState(container) {
        return Array.from(
            container.querySelectorAll("[data-preserve-scroll-id]"),
        ).map((node) => ({
            id: node.getAttribute("data-preserve-scroll-id"),
            scrollLeft: node.scrollLeft,
            scrollTop: node.scrollTop,
        }));
    }

    function restoreScrollState(container, scrollState) {
        if (!Array.isArray(scrollState) || scrollState.length === 0) {
            return;
        }

        scrollState.forEach((entry) => {
            if (!entry || !entry.id) {
                return;
            }

            const target = container.querySelector(
                `[data-preserve-scroll-id="${entry.id}"]`,
            );

            if (!target) {
                return;
            }

            target.scrollTop = Number(entry.scrollTop || 0);
            target.scrollLeft = Number(entry.scrollLeft || 0);
        });
    }

    function mount(container, render, options = {}) {
        const preserveScroll = options.preserveScroll !== false;

        const dispose = effect(() => {
            const scrollState = preserveScroll
                ? captureScrollState(container)
                : [];
            const nextNode = normalizeNode(render());

            container.replaceChildren(nextNode);

            if (preserveScroll && scrollState.length > 0) {
                requestAnimationFrame(() => {
                    restoreScrollState(container, scrollState);
                });
            }
        });

        return {
            container,
            dispose,
            rerender() {
                container.replaceChildren(normalizeNode(render()));
            },
        };
    }

    function render(component, container, options = {}) {
        return mount(container, component, options);
    }

    function unmount(mountHandle) {
        if (!mountHandle || typeof mountHandle.dispose !== "function") {
            return;
        }

        mountHandle.dispose();
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

    ForgeWebUI.batch = batch;
    ForgeWebUI.computed = computed;
    ForgeWebUI.createSignal = createSignal;
    ForgeWebUI.effect = effect;
    ForgeWebUI.ensureScopedStyle = ensureScopedStyle;
    ForgeWebUI.fragment = fragment;
    ForgeWebUI.h = h;
    ForgeWebUI.mount = mount;
    ForgeWebUI.render = render;
    ForgeWebUI.signal = createSignalValue;
    ForgeWebUI.text = text;
    ForgeWebUI.unmount = unmount;
})(window);

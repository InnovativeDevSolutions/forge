(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const runtime = StorefrontApp.runtime;
    const [getTextureVersion, setTextureVersion] = runtime.createSignal(0);
    const MAX_CONCURRENT_TEXTURES = 6;
    const RERENDER_DELAY_MS = 48;
    const textureCache = Object.create(null);
    const textureRequests = Object.create(null);
    const queuedTexturePaths = [];
    const queuedTextureLookup = Object.create(null);
    const visibleTexturePaths = Object.create(null);
    const observedTextureNodes = new WeakSet();
    let activeTextureRequests = 0;
    let observer = null;
    let observerRoot = null;
    let rerenderTimer = 0;

    function normalizeTexturePath(path) {
        let normalizedPath = String(path || "").trim();
        if (!normalizedPath) {
            return "";
        }

        while (
            normalizedPath.startsWith("\\") ||
            normalizedPath.startsWith("/")
        ) {
            normalizedPath = normalizedPath.slice(1);
        }

        if (!/\.[A-Za-z0-9]+$/.test(normalizedPath)) {
            normalizedPath += ".paa";
        }

        return normalizedPath;
    }

    function isBrowserTextureSource(path) {
        const value = String(path || "")
            .trim()
            .toLowerCase();
        return (
            value.startsWith("data:image/") ||
            value.startsWith("blob:") ||
            value.startsWith("http://") ||
            value.startsWith("https://")
        );
    }

    function finalizeTextureSource(path, source) {
        textureCache[path] = source;

        scheduleRerender();
    }

    function scheduleRerender() {
        if (rerenderTimer) {
            return;
        }

        rerenderTimer = window.setTimeout(() => {
            rerenderTimer = 0;
            setTextureVersion((currentVersion) => currentVersion + 1);
        }, RERENDER_DELAY_MS);
    }

    function pumpTextureQueue() {
        if (
            typeof A3API === "undefined" ||
            typeof A3API.RequestTexture !== "function"
        ) {
            return;
        }

        while (
            activeTextureRequests < MAX_CONCURRENT_TEXTURES &&
            queuedTexturePaths.length > 0
        ) {
            const normalizedPath = queuedTexturePaths.shift();
            delete queuedTextureLookup[normalizedPath];

            if (
                !normalizedPath ||
                textureCache[normalizedPath] !== undefined ||
                textureRequests[normalizedPath]
            ) {
                continue;
            }

            activeTextureRequests += 1;
            textureRequests[normalizedPath] = Promise.resolve(
                A3API.RequestTexture(normalizedPath, 512),
            )
                .then((resolvedPath) => {
                    const textureSource = String(resolvedPath || "").trim();

                    if (isBrowserTextureSource(textureSource)) {
                        finalizeTextureSource(normalizedPath, textureSource);
                        return;
                    }

                    console.warn(
                        "[Store UI] Ignoring unsupported texture response.",
                        normalizedPath,
                        textureSource,
                    );
                    finalizeTextureSource(normalizedPath, "");
                })
                .catch((error) => {
                    console.warn(
                        "[Store UI] Failed to resolve texture.",
                        normalizedPath,
                        error,
                    );
                    finalizeTextureSource(normalizedPath, "");
                })
                .finally(() => {
                    activeTextureRequests = Math.max(
                        0,
                        activeTextureRequests - 1,
                    );
                    delete textureRequests[normalizedPath];
                    pumpTextureQueue();
                });
        }
    }

    function queueTextureRequest(path) {
        if (!path || queuedTextureLookup[path] || textureRequests[path]) {
            return;
        }

        queuedTextureLookup[path] = true;
        queuedTexturePaths.push(path);
        pumpTextureQueue();
    }

    function markTextureVisible(path) {
        const normalizedPath = normalizeTexturePath(path);
        if (!normalizedPath || visibleTexturePaths[normalizedPath]) {
            return;
        }

        visibleTexturePaths[normalizedPath] = true;
        if (
            !isBrowserTextureSource(textureCache[normalizedPath]) &&
            !textureRequests[normalizedPath]
        ) {
            queueTextureRequest(normalizedPath);
        }
    }

    function ensureObserver() {
        const currentRoot = document.querySelector(".catalog-grid");
        if (typeof IntersectionObserver !== "function") {
            return null;
        }

        if (observer && observerRoot === currentRoot) {
            return observer;
        }

        if (observer) {
            observer.disconnect();
        }

        observerRoot = currentRoot;
        observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (!entry.isIntersecting) {
                        return;
                    }

                    const rawPath = entry.target.getAttribute(
                        "data-store-texture-path",
                    );
                    markTextureVisible(rawPath);
                    observer.unobserve(entry.target);
                });
            },
            {
                root: currentRoot,
                rootMargin: "240px 0px",
                threshold: 0.01,
            },
        );

        return observer;
    }

    function observeTextureTargets() {
        const targets = document.querySelectorAll("[data-store-texture-path]");
        if (targets.length === 0) {
            return;
        }

        const activeObserver = ensureObserver();
        targets.forEach((target) => {
            if (observedTextureNodes.has(target)) {
                return;
            }

            observedTextureNodes.add(target);

            const rawPath = target.getAttribute("data-store-texture-path");
            if (!activeObserver) {
                markTextureVisible(rawPath);
                return;
            }

            activeObserver.observe(target);
        });
    }

    function scheduleTextureObservation() {
        window.requestAnimationFrame(() => {
            observeTextureTargets();
        });
    }

    function getTextureState(path) {
        getTextureVersion();
        const normalizedPath = normalizeTexturePath(path);
        return {
            path: normalizedPath,
            isVisible: Boolean(
                normalizedPath && visibleTexturePaths[normalizedPath],
            ),
            isLoaded: Boolean(
                normalizedPath &&
                textureCache[normalizedPath] &&
                isBrowserTextureSource(textureCache[normalizedPath]),
            ),
        };
    }

    function getTextureSource(path) {
        getTextureVersion();
        const normalizedPath = normalizeTexturePath(path);
        if (!normalizedPath) {
            return "";
        }

        if (isBrowserTextureSource(path)) {
            textureCache[normalizedPath] = String(path).trim();
            return textureCache[normalizedPath];
        }

        if (textureCache[normalizedPath] !== undefined) {
            return textureCache[normalizedPath];
        }

        if (visibleTexturePaths[normalizedPath]) {
            queueTextureRequest(normalizedPath);
            return "";
        }

        return "";
    }

    StorefrontApp.media = {
        getTextureState,
        getTextureSource,
        scheduleTextureObservation,
    };
})();

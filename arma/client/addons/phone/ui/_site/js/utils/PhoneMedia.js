/** @format */

const PhoneMedia = (() => {
    const addonRoot = 'forge\\forge_client\\addons\\phone\\ui\\_site\\';
    const cache = new Map();

    function assetPath(...parts) {
        return `${addonRoot}${parts.join('\\')}`;
    }

    function base64Path(...parts) {
        const path = assetPath(...parts);
        return path.endsWith('.b64') ? path : `${path}.b64`;
    }

    function toBrowserPath(path) {
        return String(path || '')
            .replace(addonRoot, '')
            .replace(/\\/g, '/')
            .replace(/\.b64$/i, '');
    }

    function toDataUrl(base64Text, mimeType = 'image/png') {
        const value = String(base64Text || '').trim();
        if (!value) return '';
        return value.startsWith('data:') ? value : `data:${mimeType};base64,${value}`;
    }

    function loadImage(path) {
        const base64AssetPath = path.endsWith('.b64') ? path : `${path}.b64`;

        if (cache.has(base64AssetPath)) {
            return Promise.resolve(cache.get(base64AssetPath));
        }

        if (typeof A3API !== 'undefined' && A3API.RequestFile) {
            return A3API.RequestFile(base64AssetPath).then((base64Text) => {
                const dataUrl = toDataUrl(base64Text);
                cache.set(base64AssetPath, dataUrl);
                return dataUrl;
            });
        }

        const browserPath = toBrowserPath(base64AssetPath);
        cache.set(base64AssetPath, browserPath);
        return Promise.resolve(browserPath);
    }

    return {
        assetPath,
        base64Path,
        loadImage
    };
})();

(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});

    const defaultSession = {
        actorName: "",
        actorUid: "",
        approval: "Field Access",
        orgId: "",
        orgName: "",
        orgLeader: false,
        defaultOrgCeo: false,
        canUseOrgFunds: false,
    };

    const defaultStoreConfig = {
        budget: 50000,
        creditLine: 0,
        availability: "In-Stock",
        moduleState: "Preview",
        searchTags: [
            "Attachment",
            "Grenade",
            "Medical",
            "Consumable",
            "Static",
            "Scope",
            "Item",
            "Misc",
        ],
        paymentSources: [
            {
                id: "cash",
                label: "Cash",
                balance: 0,
                enabled: false,
                detail: "Use on-hand cash carried by the player.",
            },
            {
                id: "bank",
                label: "Bank",
                balance: 0,
                enabled: false,
                detail: "Charge the player bank account.",
            },
            {
                id: "org_funds",
                label: "Org Funds",
                balance: 0,
                enabled: false,
                detail: "Only organization leaders or the default-org CEO can use treasury funds.",
            },
            {
                id: "credit_line",
                label: "Credit Line",
                balance: 0,
                enabled: false,
                detail: "No approved credit line is assigned to this member.",
            },
        ],
        defaultPaymentSource: "cash",
    };

    function cloneValue(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function replaceObject(target, source) {
        Object.keys(target).forEach((key) => delete target[key]);
        Object.assign(target, cloneValue(source));
    }

    const catalog = {
        categoryCards: [
            { id: "uniforms", label: "Uniforms" },
            { id: "headgear", label: "Headgear" },
            { id: "facewear", label: "Facewear" },
            { id: "vests", label: "Vests" },
            { id: "backpacks", label: "Backpacks" },
            { id: "attachments", label: "Attachments" },
            { id: "weapons", label: "Weapons" },
            { id: "ammo", label: "Ammo" },
            { id: "misc", label: "Misc" },
            { id: "vehicles", label: "Vehicles" },
        ],
        vehicleCards: [
            { id: "cars", label: "Cars" },
            { id: "armor", label: "Armor" },
            { id: "helis", label: "Helicopters" },
            { id: "planes", label: "Planes" },
            { id: "naval", label: "Naval" },
            { id: "other", label: "Other" },
        ],
        weaponCards: [
            { id: "primary", label: "Primary" },
            { id: "secondary", label: "Secondary" },
            { id: "handgun", label: "Handgun" },
        ],
        previewItems: {
            uniforms: [],
            headgear: [],
            facewear: [],
            vests: [],
            backpacks: [],
            attachments: [],
            ammo: [],
            misc: [],
            primary: [],
            secondary: [],
            handgun: [],
            cars: [],
            armor: [],
            helis: [],
            planes: [],
            naval: [],
            other: [],
        },
    };

    StorefrontApp.data = {
        catalog,
        session: Object.assign({}, defaultSession),
        storeConfig: Object.assign({}, defaultStoreConfig),
        applyHydratePayload(payload) {
            replaceObject(
                this.session,
                Object.assign({}, defaultSession, payload?.session || {}),
            );
            replaceObject(
                this.storeConfig,
                Object.assign(
                    {},
                    defaultStoreConfig,
                    payload?.storeConfig || {},
                ),
            );
        },
    };
})();

(function () {
    const ForgeWebUI = window.ForgeWebUI;
    const RegistryApp = window.RegistryApp;
    const OrgPortal = window.OrgPortal;
    const islandDefinitions = [
        {
            id: "org-portal-frame-root",
            preserveScroll: true,
            render: () => OrgPortal.components.App(),
        },
        {
            id: "org-portal-toast-root",
            preserveScroll: false,
            render: () => OrgPortal.componentFns.TreasuryNoticeLayer(),
        },
        {
            id: "org-overview-card-root",
            preserveScroll: false,
            render: () => OrgPortal.componentFns.OverviewCard(),
        },
        {
            id: "org-fleet-card-root",
            preserveScroll: true,
            render: () => OrgPortal.componentFns.FleetCard(),
        },
        {
            id: "org-treasury-card-root",
            preserveScroll: false,
            render: () => OrgPortal.componentFns.TreasuryCard(),
        },
        {
            id: "org-members-card-root",
            preserveScroll: true,
            render: () => OrgPortal.componentFns.MembersCard(),
        },
        {
            id: "org-assets-card-root",
            preserveScroll: true,
            render: () => OrgPortal.componentFns.AssetsCard(),
        },
        {
            id: "org-activity-card-root",
            preserveScroll: true,
            render: () => OrgPortal.componentFns.ActivityCard(),
        },
        {
            id: "org-portal-modal-root",
            preserveScroll: false,
            render: () => OrgPortal.componentFns.ModalLayer(),
        },
    ];

    function createIslandManager() {
        const mounts = new Map();

        function sync() {
            islandDefinitions.forEach((definition) => {
                const container = document.getElementById(definition.id);
                const current = mounts.get(definition.id);

                if (!container) {
                    if (current) {
                        current.handle.dispose();
                        mounts.delete(definition.id);
                    }
                    return;
                }

                if (current && current.container === container) {
                    return;
                }

                if (current) {
                    current.handle.dispose();
                }

                const handle = ForgeWebUI.mount(container, definition.render, {
                    preserveScroll: definition.preserveScroll,
                });
                mounts.set(definition.id, {
                    container,
                    handle,
                });
            });
        }

        return {
            sync,
        };
    }

    const app = ForgeWebUI.createApp({
        name: "org",
        root: "#app",
        setup({ root }) {
            const islandManager = createIslandManager();

            ForgeWebUI.mount(root, () => RegistryApp.components.App(), {
                preserveScroll: false,
            });
            RegistryApp.bridge.ready({ loaded: true });

            ForgeWebUI.effect(() => {
                RegistryApp.store.getView();

                requestAnimationFrame(() => {
                    islandManager.sync();
                });
            });
        },
    });

    app.start();
})();

(function () {
    const ForgeWebUI = window.ForgeWebUI;
    const BankApp = window.BankApp;
    const islandDefinitions = [
        {
            id: "bank-notice-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.NoticeLayer(),
        },
        {
            id: "bank-sidebar-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankSidebar(),
        },
        {
            id: "bank-page-header-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankPageHeader(),
        },
        {
            id: "bank-summary-section-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankSummarySection(),
        },
        {
            id: "bank-action-sections-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankActionSections(),
        },
        {
            id: "bank-support-section-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankSupportSection(),
        },
        {
            id: "bank-history-section-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankHistorySection(),
        },
        {
            id: "bank-atm-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.ATMView(),
        },
        {
            id: "bank-footer-root",
            preserveScroll: false,
            render: () => BankApp.componentFns.BankFooter(),
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
        name: "bank",
        root: "#app",
        setup({ root }) {
            const islandManager = createIslandManager();

            ForgeWebUI.mount(root, () => BankApp.components.App(), {
                preserveScroll: false,
            });

            if (BankApp.bridge) {
                BankApp.bridge.notifyReady();
            }

            ForgeWebUI.effect(() => {
                BankApp.store.getMode();

                requestAnimationFrame(() => {
                    islandManager.sync();
                });
            });
        },
    });

    app.start();
})();

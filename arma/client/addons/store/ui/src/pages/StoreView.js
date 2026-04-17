(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const CATALOG_PAGE_SIZE = 6;

    function getSelectionKey(state) {
        return (
            state.selectedWeaponSlot ||
            state.selectedVehicleSlot ||
            state.selectedCategory
        );
    }

    function matchesQuery(query, values) {
        if (!query) {
            return true;
        }

        const normalizedQuery = String(query).trim().toLowerCase();
        if (!normalizedQuery) {
            return true;
        }

        return values.some((value) =>
            String(value || "")
                .toLowerCase()
                .includes(normalizedQuery),
        );
    }

    function parsePrice(value) {
        const parsed = Number(String(value || "0").replace(/[^0-9.-]+/g, ""));
        return Number.isFinite(parsed) ? parsed : 0;
    }

    function formatCurrency(value) {
        return `$${Number(value || 0).toLocaleString()}`;
    }

    function formatTitle(value) {
        const normalizedValue = String(value || "")
            .trim()
            .toLowerCase();
        if (["items", "misc"].includes(normalizedValue)) {
            return "Misc";
        }

        return String(value || "")
            .replace(/[-_]+/g, " ")
            .split(/\s+/)
            .filter(Boolean)
            .map(
                (part) =>
                    part.charAt(0).toUpperCase() + part.slice(1).toLowerCase(),
            )
            .join(" ");
    }

    function getStoreState(store) {
        return {
            view: store.getView(),
            selectedCategory: store.getSelectedCategory(),
            selectedWeaponSlot: store.getSelectedWeaponSlot(),
            selectedVehicleSlot: store.getSelectedVehicleSlot(),
            selectedPaymentSource: store.getSelectedPaymentSource(),
            cartOpen: store.getCartOpen(),
            searchQuery: store.getSearchQuery(),
            cartItems: store.getCartItems(),
            catalogItemsByKey: store.getCatalogItemsByKey(),
            isCatalogLoading: store.getIsCatalogLoading(),
            catalogRequestKey: store.getCatalogRequestKey(),
            catalogPage: store.getCatalogPage(),
            isCheckingOut: store.getIsCheckingOut(),
        };
    }

    function getStoreHeader(state) {
        if (state.view === "weapons") {
            return {
                eyebrow: "Weapons Division",
                title: "Weapon Categories",
                copy: "Select a weapon slot to open the next supply tier. Primary, secondary, and handgun are staged with the same state and bridge flow as the org portal.",
                badge: "3 Slots",
            };
        }

        if (state.view === "vehicles") {
            return {
                eyebrow: "Vehicle Motorpool",
                title: "Vehicle Categories",
                copy: "Select a vehicle class to open the next supply tier. Cars, armor, airframes, and naval options stay inside the same local store and bridge lifecycle.",
                badge: "6 Classes",
            };
        }

        if (state.view === "items") {
            const label = getSelectionKey(state) || "catalog";
            const queryLabel = state.searchQuery
                ? ` Filtered by "${state.searchQuery}".`
                : "";
            const loadingLabel = state.isCatalogLoading
                ? " Pulling live inventory from the game engine."
                : "";

            return {
                eyebrow: "Catalog Preview",
                title: formatTitle(label),
                copy: `Live category inventory generated from the game engine for the selected department.${queryLabel}${loadingLabel}`,
                badge: "Preview Items",
            };
        }

        return {
            eyebrow: "Supply Categories",
            title: "Procurement Dashboard",
            copy: "Choose a category to enter the exchange. Weapons and vehicles open a second tier, while the other departments display placeholder product inventory inside the new runtime/store architecture.",
            badge: "8 Categories",
        };
    }

    function getStoreBreadcrumbs(state) {
        const items = [{ id: "categories", label: "Supply Exchange" }];

        if (state.view === "weapons") {
            items.push({ id: "weapons", label: "Weapons" });
            return items;
        }

        if (state.view === "vehicles") {
            items.push({ id: "vehicles", label: "Vehicles" });
            return items;
        }

        if (state.view === "items") {
            if (state.selectedWeaponSlot) {
                items.push({ id: "weapons", label: "Weapons" });
                items.push({
                    id: "weapon-slot",
                    label: formatTitle(state.selectedWeaponSlot),
                });
                return items;
            }

            if (state.selectedVehicleSlot) {
                items.push({ id: "vehicles", label: "Vehicles" });
                items.push({
                    id: "vehicle-slot",
                    label: formatTitle(state.selectedVehicleSlot),
                });
                return items;
            }

            if (state.selectedCategory) {
                items.push({
                    id: "category",
                    label: formatTitle(state.selectedCategory),
                });
            }
        }

        return items;
    }

    function getVisibleCategoryCards(state, catalog) {
        return catalog.categoryCards.filter((category) =>
            matchesQuery(state.searchQuery, [category.id, category.label]),
        );
    }

    function getVisibleSubcategoryCards(state, catalog) {
        const source =
            state.view === "vehicles"
                ? catalog.vehicleCards
                : catalog.weaponCards;

        return source.filter((category) =>
            matchesQuery(state.searchQuery, [category.id, category.label]),
        );
    }

    function getVisibleItems(state, catalog) {
        const key = getSelectionKey(state);
        const categoryKey = String(key || "")
            .trim()
            .toLowerCase();
        const itemsByKey = state.catalogItemsByKey || {};
        const items = Array.isArray(itemsByKey[categoryKey])
            ? itemsByKey[categoryKey]
            : [];

        return items.filter((item) =>
            matchesQuery(state.searchQuery, [
                item.className,
                item.code,
                item.name,
                item.description,
                item.price,
                item.type,
            ]),
        );
    }

    function getCatalogPagination(state, catalog) {
        const totalItems = getVisibleItems(state, catalog).length;
        const totalPages = Math.max(
            1,
            Math.ceil(totalItems / CATALOG_PAGE_SIZE),
        );
        const currentPage = Math.min(
            totalPages,
            Math.max(1, Number(state.catalogPage || 1)),
        );

        return {
            pageSize: CATALOG_PAGE_SIZE,
            totalItems,
            totalPages,
            currentPage,
            startIndex:
                totalItems === 0
                    ? 0
                    : (currentPage - 1) * CATALOG_PAGE_SIZE + 1,
            endIndex: Math.min(currentPage * CATALOG_PAGE_SIZE, totalItems),
        };
    }

    function getVisibleItemsPage(state, catalog) {
        const items = getVisibleItems(state, catalog);
        const pagination = getCatalogPagination(state, catalog);
        const startOffset = (pagination.currentPage - 1) * pagination.pageSize;
        return items.slice(startOffset, startOffset + pagination.pageSize);
    }

    function summarizeCart(cartItems) {
        const itemCount = cartItems.reduce(
            (sum, item) => sum + Number(item.quantity || 0),
            0,
        );
        const subtotal = cartItems.reduce(
            (sum, item) =>
                sum + parsePrice(item.price) * Number(item.quantity || 0),
            0,
        );

        return {
            lineCount: cartItems.length,
            itemCount,
            subtotal,
            total: subtotal,
        };
    }

    function getPaymentSources(storeConfig) {
        const paymentSources = Array.isArray(storeConfig?.paymentSources)
            ? storeConfig.paymentSources
            : [];

        return paymentSources.map((source) => ({
            id: String(source?.id || "").trim(),
            label: String(source?.label || source?.id || "").trim(),
            balance: Number(source?.balance || 0),
            enabled: source?.enabled !== false,
            detail: String(source?.detail || "").trim(),
        }));
    }

    function getPaymentSourceById(storeConfig, paymentSourceId) {
        const sourceId = String(paymentSourceId || "").trim();
        return getPaymentSources(storeConfig).find(
            (source) => source.id === sourceId,
        );
    }

    StorefrontApp.getters = {
        formatTitle,
        formatCurrency,
        parsePrice,
        getSelectionKey,
        getStoreState,
        getStoreHeader,
        getStoreBreadcrumbs,
        getVisibleCategoryCards,
        getVisibleSubcategoryCards,
        getVisibleItems,
        getVisibleItemsPage,
        getCatalogPagination,
        summarizeCart,
        getPaymentSources,
        getPaymentSourceById,
    };
})();

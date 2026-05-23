(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const store = StorefrontApp.store;
    const getters = StorefrontApp.getters;
    const { storeConfig, session } = StorefrontApp.data;

    let noticeTimer = null;

    function showNotice(type, text) {
        store.setNotice({ type, text });

        if (noticeTimer) {
            clearTimeout(noticeTimer);
        }

        noticeTimer = setTimeout(() => {
            store.setNotice({ type: "", text: "" });
            noticeTimer = null;
        }, 3200);
    }

    function normalizeCheckoutItem(item) {
        return {
            classname: String(item?.code || "").trim(),
            category: String(item?.category || "")
                .trim()
                .toLowerCase(),
            entryKind: String(item?.entryKind || "item")
                .trim()
                .toLowerCase(),
            quantity: Math.max(1, Number(item?.quantity || 1)),
        };
    }

    function buildCheckoutPayload(cartItems, paymentMethod, totalPrice) {
        const payload = {
            items: [],
            vehicles: [],
            totalPrice,
            paymentMethod,
        };

        cartItems.forEach((item) => {
            const normalizedItem = normalizeCheckoutItem(item);

            if (normalizedItem.entryKind === "vehicle") {
                for (
                    let index = 0;
                    index < normalizedItem.quantity;
                    index += 1
                ) {
                    payload.vehicles.push({
                        classname: normalizedItem.classname,
                        category: normalizedItem.category,
                    });
                }
                return;
            }

            payload.items.push({
                classname: normalizedItem.classname,
                category: normalizedItem.category,
                quantity: normalizedItem.quantity,
            });
        });

        return payload;
    }

    function applySearchQuery(value) {
        store.setSearchQuery(String(value || "").trim());
        store.resetCatalogPage();
    }

    function clearSearch() {
        store.setSearchQuery("");
        store.resetCatalogPage();
    }

    function toggleCart() {
        store.setCartOpen((open) => !open);
    }

    function closeCart() {
        store.setCartOpen(false);
    }

    function closeStore() {
        const bridge = StorefrontApp.bridge;
        if (bridge && typeof bridge.requestClose === "function") {
            const sent = bridge.requestClose();
            if (sent) {
                return true;
            }
        }

        showNotice("error", "Store bridge is unavailable.");
        return false;
    }

    function navigateToBreadcrumb(target) {
        return store.navigateToBreadcrumb(target);
    }

    function scrollCatalogToTop() {
        const catalogGrid = document.querySelector(
            '[data-preserve-scroll-id="catalog-grid"]',
        );
        if (catalogGrid) {
            catalogGrid.scrollTop = 0;
        }
    }

    function selectCategory(category) {
        store.selectCategory(category);
        scrollCatalogToTop();

        if (!["weapons", "vehicles"].includes(String(category || ""))) {
            requestCategoryItems(category);
        }
    }

    function selectSubcategory(subcategory, slotType) {
        store.selectSubcategory(subcategory, slotType);
        scrollCatalogToTop();
        requestCategoryItems(subcategory);
    }

    function goToCatalogPage(page) {
        store.setCatalogPageNumber(page);
        scrollCatalogToTop();
    }

    function goToNextCatalogPage(totalPages) {
        const currentPage = Number(store.getCatalogPage() || 1);
        const lastPage = Math.max(1, Number(totalPages || 1));
        if (currentPage >= lastPage) {
            return false;
        }

        goToCatalogPage(currentPage + 1);
        return true;
    }

    function goToPreviousCatalogPage() {
        const currentPage = Number(store.getCatalogPage() || 1);
        if (currentPage <= 1) {
            return false;
        }

        goToCatalogPage(currentPage - 1);
        return true;
    }

    function requestCategoryItems(category) {
        const categoryKey = String(category || "")
            .trim()
            .toLowerCase();
        if (!categoryKey) {
            return false;
        }

        const cachedItems = store.getCatalogItemsByKey();
        if (Array.isArray(cachedItems[categoryKey])) {
            store.finishCategoryRequest("");
            return true;
        }

        store.startCategoryRequest(categoryKey);

        const bridge = StorefrontApp.bridge;
        if (!bridge || typeof bridge.requestCategory !== "function") {
            store.finishCategoryRequest(categoryKey);
            showNotice("error", "Store bridge is unavailable.");
            return false;
        }

        const sent = bridge.requestCategory({ category: categoryKey });
        if (!sent) {
            store.finishCategoryRequest(categoryKey);
            showNotice("error", "Category request bridge is unavailable.");
            return false;
        }

        return true;
    }

    function addToCart(item) {
        store.setCartItems((currentItems) => {
            const existingIndex = currentItems.findIndex(
                (entry) => entry.code === item.code,
            );
            if (existingIndex === -1) {
                return [
                    ...currentItems,
                    {
                        code: item.code,
                        name: item.name,
                        price: item.price,
                        category: item.category,
                        entryKind: item.entryKind,
                        quantity: 1,
                    },
                ];
            }

            const nextItems = [...currentItems];
            nextItems[existingIndex] = Object.assign(
                {},
                nextItems[existingIndex],
                {
                    category: item.category,
                    entryKind: item.entryKind,
                    quantity: nextItems[existingIndex].quantity + 1,
                },
            );
            return nextItems;
        });

        showNotice("success", `${item.name} added to the acquisition queue.`);
    }

    function incrementCartItem(code) {
        store.setCartItems((currentItems) =>
            currentItems.map((item) =>
                item.code === code
                    ? Object.assign({}, item, { quantity: item.quantity + 1 })
                    : item,
            ),
        );
    }

    function decrementCartItem(code) {
        store.setCartItems((currentItems) =>
            currentItems
                .map((item) =>
                    item.code === code
                        ? Object.assign({}, item, {
                              quantity: Math.max(0, item.quantity - 1),
                          })
                        : item,
                )
                .filter((item) => item.quantity > 0),
        );
    }

    function removeCartItem(code) {
        store.setCartItems((currentItems) =>
            currentItems.filter((item) => item.code !== code),
        );
    }

    function selectPaymentSource(paymentSourceId) {
        const sourceId = String(paymentSourceId || "").trim();
        const paymentSources = getters.getPaymentSources(storeConfig);
        const selectedSource = paymentSources.find(
            (source) => source.id === sourceId,
        );

        if (!selectedSource) {
            showNotice("error", "Selected payment source is unavailable.");
            return false;
        }

        if (selectedSource.enabled === false) {
            showNotice(
                "error",
                selectedSource.detail ||
                    "Selected payment source is not available.",
            );
            return false;
        }

        store.setSelectedPaymentSource(sourceId);
        return true;
    }

    function requestCheckout() {
        const cartItems = store.getCartItems();
        if (cartItems.length === 0) {
            showNotice("error", "Add at least one item before checkout.");
            return false;
        }

        const summary = getters.summarizeCart(cartItems);
        const selectedPaymentSource = getters.getPaymentSourceById(
            storeConfig,
            store.getSelectedPaymentSource(),
        );

        if (!selectedPaymentSource) {
            showNotice("error", "Select a payment source before checkout.");
            return false;
        }

        if (selectedPaymentSource.enabled === false) {
            showNotice(
                "error",
                selectedPaymentSource.detail ||
                    "Selected payment source is unavailable.",
            );
            return false;
        }

        if (summary.total > Number(selectedPaymentSource.balance || 0)) {
            showNotice(
                "error",
                `${selectedPaymentSource.label} cannot cover this checkout total.`,
            );
            return false;
        }

        const bridge = StorefrontApp.bridge;
        if (!bridge || typeof bridge.requestCheckout !== "function") {
            showNotice("error", "Checkout bridge is unavailable.");
            return false;
        }

        store.setIsCheckingOut(true);

        const checkoutPayload = buildCheckoutPayload(
            cartItems,
            selectedPaymentSource.id,
            summary.total,
        );

        const sent = bridge.requestCheckout({
            checkoutJson: JSON.stringify(checkoutPayload),
        });

        if (!sent) {
            store.setIsCheckingOut(false);
            showNotice("error", "Checkout bridge is unavailable.");
            return false;
        }

        return true;
    }

    StorefrontApp.actions = {
        showNotice,
        applySearchQuery,
        clearSearch,
        toggleCart,
        closeCart,
        closeStore,
        navigateToBreadcrumb,
        selectCategory,
        selectSubcategory,
        goToCatalogPage,
        goToNextCatalogPage,
        goToPreviousCatalogPage,
        addToCart,
        incrementCartItem,
        decrementCartItem,
        removeCartItem,
        selectPaymentSource,
        requestCheckout,
        formatTitle: getters.formatTitle,
        formatCurrency: getters.formatCurrency,
    };
})();

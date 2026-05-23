(function () {
    const StorefrontApp = (window.StorefrontApp = window.StorefrontApp || {});
    const { createSignal } = StorefrontApp.runtime;
    const SharedLogic = (window.SharedLogic = window.SharedLogic || {});

    SharedLogic.createStorefrontStore = function createStorefrontStore({
        createSignal,
    }) {
        function normalizeCatalogItem(item) {
            return {
                className: String(item?.className || item?.code || ""),
                code: String(item?.code || item?.className || ""),
                name: String(item?.name || item?.displayName || ""),
                description: String(item?.description || ""),
                price: String(item?.price || ""),
                image: String(item?.image || ""),
                type: String(item?.type || ""),
                category: String(item?.category || ""),
                entryKind: String(item?.entryKind || "item"),
                quantity: Math.max(0, Number(item?.quantity || 0)),
            };
        }

        function normalizeCartItem(item) {
            return {
                code: String(item?.code || ""),
                name: String(item?.name || ""),
                price: String(item?.price || "$0"),
                category: String(item?.category || ""),
                entryKind: String(item?.entryKind || "item"),
                quantity: Math.max(1, Number(item?.quantity || 1)),
            };
        }

        class StorefrontStore {
            constructor() {
                [this.getView, this.setView] = createSignal("categories");
                [this.getSelectedCategory, this.setSelectedCategory] =
                    createSignal("");
                [this.getSelectedWeaponSlot, this.setSelectedWeaponSlot] =
                    createSignal("");
                [this.getSelectedVehicleSlot, this.setSelectedVehicleSlot] =
                    createSignal("");
                [this.getCartOpen, this.setCartOpen] = createSignal(false);
                [this.getSearchQuery, this.setSearchQuery] = createSignal("");
                [this.getCartItems, this.setCartItems] = createSignal([]);
                [this.getCatalogItemsByKey, this.setCatalogItemsByKey] =
                    createSignal({});
                [this.getIsCatalogLoading, this.setIsCatalogLoading] =
                    createSignal(false);
                [this.getCatalogRequestKey, this.setCatalogRequestKey] =
                    createSignal("");
                [this.getCatalogPage, this.setCatalogPage] = createSignal(1);
                [this.getNotice, this.setNotice] = createSignal({
                    type: "",
                    text: "",
                });
                [this.getIsCheckingOut, this.setIsCheckingOut] =
                    createSignal(false);
                [this.getSelectedPaymentSource, this.setSelectedPaymentSource] =
                    createSignal("cash");
            }

            resetToCategories() {
                this.setView("categories");
                this.setSelectedCategory("");
                this.setSelectedWeaponSlot("");
                this.setSelectedVehicleSlot("");
                this.setIsCatalogLoading(false);
                this.setCatalogRequestKey("");
                this.setCatalogPage(1);
            }

            openWeaponsRoot() {
                this.setView("weapons");
                this.setSelectedCategory("weapons");
                this.setSelectedWeaponSlot("");
                this.setSelectedVehicleSlot("");
                this.setIsCatalogLoading(false);
                this.setCatalogRequestKey("");
                this.setCatalogPage(1);
            }

            openVehiclesRoot() {
                this.setView("vehicles");
                this.setSelectedCategory("vehicles");
                this.setSelectedVehicleSlot("");
                this.setSelectedWeaponSlot("");
                this.setIsCatalogLoading(false);
                this.setCatalogRequestKey("");
                this.setCatalogPage(1);
            }

            resetCatalogPage() {
                this.setCatalogPage(1);
            }

            setCatalogPageNumber(page) {
                const nextPage = Math.max(1, Number(page || 1));
                this.setCatalogPage(nextPage);
            }

            selectCategory(category) {
                this.setSelectedCategory(category);
                this.setSelectedWeaponSlot("");
                this.setSelectedVehicleSlot("");
                this.setCatalogPage(1);

                if (category === "weapons") {
                    this.openWeaponsRoot();
                    return;
                }

                if (category === "vehicles") {
                    this.openVehiclesRoot();
                    return;
                }

                this.setView("items");
            }

            selectSubcategory(subcategory, slotType) {
                if (slotType === "vehicle") {
                    this.setSelectedVehicleSlot(subcategory);
                    this.setSelectedWeaponSlot("");
                } else {
                    this.setSelectedWeaponSlot(subcategory);
                    this.setSelectedVehicleSlot("");
                }

                this.setCatalogPage(1);
                this.setView("items");
            }

            startCategoryRequest(category) {
                const categoryKey = String(category || "")
                    .trim()
                    .toLowerCase();
                if (!categoryKey) {
                    return false;
                }

                this.setCatalogRequestKey(categoryKey);
                this.setIsCatalogLoading(true);
                return true;
            }

            finishCategoryRequest(category) {
                const categoryKey = String(category || "")
                    .trim()
                    .toLowerCase();
                const activeKey = String(this.getCatalogRequestKey() || "")
                    .trim()
                    .toLowerCase();

                if (!categoryKey || !activeKey || activeKey === categoryKey) {
                    this.setCatalogRequestKey("");
                    this.setIsCatalogLoading(false);
                }
            }

            hydrateCategoryItems(payload) {
                const categoryKey = String(payload?.category || "")
                    .trim()
                    .toLowerCase();
                const items = Array.isArray(payload?.items)
                    ? payload.items
                    : [];

                if (!categoryKey) {
                    this.setCatalogRequestKey("");
                    this.setIsCatalogLoading(false);
                    return;
                }

                this.setCatalogItemsByKey((currentItemsByKey) =>
                    Object.assign({}, currentItemsByKey, {
                        [categoryKey]: items.map(normalizeCatalogItem),
                    }),
                );

                this.finishCategoryRequest(categoryKey);
            }

            ensureSelectedPaymentSource(storeConfig) {
                const paymentSources = Array.isArray(
                    storeConfig?.paymentSources,
                )
                    ? storeConfig.paymentSources
                    : [];
                const currentSource = String(
                    this.getSelectedPaymentSource() || "",
                ).trim();
                const defaultSource = String(
                    storeConfig?.defaultPaymentSource || "",
                ).trim();
                const sourceIds = paymentSources.map((source) =>
                    String(source?.id || "").trim(),
                );
                const enabledSource = paymentSources.find(
                    (source) => source && source.enabled !== false,
                );
                const defaultAvailable =
                    defaultSource && sourceIds.includes(defaultSource)
                        ? paymentSources.find(
                              (source) =>
                                  String(source?.id || "").trim() ===
                                  defaultSource,
                          )
                        : null;

                if (
                    currentSource &&
                    sourceIds.includes(currentSource) &&
                    paymentSources.some(
                        (source) =>
                            String(source?.id || "").trim() === currentSource &&
                            source?.enabled !== false,
                    )
                ) {
                    return;
                }

                if (defaultAvailable && defaultAvailable.enabled !== false) {
                    this.setSelectedPaymentSource(defaultSource);
                    return;
                }

                if (enabledSource) {
                    this.setSelectedPaymentSource(
                        String(enabledSource.id || "cash"),
                    );
                    return;
                }

                this.setSelectedPaymentSource(defaultSource || "cash");
            }

            navigateToBreadcrumb(target) {
                switch (target) {
                    case "categories":
                        this.resetToCategories();
                        return true;
                    case "weapons":
                        this.openWeaponsRoot();
                        return true;
                    case "vehicles":
                        this.openVehiclesRoot();
                        return true;
                    default:
                        return false;
                }
            }

            hydrateFromPayload(payload) {
                const cartItems = Array.isArray(payload?.cartItems)
                    ? payload.cartItems
                    : [];

                this.setCartItems(cartItems.map(normalizeCartItem));
                this.setCartOpen(false);
                this.setIsCheckingOut(false);
                this.setCatalogItemsByKey({});
                this.setCatalogRequestKey("");
                this.setIsCatalogLoading(false);
                this.setCatalogPage(1);
                this.ensureSelectedPaymentSource(payload?.storeConfig || {});
            }

            hydrateStoreConfig(payload) {
                const cartItems = Array.isArray(payload?.cartItems)
                    ? payload.cartItems
                    : [];

                this.setCartItems(cartItems.map(normalizeCartItem));
                this.setCartOpen(false);
                this.setIsCheckingOut(false);
                this.ensureSelectedPaymentSource(payload?.storeConfig || {});
            }
        }

        return new StorefrontStore();
    };

    StorefrontApp.store = SharedLogic.createStorefrontStore({
        createSignal,
    });
})();

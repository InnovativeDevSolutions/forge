(function () {
    const GarageApp = (window.GarageApp = window.GarageApp || {});
    const { h } = GarageApp.runtime;
    const WindowTitleBar = window.SharedUI.componentFns.WindowTitleBar;
    const store = GarageApp.store;
    const actions = GarageApp.actions;
    const { categories, garage, nearby, session } = GarageApp.data;

    function q(query, values) {
        const needle = String(query || "")
            .trim()
            .toLowerCase();
        if (!needle) {
            return true;
        }

        return values.some((value) =>
            String(value || "")
                .toLowerCase()
                .includes(needle),
        );
    }

    function pct(value) {
        return Math.max(0, Math.min(100, Math.round(Number(value || 0) * 100)));
    }

    function categoryLabel(category) {
        const match = categories.find(
            (entry) => entry.id === String(category || "other").toLowerCase(),
        );
        return match ? match.label : "Other";
    }

    function distanceLabel(value) {
        return `${Math.round(Number(value || 0))} m`;
    }

    function plateLabel(value) {
        return String(value || "").trim() || "Untracked";
    }

    function statusLabel(vehicle) {
        if (!vehicle) {
            return "-";
        }

        if (vehicle.entryKind === "stored") {
            return "Stored";
        }

        return vehicle.isEmpty === false ? "Crewed" : "Ready";
    }

    function normalizeHitPointLabel(value) {
        return String(value || "")
            .replace(/^Hit/i, "")
            .replace(/([a-z])([A-Z])/g, "$1 $2")
            .replace(/_/g, " ")
            .trim();
    }

    function sameEntry(left, right) {
        if (!left || !right) {
            return false;
        }

        return (
            String(left.entryKind || "") === String(right.entryKind || "") &&
            String(left.plate || "") === String(right.plate || "") &&
            String(left.netId || "") === String(right.netId || "")
        );
    }

    function selectedEntry(state) {
        if (state.selectedKind === "stored") {
            return (
                (garage.vehicles || []).find(
                    (vehicle) =>
                        String(vehicle.plate || "") === state.selectedId,
                ) || null
            );
        }

        if (state.selectedKind === "nearby") {
            return (
                (nearby.vehicles || []).find(
                    (vehicle) =>
                        String(vehicle.netId || "") === state.selectedId,
                ) || null
            );
        }

        return null;
    }

    function visibleVehicles(vehicles, state) {
        return (vehicles || []).filter((vehicle) => {
            if (
                state.categoryFilter !== "all" &&
                String(vehicle.category || "").toLowerCase() !==
                    state.categoryFilter
            ) {
                return false;
            }

            return q(state.searchQuery, [
                vehicle.displayName,
                vehicle.classname,
                vehicle.plate,
                vehicle.netId,
                vehicle.category,
            ]);
        });
    }

    function stat(label, value, tone = "") {
        return h(
            "div",
            {
                className: tone
                    ? `garage-stat-card is-${tone}`
                    : "garage-stat-card",
            },
            h("span", { className: "garage-stat-label" }, label),
            h("span", { className: "garage-stat-value" }, value),
        );
    }

    function meter(label, percent, tone) {
        return h(
            "div",
            { className: "garage-meter" },
            h(
                "div",
                { className: "garage-meter-label-row" },
                h("span", { className: "garage-meter-label" }, label),
                h("span", { className: "garage-meter-value" }, `${percent}%`),
            ),
            h(
                "div",
                { className: "garage-meter-track" },
                h("span", {
                    className: `garage-meter-fill is-${tone}`,
                    style: { width: `${percent}%` },
                }),
            ),
        );
    }

    function vehicleItem(vehicle, currentSelection) {
        const id =
            vehicle.entryKind === "stored"
                ? String(vehicle.plate || "")
                : String(vehicle.netId || "");
        const isNearby = vehicle.entryKind === "nearby";

        return h(
            "button",
            {
                type: "button",
                className: sameEntry(vehicle, currentSelection)
                    ? "garage-vehicle-item is-selected"
                    : "garage-vehicle-item",
                onClick: () => actions.selectEntry(vehicle.entryKind, id),
            },
            h(
                "div",
                { className: "garage-vehicle-item-head" },
                h(
                    "div",
                    { className: "garage-vehicle-copy" },
                    h(
                        "span",
                        { className: "garage-vehicle-title" },
                        vehicle.displayName || vehicle.classname || "Vehicle",
                    ),
                    h(
                        "span",
                        { className: "garage-vehicle-meta" },
                        isNearby
                            ? `Nearby ${distanceLabel(vehicle.distance)}`
                            : `Plate ${plateLabel(vehicle.plate)}`,
                    ),
                ),
                h(
                    "span",
                    {
                        className:
                            isNearby && vehicle.isEmpty === false
                                ? "garage-badge is-warning"
                                : "garage-badge",
                    },
                    isNearby
                        ? vehicle.isEmpty === false
                            ? "Crewed"
                            : "Empty"
                        : categoryLabel(vehicle.category),
                ),
            ),
            h(
                "div",
                { className: "garage-inline-meters" },
                meter("Health", pct(vehicle.health), "health"),
                meter("Fuel", pct(vehicle.fuel), "fuel"),
            ),
        );
    }

    function vehicleList(title, eyebrow, scrollId, vehicles, currentSelection) {
        return h(
            "section",
            { className: "garage-card garage-list-card" },
            h(
                "div",
                { className: "garage-card-header" },
                h(
                    "div",
                    null,
                    h("span", { className: "garage-eyebrow" }, eyebrow),
                    h("h2", { className: "garage-section-title" }, title),
                ),
                h(
                    "span",
                    { className: "garage-pill" },
                    `${vehicles.length} ${vehicles.length === 1 ? "Vehicle" : "Vehicles"}`,
                ),
            ),
            h(
                "div",
                {
                    className: "garage-card-body garage-scroll-body",
                    "data-preserve-scroll-id": scrollId,
                },
                vehicles.length > 0
                    ? vehicles.map((vehicle) =>
                          vehicleItem(vehicle, currentSelection),
                      )
                    : h(
                          "div",
                          { className: "garage-empty-state" },
                          h(
                              "h3",
                              { className: "garage-empty-title" },
                              "No matching vehicles",
                          ),
                          h(
                              "p",
                              { className: "garage-empty-copy" },
                              "Adjust the current search or category filter to view more records.",
                          ),
                      ),
            ),
        );
    }

    function hitPointRows(hitPoints) {
        const rows = (Array.isArray(hitPoints) ? hitPoints : [])
            .slice()
            .sort(
                (left, right) =>
                    Number(right.value || 0) - Number(left.value || 0),
            )
            .slice(0, 6)
            .filter((row) => Number(row.value || 0) > 0);

        if (rows.length === 0) {
            return h(
                "div",
                { className: "garage-empty-inline" },
                "No subsystem damage reported.",
            );
        }

        return h(
            "div",
            { className: "garage-hitpoint-grid" },
            rows.map((row) =>
                h(
                    "div",
                    { className: "garage-hitpoint-row" },
                    h(
                        "div",
                        { className: "garage-hitpoint-copy" },
                        h(
                            "span",
                            { className: "garage-hitpoint-name" },
                            normalizeHitPointLabel(row.name) || "Subsystem",
                        ),
                        row.selection
                            ? h(
                                  "span",
                                  { className: "garage-hitpoint-selection" },
                                  row.selection,
                              )
                            : null,
                    ),
                    h(
                        "span",
                        { className: "garage-hitpoint-value" },
                        `${Math.round(Number(row.value || 0) * 100)}%`,
                    ),
                ),
            ),
        );
    }

    function detailPanel(currentSelection, state) {
        if (!currentSelection) {
            return h(
                "section",
                { className: "garage-card garage-detail-card" },
                h(
                    "div",
                    { className: "garage-card-header" },
                    h(
                        "div",
                        null,
                        h("span", { className: "garage-eyebrow" }, "Selection"),
                        h(
                            "h2",
                            { className: "garage-section-title" },
                            "Vehicle Detail",
                        ),
                    ),
                ),
                h(
                    "div",
                    { className: "garage-card-body garage-detail-empty" },
                    h(
                        "h3",
                        { className: "garage-empty-title" },
                        "Select a vehicle",
                    ),
                    h(
                        "p",
                        { className: "garage-empty-copy" },
                        "Choose a stored record to retrieve or a nearby vehicle to store.",
                    ),
                ),
            );
        }

        const isStored = currentSelection.entryKind === "stored";
        const pendingAction = String(state.pendingAction || "");
        const isBusy = Boolean(pendingAction);
        const canRetrieve = isStored && !session.spawnBlocked && !isBusy;
        const canStore =
            !isStored && currentSelection.isEmpty !== false && !isBusy;
        const canRefuel =
            !isStored && Number(currentSelection.fuel || 0) < 0.999 && !isBusy;
        const canRepair =
            !isStored &&
            Number(currentSelection.health || 0) < 0.999 &&
            !isBusy;
        const canRearm = !isStored && !isBusy;

        return h(
            "section",
            { className: "garage-card garage-detail-card" },
            h(
                "div",
                { className: "garage-card-header" },
                h(
                    "div",
                    null,
                    h(
                        "span",
                        { className: "garage-eyebrow" },
                        isStored ? "Stored Record" : "Nearby Vehicle",
                    ),
                    h(
                        "h2",
                        { className: "garage-section-title" },
                        currentSelection.displayName ||
                            currentSelection.classname ||
                            "Vehicle",
                    ),
                ),
                h(
                    "span",
                    {
                        className:
                            currentSelection.entryKind === "nearby" &&
                            currentSelection.isEmpty === false
                                ? "garage-badge is-warning"
                                : "garage-badge",
                    },
                    isStored
                        ? `Plate ${plateLabel(currentSelection.plate)}`
                        : currentSelection.isEmpty === false
                          ? "Crewed"
                          : "Ready",
                ),
            ),
            h(
                "div",
                { className: "garage-card-body garage-detail-body" },
                h(
                    "div",
                    { className: "garage-detail-grid" },
                    h(
                        "div",
                        { className: "garage-detail-copy" },
                        h(
                            "div",
                            { className: "garage-detail-meta" },
                            stat(
                                "Category",
                                categoryLabel(currentSelection.category),
                            ),
                            stat(
                                "Status",
                                statusLabel(currentSelection),
                                currentSelection.entryKind === "nearby" &&
                                    currentSelection.isEmpty === false
                                    ? "danger"
                                    : "",
                            ),
                            stat(
                                isStored ? "Record" : "Distance",
                                isStored
                                    ? plateLabel(currentSelection.plate)
                                    : distanceLabel(currentSelection.distance),
                                isStored ? "" : "accent",
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-meter-stack" },
                            meter(
                                "Health",
                                pct(currentSelection.health),
                                "health",
                            ),
                            meter("Fuel", pct(currentSelection.fuel), "fuel"),
                        ),
                        h(
                            "div",
                            { className: "garage-action-row" },
                            isStored
                                ? h(
                                      "button",
                                      {
                                          type: "button",
                                          className:
                                              "garage-btn garage-btn-primary",
                                          disabled: !canRetrieve,
                                          onClick: () =>
                                              actions.requestRetrieveSelected(),
                                      },
                                      pendingAction === "retrieve"
                                          ? "Retrieving..."
                                          : "Retrieve Vehicle",
                                  )
                                : h(
                                      "button",
                                      {
                                          type: "button",
                                          className:
                                              "garage-btn garage-btn-primary",
                                          disabled: !canStore,
                                          onClick: () =>
                                              actions.requestStoreSelected(),
                                      },
                                      pendingAction === "store"
                                          ? "Storing..."
                                          : "Store Vehicle",
                                  ),
                            h(
                                "button",
                                {
                                    type: "button",
                                    className:
                                        "garage-btn garage-btn-secondary",
                                    disabled: !canRefuel,
                                    onClick: () =>
                                        actions.requestRefuelSelected(),
                                },
                                pendingAction === "refuel"
                                    ? "Refueling..."
                                    : "Refuel",
                            ),
                            h(
                                "button",
                                {
                                    type: "button",
                                    className:
                                        "garage-btn garage-btn-secondary",
                                    disabled: !canRepair,
                                    onClick: () =>
                                        actions.requestRepairSelected(),
                                },
                                pendingAction === "repair"
                                    ? "Repairing..."
                                    : "Repair",
                            ),
                            h(
                                "button",
                                {
                                    type: "button",
                                    className:
                                        "garage-btn garage-btn-secondary",
                                    disabled: !canRearm,
                                    onClick: () =>
                                        actions.requestRearmSelected(),
                                },
                                pendingAction === "rearm"
                                    ? "Rearming..."
                                    : "Rearm",
                            ),
                            h(
                                "button",
                                {
                                    type: "button",
                                    className:
                                        "garage-btn garage-btn-secondary garage-action-refresh",
                                    disabled: isBusy,
                                    onClick: () => actions.refreshGarage(),
                                },
                                "Refresh",
                            ),
                        ),
                        h(
                            "p",
                            { className: "garage-detail-note" },
                            isStored
                                ? session.spawnBlocked
                                    ? "The garage spawn lane is currently blocked."
                                    : "Retrieve this stored vehicle into the active spawn lane before refuel, rearm, or repair service."
                                : currentSelection.isEmpty === false
                                  ? "Only empty nearby vehicles can be stored."
                                  : "Store this nearby vehicle or request organization-billed refuel, rearm, and repair service.",
                        ),
                    ),
                    h(
                        "div",
                        { className: "garage-detail-subsystems" },
                        h(
                            "div",
                            { className: "garage-subsystem-header" },
                            h(
                                "span",
                                { className: "garage-eyebrow" },
                                "Subsystems",
                            ),
                            h(
                                "span",
                                { className: "garage-detail-caption" },
                                "Highest damage first",
                            ),
                        ),
                        hitPointRows(currentSelection.hitPoints),
                    ),
                ),
            ),
        );
    }

    GarageApp.components = GarageApp.components || {};
    GarageApp.components.App = function App() {
        const state = {
            categoryFilter: store.getCategoryFilter(),
            notice: store.getNotice(),
            pendingAction: store.getPendingAction(),
            searchQuery: store.getSearchQuery(),
            selectedId: store.getSelectedId(),
            selectedKind: store.getSelectedKind(),
        };
        const currentSelection = selectedEntry(state);
        const storedVehicles = visibleVehicles(garage.vehicles || [], state);
        const nearbyVehicles = visibleVehicles(nearby.vehicles || [], state);
        const searchLabel = state.searchQuery
            ? `Search: ${state.searchQuery}`
            : "Live";

        return h(
            "div",
            { className: "garage-shell" },
            WindowTitleBar({
                kicker: "FORGE Logistics",
                title: "Vehicle Garage",
                onClose: () => actions.closeGarage(),
                closeLabel: "Close garage interface",
            }),
            state.notice.text
                ? h(
                      "div",
                      { className: "garage-toast-stack" },
                      h(
                          "div",
                          {
                              className:
                                  state.notice.type === "error"
                                      ? "garage-toast is-error"
                                      : "garage-toast is-success",
                          },
                          state.notice.text,
                      ),
                  )
                : null,
            h(
                "div",
                { className: "garage-layout" },
                h(
                    "aside",
                    { className: "garage-sidebar" },
                    h(
                        "section",
                        { className: "garage-module" },
                        h(
                            "div",
                            { className: "garage-module-header" },
                            h(
                                "div",
                                null,
                                h(
                                    "span",
                                    { className: "garage-eyebrow" },
                                    "Search",
                                ),
                                h(
                                    "h2",
                                    { className: "garage-section-title" },
                                    "Vehicle Records",
                                ),
                            ),
                            h(
                                "span",
                                { className: "garage-pill" },
                                searchLabel,
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-search-form" },
                            h("input", {
                                id: "garage-search-input",
                                type: "text",
                                className: "garage-search-input",
                                placeholder:
                                    "Search by name, plate, or category",
                                value: state.searchQuery,
                            }),
                            h(
                                "div",
                                { className: "garage-search-actions" },
                                h(
                                    "button",
                                    {
                                        type: "button",
                                        className:
                                            "garage-btn garage-btn-primary",
                                        onClick: () =>
                                            actions.applySearchQuery(
                                                document.getElementById(
                                                    "garage-search-input",
                                                )?.value || "",
                                            ),
                                    },
                                    "Apply Search",
                                ),
                                h(
                                    "button",
                                    {
                                        type: "button",
                                        className:
                                            "garage-btn garage-btn-secondary",
                                        onClick: () => actions.clearSearch(),
                                    },
                                    "Clear",
                                ),
                            ),
                        ),
                    ),
                    h(
                        "section",
                        { className: "garage-module" },
                        h(
                            "div",
                            { className: "garage-module-header" },
                            h(
                                "div",
                                null,
                                h(
                                    "span",
                                    { className: "garage-eyebrow" },
                                    "Filter",
                                ),
                                h(
                                    "h2",
                                    { className: "garage-section-title" },
                                    "Vehicle Categories",
                                ),
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-category-grid" },
                            categories.map((category) =>
                                h(
                                    "button",
                                    {
                                        type: "button",
                                        className:
                                            state.categoryFilter === category.id
                                                ? "garage-chip is-active"
                                                : "garage-chip",
                                        onClick: () =>
                                            actions.selectCategory(category.id),
                                    },
                                    category.label,
                                ),
                            ),
                        ),
                    ),
                    h(
                        "section",
                        { className: "garage-module" },
                        h(
                            "div",
                            { className: "garage-module-header" },
                            h(
                                "div",
                                null,
                                h(
                                    "span",
                                    { className: "garage-eyebrow" },
                                    "Status",
                                ),
                                h(
                                    "h2",
                                    { className: "garage-section-title" },
                                    "Garage Summary",
                                ),
                            ),
                            h(
                                "button",
                                {
                                    type: "button",
                                    className:
                                        "garage-btn garage-btn-secondary",
                                    disabled: Boolean(state.pendingAction),
                                    onClick: () => actions.refreshGarage(),
                                },
                                "Refresh",
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-summary-grid" },
                            stat(
                                "Stored",
                                `${session.capacityUsed}/${session.capacityMax}`,
                            ),
                            stat("Nearby", session.nearbyCount, "accent"),
                            stat(
                                "Spawn Lane",
                                session.spawnStatus,
                                session.spawnBlocked ? "danger" : "",
                            ),
                        ),
                    ),
                ),
                h(
                    "main",
                    { className: "garage-main" },
                    h(
                        "section",
                        { className: "garage-panel" },
                        h(
                            "div",
                            { className: "garage-panel-header" },
                            h(
                                "div",
                                null,
                                h(
                                    "span",
                                    { className: "garage-eyebrow" },
                                    "Operations Bay",
                                ),
                                h(
                                    "h1",
                                    { className: "garage-title" },
                                    session.garageName || "Vehicle Garage",
                                ),
                            ),
                            h(
                                "span",
                                { className: "garage-pill" },
                                `${session.capacityUsed}/${session.capacityMax} Stored`,
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-panel-intro" },
                            h(
                                "p",
                                { className: "garage-copy" },
                                "Retrieve stored vehicles into the active spawn lane or store nearby empty vehicles back into persistent ownership records.",
                            ),
                        ),
                        h(
                            "div",
                            { className: "garage-dashboard" },
                            vehicleList(
                                "Stored Vehicles",
                                "Persistent Records",
                                "garage-stored-list",
                                storedVehicles,
                                currentSelection,
                            ),
                            vehicleList(
                                "Nearby Vehicles",
                                "Store Window",
                                "garage-nearby-list",
                                nearbyVehicles,
                                currentSelection,
                            ),
                            detailPanel(currentSelection, state),
                        ),
                    ),
                ),
            ),
            h(
                "footer",
                { className: "garage-footer-bar" },
                h(
                    "div",
                    { className: "garage-footer" },
                    h(
                        "div",
                        { className: "garage-footer-block" },
                        h(
                            "span",
                            { className: "garage-footer-title" },
                            "Storage Capacity",
                        ),
                        h(
                            "span",
                            { className: "garage-footer-copy" },
                            `${session.capacityUsed} of ${session.capacityMax} vehicle slot(s) are currently occupied.`,
                        ),
                    ),
                    h(
                        "div",
                        { className: "garage-footer-block" },
                        h(
                            "span",
                            { className: "garage-footer-title" },
                            "Retrieval Window",
                        ),
                        h(
                            "span",
                            { className: "garage-footer-copy" },
                            session.spawnBlocked
                                ? "Spawn lane is blocked. Clear the bay before retrieving another vehicle."
                                : "Spawn lane is clear. Stored vehicles can be retrieved immediately.",
                        ),
                    ),
                    h(
                        "div",
                        { className: "garage-footer-block" },
                        h(
                            "span",
                            { className: "garage-footer-title" },
                            "Store Rules",
                        ),
                        h(
                            "span",
                            { className: "garage-footer-copy" },
                            "Only nearby empty vehicles can be stored. Nearby count updates from the live world state.",
                        ),
                    ),
                ),
            ),
        );
    };
})();

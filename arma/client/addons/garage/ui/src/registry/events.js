(function () {
    const GarageApp = (window.GarageApp = window.GarageApp || {});
    const store = GarageApp.store;

    let noticeTimer = null;

    function getStoredVehicles() {
        return Array.isArray(GarageApp.data?.garage?.vehicles)
            ? GarageApp.data.garage.vehicles
            : [];
    }

    function getNearbyVehicles() {
        return Array.isArray(GarageApp.data?.nearby?.vehicles)
            ? GarageApp.data.nearby.vehicles
            : [];
    }

    function getSelectedEntry() {
        const selection = store.getSelection();
        if (selection.kind === "stored") {
            return (
                getStoredVehicles().find(
                    (vehicle) => String(vehicle.plate || "") === selection.id,
                ) || null
            );
        }

        if (selection.kind === "nearby") {
            return (
                getNearbyVehicles().find(
                    (vehicle) => String(vehicle.netId || "") === selection.id,
                ) || null
            );
        }

        return null;
    }

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

    function closeGarage() {
        const bridge = GarageApp.bridge;
        if (bridge && typeof bridge.requestClose === "function") {
            const sent = bridge.requestClose();
            if (sent) {
                return true;
            }
        }

        showNotice("error", "Garage bridge is unavailable.");
        return false;
    }

    function refreshGarage() {
        const bridge = GarageApp.bridge;
        if (bridge && typeof bridge.requestRefresh === "function") {
            const sent = bridge.requestRefresh();
            if (sent) {
                return true;
            }
        }

        showNotice("error", "Garage refresh bridge is unavailable.");
        return false;
    }

    function applySearchQuery(value) {
        store.setSearchQuery(String(value || "").trim());
    }

    function clearSearch() {
        store.setSearchQuery("");
    }

    function selectCategory(categoryId) {
        store.setCategoryFilter(String(categoryId || "all").trim() || "all");
    }

    function selectEntry(kind, id) {
        store.select(kind, id);
    }

    function requestRetrieveSelected() {
        const selectedEntry = getSelectedEntry();
        if (!selectedEntry || selectedEntry.entryKind !== "stored") {
            showNotice("error", "Select a stored vehicle to retrieve.");
            return false;
        }

        if (GarageApp.data?.session?.spawnBlocked) {
            showNotice("error", "The garage spawn area is blocked.");
            return false;
        }

        const bridge = GarageApp.bridge;
        if (!bridge || typeof bridge.requestRetrieve !== "function") {
            showNotice("error", "Garage retrieve bridge is unavailable.");
            return false;
        }

        store.startAction("retrieve");
        const sent = bridge.requestRetrieve({
            plate: selectedEntry.plate || "",
        });

        if (!sent) {
            store.finishAction();
            showNotice("error", "Garage retrieve bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestStoreSelected() {
        const selectedEntry = getSelectedEntry();
        if (!selectedEntry || selectedEntry.entryKind !== "nearby") {
            showNotice("error", "Select a nearby vehicle to store.");
            return false;
        }

        if (selectedEntry.isEmpty === false) {
            showNotice(
                "error",
                "All crew must exit the vehicle before storing it.",
            );
            return false;
        }

        const bridge = GarageApp.bridge;
        if (!bridge || typeof bridge.requestStore !== "function") {
            showNotice("error", "Garage store bridge is unavailable.");
            return false;
        }

        store.startAction("store");
        const sent = bridge.requestStore({
            netId: selectedEntry.netId || "",
        });

        if (!sent) {
            store.finishAction();
            showNotice("error", "Garage store bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestRefuelSelected() {
        const selectedEntry = getSelectedEntry();
        if (!selectedEntry || selectedEntry.entryKind !== "nearby") {
            showNotice("error", "Select a nearby vehicle to refuel.");
            return false;
        }

        if (Number(selectedEntry.fuel || 0) >= 0.999) {
            showNotice("error", "Vehicle fuel tank is already full.");
            return false;
        }

        const bridge = GarageApp.bridge;
        if (!bridge || typeof bridge.requestRefuel !== "function") {
            showNotice("error", "Garage refuel bridge is unavailable.");
            return false;
        }

        store.startAction("refuel");
        const sent = bridge.requestRefuel({
            netId: selectedEntry.netId || "",
        });

        if (!sent) {
            store.finishAction();
            showNotice("error", "Garage refuel bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestRepairSelected() {
        const selectedEntry = getSelectedEntry();
        if (!selectedEntry || selectedEntry.entryKind !== "nearby") {
            showNotice("error", "Select a nearby vehicle to repair.");
            return false;
        }

        if (Number(selectedEntry.health || 0) >= 0.999) {
            showNotice("error", "Vehicle has no reported damage.");
            return false;
        }

        const bridge = GarageApp.bridge;
        if (!bridge || typeof bridge.requestRepair !== "function") {
            showNotice("error", "Garage repair bridge is unavailable.");
            return false;
        }

        store.startAction("repair");
        const sent = bridge.requestRepair({
            netId: selectedEntry.netId || "",
        });

        if (!sent) {
            store.finishAction();
            showNotice("error", "Garage repair bridge is unavailable.");
            return false;
        }

        return true;
    }

    function requestRearmSelected() {
        const selectedEntry = getSelectedEntry();
        if (!selectedEntry || selectedEntry.entryKind !== "nearby") {
            showNotice("error", "Select a nearby vehicle to rearm.");
            return false;
        }

        const bridge = GarageApp.bridge;
        if (!bridge || typeof bridge.requestRearm !== "function") {
            showNotice("error", "Garage rearm bridge is unavailable.");
            return false;
        }

        store.startAction("rearm");
        const sent = bridge.requestRearm({
            netId: selectedEntry.netId || "",
        });

        if (!sent) {
            store.finishAction();
            showNotice("error", "Garage rearm bridge is unavailable.");
            return false;
        }

        return true;
    }

    GarageApp.actions = {
        showNotice,
        closeGarage,
        refreshGarage,
        applySearchQuery,
        clearSearch,
        selectCategory,
        selectEntry,
        getSelectedEntry,
        requestRearmSelected,
        requestRefuelSelected,
        requestRepairSelected,
        requestRetrieveSelected,
        requestStoreSelected,
    };
})();

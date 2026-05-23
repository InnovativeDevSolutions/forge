(function () {
    const GarageApp = (window.GarageApp = window.GarageApp || {});
    const { createSignal } = GarageApp.runtime;

    class GarageStore {
        constructor() {
            [this.getSelectedKind, this.setSelectedKind] = createSignal("");
            [this.getSelectedId, this.setSelectedId] = createSignal("");
            [this.getSearchQuery, this.setSearchQuery] = createSignal("");
            [this.getCategoryFilter, this.setCategoryFilter] =
                createSignal("all");
            [this.getPendingAction, this.setPendingAction] = createSignal("");
            [this.getNotice, this.setNotice] = createSignal({
                type: "",
                text: "",
            });
        }

        getSelection() {
            return {
                id: this.getSelectedId(),
                kind: this.getSelectedKind(),
            };
        }

        clearSelection() {
            this.setSelectedKind("");
            this.setSelectedId("");
        }

        select(kind, id) {
            this.setSelectedKind(String(kind || ""));
            this.setSelectedId(String(id || ""));
        }

        startAction(action) {
            this.setPendingAction(String(action || ""));
        }

        finishAction() {
            this.setPendingAction("");
        }

        matchesSelection(entry) {
            if (!entry || typeof entry !== "object") {
                return false;
            }

            const selection = this.getSelection();
            if (!selection.kind || !selection.id) {
                return false;
            }

            if (selection.kind === "stored") {
                return (
                    entry.entryKind === "stored" &&
                    String(entry.plate || "") === selection.id
                );
            }

            if (selection.kind === "nearby") {
                return (
                    entry.entryKind === "nearby" &&
                    String(entry.netId || "") === selection.id
                );
            }

            return false;
        }

        ensureSelection() {
            const garageVehicles = Array.isArray(
                GarageApp.data?.garage?.vehicles,
            )
                ? GarageApp.data.garage.vehicles
                : [];
            const nearbyVehicles = Array.isArray(
                GarageApp.data?.nearby?.vehicles,
            )
                ? GarageApp.data.nearby.vehicles
                : [];
            const hasCurrentSelection = [
                ...garageVehicles,
                ...nearbyVehicles,
            ].some((entry) => this.matchesSelection(entry));

            if (hasCurrentSelection) {
                return;
            }

            const firstStored = garageVehicles[0] || null;
            if (firstStored) {
                this.select("stored", firstStored.plate || "");
                return;
            }

            const firstNearby = nearbyVehicles[0] || null;
            if (firstNearby) {
                this.select("nearby", firstNearby.netId || "");
                return;
            }

            this.clearSelection();
        }

        hydrateFromPayload() {
            this.finishAction();
            this.ensureSelection();
        }
    }

    GarageApp.store = new GarageStore();
})();

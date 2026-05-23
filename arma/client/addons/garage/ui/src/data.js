(function () {
    const GarageApp = (window.GarageApp = window.GarageApp || {});

    const defaultSession = {
        garageName: "Vehicle Garage",
        capacityUsed: 0,
        capacityMax: 5,
        nearbyCount: 0,
        spawnBlocked: false,
        spawnStatus: "Ready",
    };

    const defaultGarage = {
        vehicles: [],
    };

    const defaultNearby = {
        vehicles: [],
    };

    function cloneValue(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function replaceObject(target, source) {
        Object.keys(target).forEach((key) => delete target[key]);
        Object.assign(target, cloneValue(source));
    }

    GarageApp.data = {
        categories: [
            { id: "all", label: "All" },
            { id: "car", label: "Cars" },
            { id: "armor", label: "Armor" },
            { id: "air", label: "Air" },
            { id: "naval", label: "Naval" },
            { id: "other", label: "Other" },
        ],
        session: Object.assign({}, defaultSession),
        garage: Object.assign({}, defaultGarage),
        nearby: Object.assign({}, defaultNearby),
        applyHydratePayload(payload) {
            replaceObject(
                this.session,
                Object.assign({}, defaultSession, payload?.session || {}),
            );
            replaceObject(
                this.garage,
                Object.assign({}, defaultGarage, payload?.garage || {}),
            );
            replaceObject(
                this.nearby,
                Object.assign({}, defaultNearby, payload?.nearby || {}),
            );
        },
    };
})();

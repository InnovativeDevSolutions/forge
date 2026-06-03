/*
 * Forge store catalog filter.
 *
 * The server store catalog is generated from loaded Arma config classes, then
 * this mission config is applied as an optional filter and override layer.
 *
 * mode options:
 * - dynamic: keep the generated catalog for every category.
 * - allowlist: only show classnames listed under Categories.<category>[].
 * - denylist: show the generated catalog except classnames listed under
 *   Categories.<category>[].
 *
 * Per-store/vendor profiles are intentionally not implemented yet. Revisit
 * profile support if individual vendors need different inventories.
 */
class CfgStore {
    mode = "dynamic";

    class Categories {
        uniforms[] = {};
        headgear[] = {};
        vests[] = {};
        backpacks[] = {};
        attachments[] = {};
        facewear[] = {};
        ammo[] = {};
        misc[] = {};
        primary[] = {};
        handgun[] = {};
        secondary[] = {};
        cars[] = {};
        armor[] = {};
        helis[] = {};
        planes[] = {};
        naval[] = {};
        other[] = {};
        units[] = {};
    };

    class Overrides {
        /*
        class arifle_MX_F {
            price = 2500;
            displayName = "MX Rifle";
            description = "Approved PMC service rifle.";
        };
        */
    };
};

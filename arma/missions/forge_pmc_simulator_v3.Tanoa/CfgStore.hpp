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
 * modMode options:
 * - dynamic: do not filter by mod source.
 * - allowlist: only show generated entries that match one of mods[].
 * - denylist: hide generated entries that match one of mods[].
 *
 * ModSources supports:
 * - patches[]: CfgPatches classes used to detect whether the mod is loaded.
 * - addons[]: config source addon/source mod names or classname prefixes.
 * - prefixes[]: classname prefixes.
 *
 * Per-store/vendor profiles are intentionally not implemented yet. Revisit
 * profile support if individual vendors need different inventories.
 */
class CfgStore {
    mode = "dynamic";
    modMode = "dynamic";
    mods[] = {};

    class ModSources {
        class ace3 {
            patches[] = {"ace_main"};
            addons[] = {"ace_"};
            prefixes[] = {"ace_"};
        };

        class rhs {
            patches[] = {"rhs_main", "rhsusf_main"};
            addons[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
            prefixes[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
        };

        class tfar {
            patches[] = {"task_force_radio"};
            addons[] = {"tfar_", "tf_"};
            prefixes[] = {"tfar_", "tf_"};
        };

        class ef {
            patches[] = {"EF_Data"};
            addons[] = {"ef_"};
            prefixes[] = {"ef_"};
        };

        class rf {
            patches[] = {"lxRF_Data"};
            addons[] = {"lxrf_", "rf_"};
            prefixes[] = {"lxrf_", "rf_"};
        };

        class ws {
            patches[] = {"lxWS_Data"};
            addons[] = {"lxws_", "ws_"};
            prefixes[] = {"lxws_", "ws_"};
        };
    };

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

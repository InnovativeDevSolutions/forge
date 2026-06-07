/*
 * Forge store catalog filter.
 *
 * The server store catalog is generated from loaded Arma config classes, then
 * this mission config is applied as an optional filter and override layer.
 *
 * mode options:
 * - dynamic: keep the generated catalog for categories with empty arrays.
 * - allowlist: hide categories with empty arrays.
 * - denylist: reserved for global deny behavior when category arrays are empty.
 *
 * Non-empty Categories.<category>[] arrays always act as explicit per-category
 * allowlists after the mod filter, regardless of mode. Unit catalog responses
 * are also filtered to the requesting player's side and include side/faction
 * metadata for display.
 *
 * modMode options:
 * - dynamic: do not filter by mod source.
 * - allowlist: only show generated entries that match one of mods[].
 * - denylist: hide generated entries that match one of mods[].
 *
 * ModSources supports:
 * - patches[]: CfgPatches classes used to detect whether the mod is loaded.
 * - addons[]: exact config source addon/source mod names.
 * - prefixes[]: classname, source addon, or source mod prefixes.
 * - contains[]: classname/source metadata tokens that can appear anywhere.
 * - dlcs[]: DLC/source/author labels used by Creator DLC content.
 *
 * Per-store/vendor profiles are intentionally not implemented yet. Revisit
 * profile support if individual vendors need different inventories.
 */
class CfgStore {
    mode = "dynamic";
    modMode = "allowlist";
    mods[] = {"a3", "rf", "ws", "ace3"};

    class ModSources {
        class a3 {
            patches[] = {};
            addons[] = {"a3_"};
            prefixes[] = {"a3_"};
            contains[] = {};
            dlcs[] = {};
        };

        class ace3 {
            patches[] = {"ace_main"};
            addons[] = {"ace_"};
            prefixes[] = {"ace_", "ace3_"};
            contains[] = {"ace_", "ace3_"};
            dlcs[] = {};
        };

        class rhs {
            patches[] = {"rhs_main", "rhsusf_main"};
            addons[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
            prefixes[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
            contains[] = {"rhs_", "rhsusf_", "rhsgref_", "rhsafrf_"};
            dlcs[] = {};
        };

        class tfar {
            patches[] = {"task_force_radio"};
            addons[] = {"tfar_", "tf_"};
            prefixes[] = {"tfar_", "tf_"};
            contains[] = {"tfar_", "tf_"};
            dlcs[] = {};
        };

        class ef {
            patches[] = {};
            addons[] = {"ef_"};
            prefixes[] = {"ef_"};
            contains[] = {"_ef_", "_ef", "ef_"};
            dlcs[] = {"ef", "expeditionaryforces", "expeditionary forces"};
        };

        class rf {
            patches[] = {};
            addons[] = {"lxrf_", "rf_"};
            prefixes[] = {"lxrf_", "rf_"};
            contains[] = {"lxrf", "_lxrf_", "_lxrf", "lxrf_", "_rf_", "_rf", "rf_"};
            dlcs[] = {"rf", "reactionforces", "reaction forces"};
        };

        class ws {
            patches[] = {};
            addons[] = {"lxws_", "ws_"};
            prefixes[] = {"lxws_", "ws_"};
            contains[] = {"lxws", "_lxws_", "_lxws", "lxws_", "_ws_", "_ws", "ws_"};
            dlcs[] = {"ws", "lxws", "westernsahara", "western sahara"};
        };

        class vn {
            patches[] = {};
            addons[] = {"vn_", "vn_data_f_vietnam"};
            prefixes[] = {"vn_"};
            contains[] = {"_vn_", "_vn", "vn_"};
            dlcs[] = {"vn", "vietnam", "prairiefire", "sog prairiefire", "sog prairie fire"};
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

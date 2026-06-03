/*
 * Forge starting equipment and unlocks.
 *
 * Include this file from description.ext to override the framework defaults
 * without recompiling the server addon or extension.
 */
class CfgStartingEquipment {
    loadout[] = {
        {},
        {},
        {"hgun_P07_F", "", "", "", ["16Rnd_9x21_Mag", 17], [], ""},
        {"U_BG_Guerrilla_6_1", {{"FirstAidKit", 2}, {"ACE_EarPlugs", 1}}},
        {"V_Rangemaster_belt", {{"16Rnd_9x21_Mag", 4}}},
        {},
        "H_Cap_blk_ION",
        "",
        {"Binocular", "", "", "", [], [], ""},
        {"ItemMap", "ItemGPS", "ItemRadio", "ItemCompass", "ItemWatch", ""}
    };

    class Unlocks {
        class Locker {
            items[] = {
                "FirstAidKit",
                "G_Combat",
                "H_Cap_blk_ION",
                "H_HelmetB",
                "ItemCompass",
                "ItemGPS",
                "ItemMap",
                "ItemRadio",
                "ItemWatch",
                "NVGoggles",
                "U_BG_Guerrilla_6_1",
                "V_Rangemaster_belt",
                "V_TacVest_oli",
                "ACE_EarPlugs"
            };
            weapons[] = {
                "arifle_MX_F",
                "hgun_P07_F",
                "Binocular"
            };
            magazines[] = {
                "16Rnd_9x21_Mag",
                "30Rnd_65x39_caseless_black_mag",
                "Chemlight_blue",
                "Chemlight_green",
                "Chemlight_red",
                "Chemlight_yellow",
                "HandGrenade",
                "SmokeShell",
                "SmokeShellBlue",
                "SmokeShellGreen",
                "SmokeShellOrange",
                "SmokeShellPurple",
                "SmokeShellRed",
                "SmokeShellYellow"
            };
            backpacks[] = {
                "B_AssaultPack_rgr"
            };
        };

        class Garage {
            cars[] = {
                "B_Quadbike_01_F"
            };
            armor[] = {};
            helis[] = {};
            planes[] = {};
            naval[] = {};
            other[] = {};
        };
    };
};

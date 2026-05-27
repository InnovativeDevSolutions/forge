/*
 * PMC simulator dynamic mission configuration.
 *
 * This file is read by the mission setup UI, the mission manager, and the
 * mission generators under functions\missionGenerators.
 *
 * Startup UI behavior:
 * - Arma mission params/defaults provide the startup setup UI defaults.
 * - If the setup UI is cancelled, those same params/defaults are applied.
 * - If the setup UI is submitted, UI values override compatible ranges.
 *
 * Generator behavior:
 * - maxConcurrentMissions and missionInterval are copied into
 *   forge_pmc_missionSettings by forge_pmc_fnc_setupMenu_applySettings.
 * - Reward, reputation, penalty, and timeLimit ranges are read through
 *   forge_pmc_fnc_getMissionSettingRange so UI overrides and config fallbacks
 *   use the same path.
 */
class CfgMissions {
    // Maximum number of generated missions allowed to be active at once.
    maxConcurrentMissions = 3;

    // Seconds between mission generation attempts.
    missionInterval = 300;

    // Seconds before a generated mission location can be reused.
    locationReuseCooldown = 900;

    // Enemy faction selection is ultimately exported to ENEMY_FACTION_STR and
    // ENEMY_SIDE for server-side generators.
    class EnemyFactionConfig {
        // Mission param key used by fallback/default setup application.
        enemyFactionParam = "enemyFaction";
    };

    // Relative generation weights. The values do not need to add to 1; the
    // mission manager treats them as weighted proportions.
    class MissionWeights {
        attack = 0.2;
        defend = 0.2;
        hostage = 0.2;
        hvtkill = 0.15;
        hvtcapture = 0.15;
        defuse = 0.15;
        delivery = 0.1;
        destroy = 0.2;
    };

    /*
     * Mission type settings.
     *
     * Common fields:
     * - Rewards.money[]: min/max funds reward.
     * - Rewards.reputation[]: min/max reputation reward.
     * - Rewards.<category>[]: item reward rolls as {classname, chance}.
     * - penalty[]: numeric min/max reputation penalty on failure. UI settings
     *   may express these as min/max reputation hits, then the helper sorts the
     *   numeric roll range before generators use it.
     * - timeLimit[]: min/max task time limit in seconds.
     */
    class MissionTypes {
        // Search-and-destroy infantry engagement.
        class Attack {
            minUnits = 4;
            maxUnits = 8;
            class Rewards {
                money[] = {25000, 60000};
                reputation[] = {6, 14};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-8, -3};
            timeLimit[] = {900, 1800};
        };

        // Hold a generated position through multiple enemy waves.
        class Defend {
            minWaves = 3;
            maxWaves = 8;
            // Min/max units spawned per wave before active-player scaling.
            unitsPerWave[] = {4, 8};
            // Seconds between wave spawns.
            waveCooldown = 300;
            class Rewards {
                money[] = {40000, 90000};
                reputation[] = {8, 18};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-12, -4};
            timeLimit[] = {300, 1800};
        };

        // Rescue a hostage from a generated hostile site.
        class Hostage {
            // Candidate hostage classnames by broad source category.
            class Hostages {
                civilian[] = {"C_journalist_F", "C_Journalist_01_War_F", "C_Man_Paramedic_01_F", "C_scientist_F", "C_IDAP_Pilot_RF", "C_IDAP_Man_Paramedic_01_F", "C_IDAP_Pilot_01_F", "C_IDAP_Man_AidWorker_01_F", "C_IDAP_Man_AidWorker_05_F", "C_pilot_story_RF", "C_pilot2_story_RF", "C_Orestes", "C_Nikos", "C_Journalist_lxWS"};
                military[] = {"B_helicrew_F", "B_Helipilot_F", "B_officer_F", "B_Fighter_Pilot_F", "B_Captain_Jay_F", "B_CTRG_soldier_M_medic_F", "B_Story_Pilot_F", "B_CTRG_soldier_GL_LAT_F", "B_Captain_Pettka_F", "B_Survivor_F", "B_Pilot_F"};
            };
            class Rewards {
                money[] = {60000, 140000};
                reputation[] = {12, 25};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-16, -6};
            timeLimit[] = {600, 900};
        };

        // Eliminate a high-value target with escort security.
        class HVTKill {
            // Candidate target classnames by role.
            class Targets {
                officer[] = {"O_officer_F"};
                sniper[] = {"O_sniper_F"};
            };
            // Number of escort units to attempt around the target.
            escorts = 4;
            class Rewards {
                money[] = {50000, 120000};
                reputation[] = {10, 22};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-14, -5};
            timeLimit[] = {900, 1800};
        };

        // Capture and extract a high-value target.
        class HVTCapture {
            // Candidate capturable target classnames.
            class Targets {
                civilian[] = {"C_journalist_F", "C_Journalist_01_War_F", "C_Man_Paramedic_01_F", "C_scientist_F", "C_IDAP_Pilot_RF", "C_IDAP_Man_Paramedic_01_F", "C_IDAP_Pilot_01_F", "C_IDAP_Man_AidWorker_01_F", "C_IDAP_Man_AidWorker_05_F", "C_pilot_story_RF", "C_pilot2_story_RF", "C_Orestes", "C_Nikos", "C_Journalist_lxWS"};
            };
            // Number of escort units to attempt around the target.
            escorts = 4;
            class Rewards {
                money[] = {50000, 120000};
                reputation[] = {10, 22};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-14, -5};
            timeLimit[] = {900, 1800};
        };

        // Defuse explosive devices and protect nearby critical objects.
        class Defuse {
            // Device and protected-object candidate classnames.
            class Devices {
                small[] = {"DemoCharge_F", "IEDLandSmall_F", "IEDUrbanSmall_F", "ACE_IEDLandSmall_Range", "ACE_IEDUrbanSmall_Range"};
                large[] = {"SatchelCharge_F", "IEDLandBig_F", "IEDUrbanBig_F", "ACE_IEDLandBig_Range", "ACE_IEDUrbanBig_Range"};
                protected[] = {"CargoNet_01_barrels_F", "CargoNet_01_box_F", "B_CargoNet_01_ammo_F", "C_IDAP_CargoNet_01_supplies_F", "Box_NATO_AmmoVeh_F", "B_supplyCrate_F"};
            };
            // Maximum explosive devices to place for one generated task.
            maxDevices = 1;
            class Rewards {
                money[] = {20000, 50000};
                reputation[] = {5, 12};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-9, -3};
            timeLimit[] = {600, 900};
        };

        // Deliver cargo or vehicles between generated locations.
        class Delivery {
            // Candidate delivery objects grouped by cargo type.
            class Cargo {
                supplies[] = {"CargoNet_01_barrels_F", "CargoNet_01_box_F", "B_CargoNet_01_ammo_F", "C_IDAP_CargoNet_01_supplies_F", "Box_NATO_AmmoVeh_F", "B_supplyCrate_F"};
                vehicles[] = {};
            };
            class Rewards {
                money[] = {10000, 30000};
                reputation[] = {3, 8};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-6, -2};
            timeLimit[] = {0, 0};
        };

        // Destroy generated infrastructure targets.
        class Destroy {
            // Candidate destructible target classnames.
            class Bomb {
                building[] = {"Land_Radar_F", "Land_Radar_Small_F", "Land_MobileRadar_01_radar_F", "Land_MobileRadar_01_generator_F", "Land_Communication_F", "Land_spp_Tower_F", "Land_TTowerSmall_1_F", "Land_TTowerSmall_2_F", "Land_TTowerBig_1_F", "Land_TTowerBig_2_F"};
            };
            class Rewards {
                money[] = {10000, 30000};
                reputation[] = {3, 8};
                equipment[] = {{"ItemGPS", 0.5}, {"ItemCompass", 0.3}};
                supplies[] = {{"FirstAidKit", 0.2}, {"Medikit", 0.1}};
                weapons[] = {{"arifle_MX_F", 0.3}, {"arifle_Katiba_F", 0.2}};
                vehicles[] = {{"B_MRAP_01_F", 0.1}, {"B_APC_Wheeled_01_cannon_F", 0.05}};
                special[] = {{"B_UAV_01_F", 0.05}, {"B_Heli_Light_01_F", 0.02}};
            };
            penalty[] = {-6, -2};
            timeLimit[] = {900, 1800};
        };
    };
};

// TODO: Move to mission template and provide documentation
class CfgMissions {
    // Global settings
    maxConcurrentMissions = 3;
    missionInterval = 300; // 5 minutes between mission generation
    
    // Mission type weights
    class MissionWeights {
        attack = 0.2;
        defend = 0.2;
        hostage = 0.2;
        hvt = 0.15;
        defuse = 0.15;
        delivery = 0.1;
    };

    // Mission locations
    class Locations {
        class CityOne {
            position[] = {1000, 1000, 0};
            type = "city";
            radius = 300;
            suitable[] = {"attack", "defend", "hostage"};
        };
        class MilitaryBase {
            position[] = {2000, 2000, 0};
            type = "military";
            radius = 500;
            suitable[] = {"hvt", "defend", "attack"};
        };
        class Industrial {
            position[] = {3000, 3000, 0};
            type = "industrial";
            radius = 200;
            suitable[] = {"delivery", "defuse"};
        };
    };

    // AI Groups configuration
    class AIGroups {
        class Infantry {
            side = "EAST";
            class Units {
                class Unit0 {
                    vehicle = "O_Soldier_TL_F";
                    rank = "SERGEANT";
                    position[] = {0, 0, 0};
                };
                class Unit1 {
                    vehicle = "O_Soldier_AR_F";
                    rank = "CORPORAL";
                    position[] = {5, -5, 0};
                };
                class Unit2 {
                    vehicle = "O_Soldier_LAT_F";
                    rank = "PRIVATE";
                    position[] = {-5, -5, 0};
                };
            };
            suitable[] = {"attack", "defend", "hostage"};
        };
        class Assault {
            side = "EAST";
            class Units {
                class Unit0 {
                    vehicle = "O_Soldier_SL_F";
                    rank = "SERGEANT";
                    position[] = {0, 0, 0};
                };
                class Unit1 {
                    vehicle = "O_Soldier_GL_F";
                    rank = "CORPORAL";
                    position[] = {4, -3, 0};
                };
                class Unit2 {
                    vehicle = "O_Soldier_AR_F";
                    rank = "CORPORAL";
                    position[] = {-4, -3, 0};
                };
                class Unit3 {
                    vehicle = "O_medic_F";
                    rank = "PRIVATE";
                    position[] = {7, -6, 0};
                };
            };
            suitable[] = {"attack", "defend"};
        };
        class MotorizedPatrol {
            side = "EAST";
            class Units {
                class Unit0 {
                    vehicle = "O_Soldier_TL_F";
                    rank = "SERGEANT";
                    position[] = {0, 0, 0};
                };
                class Unit1 {
                    vehicle = "O_Soldier_LAT_F";
                    rank = "CORPORAL";
                    position[] = {5, -4, 0};
                };
                class Unit2 {
                    vehicle = "O_Soldier_F";
                    rank = "PRIVATE";
                    position[] = {-5, -4, 0};
                };
                class Unit3 {
                    vehicle = "O_Soldier_A_F";
                    rank = "PRIVATE";
                    position[] = {8, -7, 0};
                };
            };
            suitable[] = {"attack", "defend"};
        };
        class SpecOps {
            side = "EAST";
            class Units {
                class Unit0 {
                    vehicle = "O_recon_TL_F";
                    rank = "SERGEANT";
                    position[] = {0, 0, 0};
                };
                class Unit1 {
                    vehicle = "O_recon_M_F";
                    rank = "CORPORAL";
                    position[] = {5, -5, 0};
                };
            };
            suitable[] = {"hvt", "hostage"};
        };
        class ReconRaid {
            side = "EAST";
            class Units {
                class Unit0 {
                    vehicle = "O_recon_TL_F";
                    rank = "SERGEANT";
                    position[] = {0, 0, 0};
                };
                class Unit1 {
                    vehicle = "O_recon_M_F";
                    rank = "CORPORAL";
                    position[] = {4, -4, 0};
                };
                class Unit2 {
                    vehicle = "O_recon_LAT_F";
                    rank = "CORPORAL";
                    position[] = {-4, -4, 0};
                };
                class Unit3 {
                    vehicle = "O_recon_medic_F";
                    rank = "PRIVATE";
                    position[] = {7, -7, 0};
                };
            };
            suitable[] = {"attack", "hvt", "hostage"};
        };
    };

    // TODO: Continue to refine mission types and their specific settings
    // Mission type specific settings
    class MissionTypes {
        class Attack {
            minUnits = 4;
            maxUnits = 8;
            patrolRadius = 200;
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
            timeLimit[] = {900, 1800}; // 15-30 minutes
        };
        
        class Defend {
            minWaves = 3;
            maxWaves = 8;
            unitsPerWave[] = {4, 8};
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
            timeLimit[] = {1800, 3600}; // 30-60 minutes
        };
        
        class Hostage {
            class Hostages {
                civilian[] = {"C_man_1", "C_man_polo_1_F"};
                military[] = {"B_Pilot_F", "B_officer_F"};
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
            timeLimit[] = {600, 900}; // 10-15 minutes
        };

        class HVT {
            class Targets {
                officer[] = {"O_officer_F"};
                sniper[] = {"O_sniper_F"};
            };
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
            timeLimit[] = {900, 1800}; // 15-30 minutes
        };

        class Defuse {
            class Devices {
                small[] = {"DemoCharge_Remote_Mag"};
                large[] = {"SatchelCharge_Remote_Mag"};
            };
            maxDevices = 3;
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
            timeLimit[] = {600, 900}; // 10-15 minutes
        };

        class Delivery {
            class Cargo {
                supplies[] = {"Land_CargoBox_V1_F"};
                vehicles[] = {"B_MRAP_01_F", "B_Truck_01_transport_F"};
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
            timeLimit[] = {900, 1800}; // 15-30 minutes
        };
    };
};

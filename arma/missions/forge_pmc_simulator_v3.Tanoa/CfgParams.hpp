/*
 * Mission lobby fallback params.
 *
 * The startup setup UI now discovers selectable factions dynamically from the
 * active modset. Params remain intentionally static because Arma evaluates
 * them before mission runtime scripts can scan loaded factions. If the setup UI
 * is cancelled or never opened, these values provide the default fallback.
 */
class Params {
    class enemyFaction {
        title = "Enemy Faction";
        values[] = {0,1,2,3,4,5,6,7,8,9,10};
        texts[] = {
            "CSAT",
            "CSAT (Pacific)",
            "Spetnaz",
            "SFIA (OPFOR)",
            "Tura (OPFOR)",
            "AAF",
            "FIA",
            "LDF",
            "Syndikat",
            "Looters",
            "Tura (Independent)"
        };
        default = 6;
    };

    class maxConcurrentMissions {
        title = "Max Concurrent Missions";
        values[] = {1,2,3,4,5};
        default = 3;
    };

    class missionInterval {
        title = "Mission Interval (seconds)";
        values[] = {60,120,300,600,900};
        default = 300;
    };

    class moneyMin {
        title = "Money Min";
        values[] = {0,500,1000,5000};
        default = 500;
    };

    class moneyMax {
        title = "Money Max";
        values[] = {500,1000,5000,10000};
        default = 1000;
    };

    class reputationMin {
        title = "Reputation Min";
        values[] = {0,10,15,20,25,30};
        default = 25;
    };

    class reputationMax {
        title = "Reputation Max";
        values[] = {50,75,100,125,150};
        default = 100;
    };

    class penaltyMin {
        title = "Min Reputation Hit";
        values[] = {-20,-15,-10,-5,-3};
        default = -5;
    };

    class penaltyMax {
        title = "Max Reputation Hit";
        values[] = {-25,-20,-15,-10,-5};
        default = -25;
    };

    class timeLimitMin {
        title = "Time Limit Min (seconds, 0 = no limit)";
        values[] = {0,300,600,900,1200};
        default = 600;
    };

    class timeLimitMax {
        title = "Time Limit Max (seconds, 0 = no limit)";
        values[] = {0,600,900,1200,1800};
        default = 900;
    };

    class medicalSpawnCost {
        title = "Medical Spawn Cost";
        values[] = {0,100,250,500,1000};
        default = 100;
    };

    class medicalHealCost {
        title = "Medical Heal Cost";
        values[] = {0,100,250,500,1000};
        default = 100;
    };

    class serviceRepairCost {
        title = "Repair Service Cost";
        values[] = {0,250,500,1000,2500,5000};
        default = 500;
    };

    class serviceRearmCost {
        title = "Rearm Service Cost";
        values[] = {0,250,500,1000,2500,5000};
        default = 500;
    };

    class fuelCost {
        title = "Fuel Cost Per Liter";
        values[] = {0,1,2,5,10,25};
        default = 5;
    };

    class transportBaseFare {
        title = "Transport Base Fare";
        values[] = {0,50,100,250,500,1000};
        default = 100;
    };

    class transportPricePerKm {
        title = "Transport Price Per KM";
        values[] = {0,25,50,75,100,250};
        default = 50;
    };
};

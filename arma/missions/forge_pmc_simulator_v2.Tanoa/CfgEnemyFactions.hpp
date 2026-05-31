/*
 * Runtime enemy faction discovery controls for the PMC simulator setup flow.
 *
 * Consumers:
 * - The framework mission setup UI scans loaded CfgFactionClasses and
 *   CfgVehicles at runtime, then uses this config to filter and polish the UI.
 * - Override values here keep legacy mission params compatible when the setup
 *   UI is cancelled.
 * - Mission generators use ENEMY_FACTION_STR and ENEMY_SIDE after setup has
 *   applied the selected option.
 *
 * This config is intentionally not the full faction list. Any loaded mod
 * faction on an allowed side can appear automatically if it has spawnable
 * infantry or a CfgFactionUnitMap override.
 */
class CfgEnemyFactions {
    /*
     * Arma side IDs allowed as generated enemy factions:
     * - 0: EAST / OPFOR
     * - 2: RESISTANCE / Independent
     *
     * WEST / BLUFOR is intentionally excluded because generated missions use
     * these options as opposing forces.
     */
    sides[] = {0, 2};

    /*
     * Factions that should never be offered even if present in the active
     * modset. Keep this for factions that are unsuitable for PMC contracts.
     */
    denylist[] = {
        "IND_UN_lxWS"
    };

    /*
     * Optional display/order/value metadata for known factions.
     *
     * - value keeps legacy Params::enemyFaction values stable.
     * - order controls setup UI ordering before dynamically discovered factions.
     * - display overrides raw CfgFactionClasses names when we want cleaner text.
     *
     * Factions not listed here are still discovered automatically and sorted
     * after these known options.
     */
    class Overrides {
        class OPF_F { value = 0; order = 0; display = "CSAT"; };
        class OPF_T_F { value = 1; order = 1; display = "CSAT (Pacific)"; };
        class OPF_R_F { value = 2; order = 2; display = "Spetnaz"; };
        class OPF_SFIA_lxWS { value = 3; order = 3; display = "SFIA"; };
        class OPF_TURA_lxWS { value = 4; order = 4; display = "Tura"; };
        class IND_F { value = 5; order = 5; display = "AAF"; };
        class IND_G_F { value = 6; order = 6; display = "FIA"; };
        class IND_E_F { value = 7; order = 7; display = "LDF"; };
        class IND_C_F { value = 8; order = 8; display = "Syndikat"; };
        class IND_L_F { value = 9; order = 9; display = "Looters"; };
        class IND_TURA_lxWS { value = 10; order = 10; display = "Tura"; };
    };
};

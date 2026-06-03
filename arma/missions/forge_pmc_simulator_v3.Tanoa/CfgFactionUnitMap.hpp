/*
 * Optional faction-to-unit override map.
 *
 * Current behavior:
 * - The framework mission setup UI treats a mapped faction as selectable when
 *   at least one mapped vehicle exists.
 * - Framework task generators check this map first.
 * - If a selected faction has a class here, the listed Units are used as the
 *   deterministic spawn pool for generated mission enemies.
 * - If no class exists here, the framework helper falls back to CfgVehicles
 *   traversal for units whose faction and side match the selected faction.
 *
 * Most mod factions do not need an entry here. Add a class only when a faction
 * needs a curated or corrected spawn pool.
 */
class CfgFactionUnitMap {
    /*
     * Mapping key should match the selected faction classname from
     * CfgFactionClasses, such as "IND_G_F".
     */
    class IND_G_F {
        /*
         * Unit template fields:
         * - vehicle: unit classname to spawn.
         * - rank: Arma rank string applied after spawn.
         * - position[]: base local offset from the generated mission position.
         *
         * Generators may add small random jitter to the position offset.
         */
        class Units {
            class Unit0 { vehicle = "Ind_G_Unit1_F"; rank = "SERGEANT"; position[] = {0,0,0}; };
        };
    };
};

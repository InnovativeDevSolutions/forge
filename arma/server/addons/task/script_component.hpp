#define COMPONENT task
#define COMPONENT_BEAUTIFIED Task
#include "\forge\forge_server\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define ENABLE_PERFORMANCE_COUNTERS

#include "\forge\forge_server\addons\main\script_macros.hpp"

#define REWARD_ARRAY_ATTRIBUTES(PREFIX) \
            class EquipmentRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,EquipmentRewards)); \
                displayName = "Equipment Rewards"; \
                tooltip = "SQF array string for equipment rewards, e.g. [""ItemGPS"",""ItemCompass""]"; \
                typeName = "STRING"; \
            }; \
            class SupplyRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,SupplyRewards)); \
                displayName = "Supply Rewards"; \
                tooltip = "SQF array string for supply rewards, e.g. [""FirstAidKit"",""Medikit""]"; \
                typeName = "STRING"; \
            }; \
            class WeaponRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,WeaponRewards)); \
                displayName = "Weapon Rewards"; \
                tooltip = "SQF array string for weapon rewards, e.g. [""arifle_MX_F""]"; \
                typeName = "STRING"; \
            }; \
            class VehicleRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,VehicleRewards)); \
                displayName = "Vehicle Rewards"; \
                tooltip = "SQF array string for vehicle rewards, e.g. [""B_MRAP_01_F""]"; \
                typeName = "STRING"; \
            }; \
            class SpecialRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,SpecialRewards)); \
                displayName = "Special Rewards"; \
                tooltip = "SQF array string for special rewards, e.g. [""B_UAV_01_F""]"; \
                typeName = "STRING"; \
            };

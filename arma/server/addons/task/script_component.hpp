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
                tooltip = "Comma-separated equipment class names, e.g. ItemGPS, ItemCompass. Legacy SQF arrays still work."; \
                typeName = "STRING"; \
            }; \
            class SupplyRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,SupplyRewards)); \
                displayName = "Supply Rewards"; \
                tooltip = "Comma-separated supply class names, e.g. FirstAidKit, Medikit. Legacy SQF arrays still work."; \
                typeName = "STRING"; \
            }; \
            class WeaponRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,WeaponRewards)); \
                displayName = "Weapon Rewards"; \
                tooltip = "Comma-separated weapon class names, e.g. arifle_MX_F, arifle_Katiba_F. Legacy SQF arrays still work."; \
                typeName = "STRING"; \
            }; \
            class VehicleRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,VehicleRewards)); \
                displayName = "Vehicle Rewards"; \
                tooltip = "Comma-separated vehicle class names, e.g. B_MRAP_01_F, B_Quadbike_01_F. Legacy SQF arrays still work."; \
                typeName = "STRING"; \
            }; \
            class SpecialRewards: Edit { \
                property = QUOTE(DOUBLES(PREFIX,SpecialRewards)); \
                displayName = "Special Rewards"; \
                tooltip = "Comma-separated special reward class names, e.g. B_UAV_01_F, B_Heli_Light_01_F. Legacy SQF arrays still work."; \
                typeName = "STRING"; \
            };

#define TASK_CHAIN_ATTRIBUTES(PREFIX) \
            class PrerequisiteTaskIds: Edit { \
                property = QUOTE(DOUBLES(PREFIX,PrerequisiteTaskIds)); \
                displayName = "Prerequisite Task IDs"; \
                tooltip = "Comma-separated task IDs that must succeed before this task appears in CAD or can be assigned"; \
                typeName = "STRING"; \
            };

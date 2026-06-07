#define COMPONENT task
#define COMPONENT_BEAUTIFIED Task
#include "\forge\forge_mod\addons\main\script_mod.hpp"
#include "\forge\forge_mod\addons\main\script_macros.hpp"

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

#define TASK_DISPLAY_ATTRIBUTES(PREFIX, DEFAULT_ICON) \
            class TaskTitle: Edit { \
                property = QUOTE(DOUBLES(PREFIX,TaskTitle)); \
                displayName = "Task Title"; \
                tooltip = "Optional title shown in CAD, the map task list, and task notifications. Leave blank to use the Forge default."; \
                typeName = "STRING"; \
            }; \
            class TaskDescription: Edit { \
                property = QUOTE(DOUBLES(PREFIX,TaskDescription)); \
                displayName = "Task Description"; \
                tooltip = "Optional description shown in CAD and the map task list. Leave blank to use the Forge default."; \
                typeName = "STRING"; \
                control = "EditMulti5"; \
            }; \
            class TaskIcon: Combo { \
                property = QUOTE(DOUBLES(PREFIX,TaskIcon)); \
                displayName = "Task Icon"; \
                tooltip = "Arma 3 task framework type/icon used for the BIS map task."; \
                typeName = "STRING"; \
                defaultValue = QUOTE(DEFAULT_ICON); \
                class Values { \
                    class AirDrop { name = "airdrop"; value = "airdrop"; picture = "\a3\ui_f_orange\data\cfgTaskTypes\airdrop_ca.paa"; }; \
                    class Armor { name = "armor"; value = "armor"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\armor_ca.paa"; }; \
                    class Attack { name = "attack"; value = "attack"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\attack_ca.paa"; }; \
                    class Backpack { name = "backpack"; value = "backpack"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\backpack_ca.paa"; }; \
                    class Boat { name = "boat"; value = "boat"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\boat_ca.paa"; }; \
                    class Box { name = "box"; value = "box"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\box_ca.paa"; }; \
                    class Car { name = "car"; value = "car"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\car_ca.paa"; }; \
                    class Container { name = "container"; value = "container"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\container_ca.paa"; }; \
                    class Danger { name = "danger"; value = "danger"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\danger_ca.paa"; }; \
                    class Default { name = "default"; value = "default"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa"; }; \
                    class Defend { name = "defend"; value = "defend"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\defend_ca.paa"; }; \
                    class Destroy { name = "destroy"; value = "destroy"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\destroy_ca.paa"; }; \
                    class Documents { name = "documents"; value = "documents"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\documents_ca.paa"; }; \
                    class Download { name = "download"; value = "download"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\download_ca.paa"; }; \
                    class Exit { name = "exit"; value = "exit"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\exit_ca.paa"; }; \
                    class GetIn { name = "getin"; value = "getin"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\getin_ca.paa"; }; \
                    class GetOut { name = "getout"; value = "getout"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\getout_ca.paa"; }; \
                    class Heal { name = "heal"; value = "heal"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\heal_ca.paa"; }; \
                    class Heli { name = "heli"; value = "heli"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\heli_ca.paa"; }; \
                    class Help { name = "help"; value = "help"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\help_ca.paa"; }; \
                    class Intel { name = "intel"; value = "intel"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\intel_ca.paa"; }; \
                    class Interact { name = "interact"; value = "interact"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\interact_ca.paa"; }; \
                    class Kill { name = "kill"; value = "kill"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\kill_ca.paa"; }; \
                    class Land { name = "land"; value = "land"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\land_ca.paa"; }; \
                    class Listen { name = "listen"; value = "listen"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\listen_ca.paa"; }; \
                    class Map { name = "map"; value = "map"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\map_ca.paa"; }; \
                    class Meet { name = "meet"; value = "meet"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\meet_ca.paa"; }; \
                    class Mine { name = "mine"; value = "mine"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\mine_ca.paa"; }; \
                    class Move { name = "move"; value = "move"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move_ca.paa"; }; \
                    class Move1 { name = "move1"; value = "move1"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move1_ca.paa"; }; \
                    class Move2 { name = "move2"; value = "move2"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move2_ca.paa"; }; \
                    class Move3 { name = "move3"; value = "move3"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move3_ca.paa"; }; \
                    class Move4 { name = "move4"; value = "move4"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move4_ca.paa"; }; \
                    class Move5 { name = "move5"; value = "move5"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\move5_ca.paa"; }; \
                    class Navigate { name = "navigate"; value = "navigate"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\navigate_ca.paa"; }; \
                    class Plane { name = "plane"; value = "plane"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\plane_ca.paa"; }; \
                    class Radio { name = "radio"; value = "radio"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\radio_ca.paa"; }; \
                    class Rearm { name = "rearm"; value = "rearm"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\rearm_ca.paa"; }; \
                    class Refuel { name = "refuel"; value = "refuel"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\refuel_ca.paa"; }; \
                    class Repair { name = "repair"; value = "repair"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\repair_ca.paa"; }; \
                    class Rifle { name = "rifle"; value = "rifle"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\rifle_ca.paa"; }; \
                    class Run { name = "run"; value = "run"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\run_ca.paa"; }; \
                    class Scout { name = "scout"; value = "scout"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\scout_ca.paa"; }; \
                    class Search { name = "search"; value = "search"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\search_ca.paa"; }; \
                    class Takeoff { name = "takeoff"; value = "takeoff"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\takeoff_ca.paa"; }; \
                    class Talk { name = "talk"; value = "talk"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk_ca.paa"; }; \
                    class Talk1 { name = "talk1"; value = "talk1"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk1_ca.paa"; }; \
                    class Talk2 { name = "talk2"; value = "talk2"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk2_ca.paa"; }; \
                    class Talk3 { name = "talk3"; value = "talk3"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk3_ca.paa"; }; \
                    class Talk4 { name = "talk4"; value = "talk4"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk4_ca.paa"; }; \
                    class Talk5 { name = "talk5"; value = "talk5"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\talk5_ca.paa"; }; \
                    class Target { name = "target"; value = "target"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\target_ca.paa"; }; \
                    class Truck { name = "truck"; value = "truck"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\truck_ca.paa"; }; \
                    class Unknown { name = "unknown"; value = "unknown"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\unknown_ca.paa"; }; \
                    class Upload { name = "upload"; value = "upload"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\upload_ca.paa"; }; \
                    class Use { name = "use"; value = "use"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\use_ca.paa"; }; \
                    class Wait { name = "wait"; value = "wait"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\wait_ca.paa"; }; \
                    class Walk { name = "walk"; value = "walk"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\walk_ca.paa"; }; \
                    class Whiteboard { name = "whiteboard"; value = "whiteboard"; picture = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\whiteboard_ca.paa"; }; \
                }; \
            };

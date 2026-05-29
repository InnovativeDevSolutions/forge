class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase {
            class Edit;
            class Combo;
        };
        class ModuleDescription {};
    };

    class FORGE_Module_Attack: Module_F {
        scope = 2;
        displayName = "Attack Task";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(attackModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Attack_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
                // defaultValue = """";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Attack)
            class LimitFail: Edit {
                property = "FORGE_Module_Attack_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of targets that escape to fail the task";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_Attack_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of targets that need to be eliminated to succeed the task";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Attack_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Attack)
            class RatingFail: Edit {
                property = "FORGE_Module_Attack_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Attack_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Attack_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Attack_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_Attack_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Time in seconds before targets escape (0 for no limit)";
                typeName = "NUMBER";
                defaultValue = 0;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates an attack task with configurable parameters";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Attack task module",
                    "Sync with units/vehicles to mark as targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Explosives: Module_F {
        scope = 2;
        displayName = "Explosive Entities";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(explosivesModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "Module for explosive entities that need to be defused";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Explosive entities module",
                    "Sync with objects to mark as explosives",
                    "Those objects will be processed as defusal targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Hostages: Module_F {
        scope = 2;
        displayName = "Hostage Entities";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(hostagesModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "Module for hostage entities that need to be rescued";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Hostage entities module",
                    "Sync with units to mark as hostages",
                    "Those objects will be processed as rescue targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Shooters: Module_F {
        scope = 2;
        displayName = "Shooter Entities";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(shootersModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "Module for shooter entities that need to be eliminated";
            sync[] = { "AnyBrain" };

            class AnyBrain {
                description[] = {
                    "Shooter entities module",
                    "Sync with units to mark as shooters",
                    "Those objects will be processed as elimination targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Protected: Module_F {
        scope = 2;
        displayName = "Protected Entities";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(protectedModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "Module for protected entities that need to be protected";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Protected entities module",
                    "Sync with objects to mark as protected entities",
                    "Those objects will be processed as protected targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Defend: Module_F {
        scope = 2;
        displayName = "Defend Task";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(defendModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Defend_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Defend)
            class DefenseZone: Edit {
                property = "FORGE_Module_Defend_DefenseZone";
                displayName = "Defense Zone Marker";
                tooltip = "Name of the marker defining the defense zone";
                typeName = "STRING";
            };
            class DefendTime: Edit {
                property = "FORGE_Module_Defend_DefendTime";
                displayName = "Defend Time";
                tooltip = "Time in seconds the zone must be held";
                typeName = "NUMBER";
                defaultValue = 600;
            };
            class WaveCount: Edit {
                property = "FORGE_Module_Defend_WaveCount";
                displayName = "Wave Count";
                tooltip = "Number of enemy waves to spawn";
                typeName = "NUMBER";
                defaultValue = 3;
            };
            class WaveCooldown: Edit {
                property = "FORGE_Module_Defend_WaveCooldown";
                displayName = "Wave Cooldown";
                tooltip = "Time in seconds between enemy waves";
                typeName = "NUMBER";
                defaultValue = 300;
            };
            class MinBlufor: Edit {
                property = "FORGE_Module_Defend_MinBlufor";
                displayName = "Minimum BLUFOR";
                tooltip = "Minimum number of BLUFOR units that must remain in the zone";
                typeName = "NUMBER";
                defaultValue = 1;
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Defend_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Defend)
            class RatingFail: Edit {
                property = "FORGE_Module_Defend_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Defend_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Defend_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Defend_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a defend task with configurable defense zone and designer-controlled enemy wave templates";
            sync[] = { "AnyBrain" };

            class AnyBrain {
                description[] = {
                    "Defend task module",
                    "Sync with enemy units or group members to use their groups as wave templates"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Defuse: Module_F {
        scope = 2;
        displayName = "Defuse Task";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(defuseModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Defuse_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
                // defaultValue = """";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Defuse)
            class LimitFail: Edit {
                property = "FORGE_Module_Defuse_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of protected entities destroyed to fail the task";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_Defuse_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of entities that need to be defused to complete the task";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Defuse_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Defuse)
            class RatingFail: Edit {
                property = "FORGE_Module_Defuse_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Defuse_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Defuse_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEnSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Defuse_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_Defuse_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Time in seconds before detonation; must be greater than 0";
                typeName = "NUMBER";
                defaultValue = 300;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a defuse task with configurable parameters";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Defuse task module",
                    "Sync with entities to mark as explosives and protected entities",
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Destroy: Module_F {
        scope = 2;
        displayName = "Destroy Task";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(destroyModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Destroy_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
                // defaultValue = """";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Destroy)
            class LimitFail: Edit {
                property = "FORGE_Module_Destroy_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of targets that can escape before failing";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_Destroy_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of targets that need to be destroyed";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Destroy_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Destroy)
            class RatingFail: Edit {
                property = "FORGE_Module_Destroy_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Destroy_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Destroy_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Destroy_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_Destroy_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Time in seconds before targets escape (0 for no limit)";
                typeName = "NUMBER";
                defaultValue = 0;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a destroy task with configurable parameters";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Destroy task module",
                    "Sync with units and/or vehicles to mark as targets"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Hostage: Module_F {
        scope = 2;
        displayName = "Hostage Task";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(hostageModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Hostage_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
                // defaultValue = """";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Hostage)
            class LimitFail: Edit {
                property = "FORGE_Module_Hostage_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of hostages KIA before failing";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_Hostage_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of hostages rescued before succeeding";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class ExtZone: Edit {
                property = "FORGE_Module_Hostage_ExtZone";
                displayName = "Extraction Zone";
                tooltip = "Unique marker name for the extraction zone";
                typeName = "STRING";
                // defaultValue = """";
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Hostage_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Hostage)
            class RatingFail: Edit {
                property = "FORGE_Module_Hostage_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Hostage_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class CBRN: Combo {
                property = "FORGE_Module_Hostage_CBRN";
                displayName = "CBRN Attack";
                tooltip = "CBRN Attack instead of execution";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class TrueCBRN { name = "True"; value = 1; };
                    class FalseCBRN { name = "False"; value = 0; };
                };
            };
            class Execution: Combo {
                property = "FORGE_Module_Hostage_Execution";
                displayName = "Execution";
                tooltip = "Execution instead of CBRN Attack";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class TrueExecution { name = "True"; value = 1; };
                    class FalseExecution { name = "False"; value = 0; };
                };
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Hostage_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Hostage_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_Hostage_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Time in seconds before hostages are executed (0 for no limit)";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class CBRNZone: Edit {
                property = "FORGE_Module_Hostage_CBRNZone";
                displayName = "CBRN Zone";
                tooltip = "Unique marker name for the CBRN zone";
                typeName = "STRING";
                // defaultValue = """";
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a Hostage task with configurable parameters";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Hostage task module",
                    "Sync with hostage and shooter module to register the entities to the task"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Delivery: Module_F {
        scope = 2;
        displayName = "Delivery Task";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(deliveryModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_Delivery_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_Delivery)
            class DeliveryZone: Edit {
                property = "FORGE_Module_Delivery_DeliveryZone";
                displayName = "Delivery Zone Marker";
                tooltip = "Name of the marker defining the delivery destination";
                typeName = "STRING";
            };
            class LimitFail: Edit {
                property = "FORGE_Module_Delivery_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of cargo items damaged or lost before failing";
                typeName = "NUMBER";
                defaultValue = 1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_Delivery_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of cargo items that must reach the delivery zone";
                typeName = "NUMBER";
                defaultValue = 1;
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_Delivery_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_Delivery)
            class RatingFail: Edit {
                property = "FORGE_Module_Delivery_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_Delivery_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_Delivery_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_Delivery_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_Delivery_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Seconds to complete delivery (0 for no limit)";
                typeName = "NUMBER";
                defaultValue = 0;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a delivery task. Sync with a FORGE_Module_Cargo to register cargo objects.";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Delivery task module",
                    "Sync with FORGE_Module_Cargo which groups the cargo objects"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_Cargo: Module_F {
        scope = 2;
        displayName = "Cargo Entities";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(cargoModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "Grouping module for cargo objects in a delivery task. Sync with objects to mark as cargo, then sync this module to FORGE_Module_Delivery.";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "Cargo entities module",
                    "Sync with objects to mark as delivery cargo"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };

    class FORGE_Module_HVT: Module_F {
        scope = 2;
        displayName = "HVT Task";
        // icon = "\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\default_ca.paa";
        category = "FORGE_Modules";

        function = SERVER_TASK_FUNC(hvtModule);
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;

        canSetArea = 0;
        canSetAreaShape = 0;
        canSetAreaHeight = 0;

        class AttributeValues {};
        class Attributes: AttributesBase {
            class TaskID: Edit {
                property = "FORGE_Module_HVT_TaskID";
                displayName = "Task ID";
                tooltip = "Unique identifier for this task";
                typeName = "STRING";
                // defaultValue = """";
            };
            TASK_CHAIN_ATTRIBUTES(FORGE_Module_HVT)
            class LimitFail: Edit {
                property = "FORGE_Module_HVT_LimitFail";
                displayName = "Fail Limit";
                tooltip = "Number of hvts that can escape or KIA before failing";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class LimitSuccess: Edit {
                property = "FORGE_Module_HVT_LimitSuccess";
                displayName = "Success Limit";
                tooltip = "Number of hvts that need to be captured or KIA";
                typeName = "NUMBER";
                defaultValue = -1;
            };
            class ExtZone: Edit {
                property = "FORGE_Module_HVT_ExtZone";
                displayName = "Extraction Zone";
                tooltip = "Unique marker name for the extraction zone";
                typeName = "STRING";
                // defaultValue = """";
            };
            class CompanyFunds: Edit {
                property = "FORGE_Module_HVT_CompanyFunds";
                displayName = "Reward Funds";
                tooltip = "Amount of funds awarded on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            REWARD_ARRAY_ATTRIBUTES(FORGE_Module_HVT)
            class RatingFail: Edit {
                property = "FORGE_Module_HVT_RatingFail";
                displayName = "Rating Loss";
                tooltip = "Amount of rating lost on failure";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class RatingSuccess: Edit {
                property = "FORGE_Module_HVT_RatingSuccess";
                displayName = "Rating Gain";
                tooltip = "Amount of rating gained on success";
                typeName = "NUMBER";
                defaultValue = 0;
            };
            class CaptureHVT: Combo {
                property = "FORGE_Module_HVT_CaptureHVT";
                displayName = "Capture HVT";
                tooltip = "Capture HVT instead of eliminating";
                typeName = "BOOL";
                defaultValue = 1;

                class Values {
                    class TrueCapture { name = "True"; value = 1; };
                    class FalseCapture { name = "False"; value = 0; };
                };
            };
            class EliminateHVT: Combo {
                property = "FORGE_Module_HVT_EliminateHVT";
                displayName = "Eliminate HVT";
                tooltip = "Eliminate HVT instead of capturing";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class TrueEliminate { name = "True"; value = 1; };
                    class FalseEliminate { name = "False"; value = 0; };
                };
            };
            class EndSuccess: Combo {
                property = "FORGE_Module_HVT_EndSuccess";
                displayName = "End on Success";
                tooltip = "End mission when task is completed successfully";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndSuccess { name = "Enable"; value = 1; };
                    class DisableEndSuccess { name = "Disable"; value = 0; };
                };
            };
            class EndFail: Combo {
                property = "FORGE_Module_HVT_EndFail";
                displayName = "End on Failure";
                tooltip = "End mission when task fails";
                typeName = "BOOL";
                defaultValue = 0;

                class Values {
                    class EnableEndFail { name = "Enable"; value = 1; };
                    class DisableEndFail { name = "Disable"; value = 0; };
                };
            };
            class TimeLimit: Edit {
                property = "FORGE_Module_HVT_TimeLimit";
                displayName = "Time Limit";
                tooltip = "Time in seconds before the HVT task fails (0 for no limit)";
                typeName = "NUMBER";
                defaultValue = 0;
            };
        };

        class ModuleDescription: ModuleDescription {
            description = "Creates a HVT task with configurable parameters";
            sync[] = { "Anything" };

            class Anything {
                description[] = {
                    "HVT task module",
                    "Sync with units to mark as HVTs"
                };
                position = 1;
                direction = 1;
                optional = 1;
                duplicate = 1;
            };
        };
    };
};

#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        author = AUTHOR;
        authors[] = {"J.Schmidt"};
        url = "https://github.com/IDSolutions/MOD_REPO";
        name = COMPONENT_NAME;
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "forge_mod_main",
            "A3_Modules_F"
        };
        units[] = {
            "FORGE_Module_Attack",
            "FORGE_Module_Explosives",
            "FORGE_Module_Hostages",
            "FORGE_Module_Shooters",
            "FORGE_Module_Protected",
            "FORGE_Module_Defend",
            "FORGE_Module_Defuse",
            "FORGE_Module_Destroy",
            "FORGE_Module_Hostage",
            "FORGE_Module_Delivery",
            "FORGE_Module_Cargo",
            "FORGE_Module_HVT"
        };
        weapons[] = {};
        VERSION_CONFIG;
    };
};

#include "CfgFactionClasses.hpp"
#include "CfgVehicles.hpp"

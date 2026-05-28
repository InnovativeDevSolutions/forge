#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        author = AUTHOR;
        authors[] = {"IDSolutions"};
        url = "https://github.com/IDSolutions/MOD_REPO";
        name = COMPONENT_NAME;
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "forge_mod_main",
            "A3_Characters_F"
        };
        units[] = {"forge_bodyBag"};
        weapons[] = {};
        VERSION_CONFIG;
    };
};

#include "CfgVehicles.hpp"

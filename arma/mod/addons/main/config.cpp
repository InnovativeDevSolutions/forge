#include "script_component.hpp"

class CfgPatches {
    class ADDON {
        author = AUTHOR;
        authors[] = {"J.Schmidt"};
        url = "https://github.com/IDSolutions/MOD_REPO";
        name = COMPONENT_NAME;
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {"cba_main"};
        units[] = {};
        weapons[] = {};
        VERSION_CONFIG;
    };
};

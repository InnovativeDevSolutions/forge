#include "script_component.hpp"

// Loads only with AIO - Arma Inventory Overhaul. skipWhenMissingDependencies
// makes Arma skip this addon quietly when AIO is not loaded, so the rest of
// Forge works the same without it.
class CfgPatches {
    class ADDON {
        author = AUTHOR;
        authors[] = {"IDSolutions"};
        url = ECSTRING(main,url);
        name = COMPONENT_NAME;
        requiredVersion = REQUIRED_VERSION;
        requiredAddons[] = {
            "cba_main",
            "forge_client_main",
            "forge_client_locker",
            "aio_main",
            "aio_storage",
            "aio_gui"
        };
        skipWhenMissingDependencies = 1;
        units[] = {};
        weapons[] = {};
        VERSION_CONFIG;
    };
};

#include "CfgEventHandlers.hpp"

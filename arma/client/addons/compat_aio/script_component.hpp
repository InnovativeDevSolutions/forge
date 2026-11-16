#define COMPONENT compat_aio
#define COMPONENT_BEAUTIFIED Compat - AIO
#include "\forge\forge_client\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define ENABLE_PERFORMANCE_COUNTERS

#include "\forge\forge_client\addons\main\script_macros.hpp"

// AIO object variables (see AIO docs/ARCHITECTURE.md):
// - aio_storage_localOnly: moves on this object run on this machine, not through the server hub.
// - aio_noSearch: the object is not loot and needs no searching.
#define AIO_LOCAL_ONLY "aio_storage_localOnly"
#define AIO_NO_SEARCH "aio_noSearch"
#define AIO_DISPLAY "aio_gui_display"

// How often (seconds) and how close (metres) a locker is checked for changes.
#define LOCKER_CHECK_INTERVAL 2
#define LOCKER_CHECK_RANGE 15

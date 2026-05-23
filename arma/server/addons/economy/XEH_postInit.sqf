#include "script_component.hpp"

if !(isNil QGVAR(MEconomyStore)) then {
    GVAR(MEconomyStore) call ["init", []];
};

#include "\forge\forge_client\addons\main\data\hpp\defineDIKCodes.hpp"

[
    _category, QGVAR(ForgeIMenu),
    [LSTRING(iMenu), LSTRING(iMenuTooltip)], {
        call FUNC(openUI)
    }, {}, [DIK_TAB, false, false, false] // Default keybind
] call CBA_fnc_addKeybind;

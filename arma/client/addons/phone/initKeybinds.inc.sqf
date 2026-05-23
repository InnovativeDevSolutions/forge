#include "\forge\forge_client\addons\main\data\hpp\defineDIKCodes.hpp"

[
    _category, QGVAR(ForgePhone),
    [LSTRING(phone), LSTRING(phoneTooltip)], {
        [] call FUNC(openUI)
    }, {}, [DIK_P, [false, false, false]]
] call CFUNC(addKeybind);

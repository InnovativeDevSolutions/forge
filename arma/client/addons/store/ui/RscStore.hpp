class RscStore {
    idd = 1003;
    fadeIn = 0;
    fadeOut = 0;
    duration = 1e011;
    onLoad = "uiNamespace setVariable ['RscStore', _this select 0]";
    onUnLoad = "uinamespace setVariable ['RscStore', nil]";

    class controlsBackground {};
    class controls {
        class IFrame: RscText {
            type = 106;
            idc = 1004;
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

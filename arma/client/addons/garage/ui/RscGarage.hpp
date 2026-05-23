class RscGarage {
    idd = 1005;
    fadeIn = 0;
    fadeOut = 0;
    duration = 1e011;
    onLoad = "uiNamespace setVariable ['RscGarage', _this select 0]";
    onUnLoad = "uinamespace setVariable ['RscGarage', nil]";

    class controlsBackground {};
    class controls {
        class IFrame: RscText {
            type = 106;
            idc = 1006;
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

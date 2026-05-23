class RscBank {
    idd = 1001;
    fadeIn = 0;
    fadeOut = 0;
    duration = 1e011;
    onLoad = "uiNamespace setVariable ['RscBank', _this select 0]";
    onUnLoad = "uinamespace setVariable ['RscBank', nil]";

    class controlsBackground {};
    class controls {
        class IFrame: RscText {
            type = 106;
            idc = 1002;
            x = "safeZoneXAbs";
            y = "safeZoneY";
            w = "safeZoneWAbs";
            h = "safeZoneH";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

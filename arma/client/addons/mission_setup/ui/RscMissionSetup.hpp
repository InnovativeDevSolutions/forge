class RscText;

class RscMissionSetup {
    idd = 94010;
    fadeIn = 0;
    fadeOut = 0;
    duration = 1e011;
    onLoad = "uiNamespace setVariable ['RscMissionSetup', _this select 0]";
    onUnLoad = "uiNamespace setVariable ['RscMissionSetup', nil]";

    class controlsBackground {};
    class controls {
        class Browser: RscText {
            type = 106;
            idc = 94011;
            x = "safeZoneXAbs + (safeZoneWAbs * 0.125)";
            y = "safeZoneY + (safeZoneH * 0.125)";
            w = "safeZoneWAbs * 0.75";
            h = "safeZoneH * 0.75";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

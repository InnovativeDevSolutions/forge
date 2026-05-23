class RscTitles {
    class RscNotifications {
        idd = 1003;
        fadein = 0;
        fadeout = 0;
        duration = 1e+011;
        onLoad = "uinamespace setVariable ['RscNotifications', _this select 0]";
        onUnLoad = "uinamespace setVariable ['RscNotifications', nil]";

        class controlsBackground {};
        class controls {
            class IFrame: RscText {
                type = 106;
                idc = 1004;
                x = "safeZoneX";
                y = "safeZoneY";
                w = "safeZoneW";
                h = "safeZoneH";
            };
        };
    };
};

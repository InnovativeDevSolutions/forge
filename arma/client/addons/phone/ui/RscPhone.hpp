class RscPhone {
    idd = 1000;
    movingEnable = 1;
    enableSimulation = 1;
    duration = 1e011;
    fadeIn = 0;
    fadeOut = 0;
    onLoad = "uiNamespace setVariable ['RscPhone', _this select 0]";

    class controlsBackground {};
    class controls {
        class Background: RscText {
            type = 106;
            idc = 1001;
            x = "safezoneX + (safezoneW * 0.4125)";
            y = "safezoneY + (safezoneH * 0.1)";
            w = "safezoneW * 1";
            h = "safezoneH * 1";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

class RscMapUI {
    idd = 1004;
    movingEnable = 0;
    enableSimulation = 1;
    fadein = 0;
    fadeout = 0;
    duration = 1e+011;
    onLoad = "uiNamespace setVariable ['forge_client_cad_Display', _this select 0]; [_this select 0] call forge_client_cad_fnc_initUI;";
    onUnLoad = "uiNamespace setVariable ['forge_client_cad_Display', nil]; uiNamespace setVariable ['forge_client_cad_MapCtrl', nil]; uiNamespace setVariable ['forge_client_cad_TopBarCtrl', nil]; uiNamespace setVariable ['forge_client_cad_BottomBarCtrl', nil]; uiNamespace setVariable ['forge_client_cad_SidePanelCtrl', nil]; uiNamespace setVariable ['forge_client_cad_DispatcherCtrl', nil]; if !(isNil 'forge_client_cad_CADRepository') then { forge_client_cad_CADRepository set ['isOpen', false]; };";

    class controlsBackground {
        class SurfaceBackground: RscText {
            idc = -1;
            x = "safeZoneX + (safeZoneW * 0.1)";
            y = "safeZoneY + (safeZoneH * 0.1)";
            w = "safeZoneW * 0.8";
            h = "safeZoneH * 0.8";
            colorBackground[] = {0.04, 0.06, 0.09, 0.96};
        };

        class MapControl: RscMapControl {
            idc = 1001;
            x = "safeZoneX + (safeZoneW * 0.1)";  // 10% margin (80% width centered)
            y = "safeZoneY + (safeZoneH * 0.1) + 0.10372";  // 10% margin + 56px visible top bar
            w = "safeZoneW * 0.8";  // 80% width
            h = "(safeZoneH * 0.8) - 0.10372 - 0.0556";  // 80% height minus visible top and bottom bars
            
            // Map specific settings
            maxSatelliteAlpha = 0.85;
            alphaFadeStartScale = 0.35;
            alphaFadeEndScale = 0.4;
            colorBackground[] = {0.969, 0.957, 0.949, 1};
            colorSea[] = {0.467, 0.631, 0.851, 0.5};
            colorForest[] = {0.624, 0.78, 0.388, 0.5};
            colorRocks[] = {0, 0, 0, 0};
            colorCountlines[] = {0.572, 0.354, 0.318, 0.25};
            colorMainCountlines[] = {0.572, 0.354, 0.318, 0.5};
            colorCountlinesWater[] = {0.491, 0.577, 0.702, 0.3};
            colorMainCountlinesWater[] = {0.491, 0.577, 0.702, 0.6};
            colorForestBorder[] = {0, 0, 0, 0};
            colorRocksBorder[] = {0, 0, 0, 0};
            colorPowerLines[] = {0.1, 0.1, 0.1, 1};
            colorRailWay[] = {0.8, 0.2, 0, 1};
            colorNames[] = {0.1, 0.1, 0.1, 0.9};
            colorInactive[] = {1, 1, 1, 0.5};
            colorLevels[] = {0.286, 0.177, 0.094, 0.5};
            colorTracks[] = {0.84, 0.76, 0.65, 0.15};
            colorRoads[] = {0.7, 0.7, 0.7, 1};
            colorMainRoads[] = {0.9, 0.5, 0.3, 1};
            colorTracksFill[] = {0.84, 0.76, 0.65, 1};
            colorRoadsFill[] = {1, 1, 1, 1};
            colorMainRoadsFill[] = {1, 0.6, 0.4, 1};
            colorGrid[] = {0.1, 0.1, 0.1, 0.6};
            colorGridMap[] = {0.1, 0.1, 0.1, 0.6};
            colorText[] = {1, 1, 1, 1};
            font = "PuristaMedium";
            sizeEx = 0.04;
            showCountourInterval = 0;
            scaleMin = 0.001;
            scaleMax = 1;
            scaleDefault = 0.16;
        };
    };
    
    class controls {
        // Top bar browser
        class TopBarBrowser: RscText {
            type = 106;
            idc = 1002;
            x = "safeZoneX + (safeZoneW * 0.1)";
            y = "safeZoneY + (safeZoneH * 0.1)";
            w = "safeZoneW * 0.8";
            h = "0.24076";  // 130px, allows dropdowns to open over the map
            colorBackground[] = {0, 0, 0, 0};
        };
        
        // Bottom bar browser
        class BottomBarBrowser: RscText {
            type = 106;
            idc = 1003;
            x = "safeZoneX + (safeZoneW * 0.1)";
            y = "safeZoneY + (safeZoneH * 0.9) - 0.0556";
            w = "safeZoneW * 0.8";
            h = "0.0556";  // 30px
            colorBackground[] = {0, 0, 0, 0};
        };
        
        // Side panel browser (overlays from right side of 80% box)
        class SidePanelBrowser: RscText {
            type = 106;
            idc = 1005;
            x = "safeZoneX + (safeZoneW * 0.1) + (safeZoneW * 0.8) - 0.5550";  // Right edge of 80% box minus panel width
            y = "safeZoneY + (safeZoneH * 0.1) + 0.10372";  // Below visible top bar
            w = "0.5550";  // Wider panel for four-tab operations layout
            h = "(safeZoneH * 0.8) - 0.10372 - 0.0556";  // Full height minus visible bars
            colorBackground[] = {0, 0, 0, 0};
        };

        class DispatcherBrowser: RscText {
            type = 106;
            idc = 1006;
            x = "safeZoneX + (safeZoneW * 0.1)";
            y = "safeZoneY + (safeZoneH * 0.1) + 0.10372";
            w = "safeZoneW * 0.8";
            h = "(safeZoneH * 0.8) - 0.10372 - 0.0556";
            colorBackground[] = {0, 0, 0, 0};
        };
    };
};

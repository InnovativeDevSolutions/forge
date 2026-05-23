# Integrated Map Display System (A3API Pattern)

This system integrates the Arma 3 native map control (`RscMapControl`) within an HTML/CSS/JS UI using Arma's proper WebBrowser control (type 106) and A3API communication pattern.

## How It Works

### Layered Architecture

1. **IFrame Control (type 106)** - Loads HTML content using `ctrlWebBrowserAction`
2. **Map Control (RscMapControl)** - Native Arma map positioned behind/within the UI
3. **A3API Communication** - Bidirectional communication between JavaScript and SQF

### Communication Flow

**JavaScript → SQF:**
```javascript
// Send alert (no response expected)
A3API.SendAlert(JSON.stringify({
    event: "map::zoomIn",
    data: null
}));

// Send confirm (expects response via ExecJS)
A3API.SendConfirm(JSON.stringify({
    event: "map::getPosition",
    data: null
}));
```

**SQF → JavaScript:**
```sqf
_control ctrlWebBrowserAction ["ExecJS", "updateMapState({center: [1000, 2000], scale: 0.5});"];
```

## File Structure

```
UI/map/
├── _site/
│   ├── index.html    # HTML with A3API dynamic loading
│   ├── script.js     # JavaScript using A3API
│   └── style.css     # Styling
└── MAP_README.md     # This file

functions/map/
├── fn_openMap.sqf            # Opens the display
├── fn_mapHandleUIEvents.sqf  # Handles JS events
├── fn_mapDisplay.sqf         # Display initialization
└── fn_mapDisplayUpdate.sqf   # Update loop

UI/MapDisplay.h               # Dialog definition
```

## Usage

### Opening the Map

```sqf
[] call FORGE_fnc_openMap;
```

### From Init or Action

```sqf
// Add player action
player addAction ["Open Map", {[] call FORGE_fnc_openMap;}];

// In init.sqf
[] call FORGE_fnc_openMap;
```

## Key Differences from Standard HTML/CSS/JS

### 1. Dynamic Resource Loading

Instead of `<link>` and `<script>` tags, files are loaded using A3API:

```html
<script>
    Promise.all([
        A3API.RequestFile("UI\\map\\_site\\style.css"),
        A3API.RequestFile("UI\\map\\_site\\script.js")
    ]).then(([css, js]) => {
        // Apply CSS
        const style = document.createElement('style');
        style.textContent = css;
        document.head.appendChild(style);

        // Execute JavaScript
        const script = document.createElement('script');
        script.text = js;
        document.head.appendChild(script);
    });
</script>
```

### 2. Event Communication

Use **A3API.SendAlert()** for one-way messages:
```javascript
A3API.SendAlert(JSON.stringify({event: "map::action", data: value}));
```

Use **A3API.SendConfirm()** for messages expecting a response:
```javascript
A3API.SendConfirm(JSON.stringify({event: "map::getdata", data: null}));
```

### 3. Pointer Events

UI elements need `pointer-events: auto` while the body has `pointer-events: none`:

```css
body {
    pointer-events: none;  /* Allows clicks through to map */
}

#topBar {
    pointer-events: auto;   /* UI elements catch clicks */
}
```

## Dialog Definition Pattern

```cpp
class RscMapDisplay {
    idd = 9000;
    onLoad = "['onLoad', _this] call FORGE_fnc_mapDisplay;";
    
    class Controls {
        class Browser: RscText {
            type = 106;  // IFrame control type
            idc = 9001;
            x = "safeZoneX";
            y = "safeZoneY";
            w = "safeZoneW";
            h = "safeZoneH";
        };
        
        class MapControl: RscMapControl {
            idc = 9002;
            // Position to fit within HTML UI
        };
    };
};
```

## Event Handler Pattern

In `fn_openMap.sqf`:
```sqf
private _ctrl = _display displayCtrl 9001;

// Add JSDialog event handler
_ctrl ctrlAddEventHandler ["JSDialog", {
    params ["_control", "_isConfirmDialog", "_message"];
    [_control, _isConfirmDialog, _message] call FORGE_fnc_mapHandleUIEvents;
}];

// Load HTML file
_ctrl ctrlWebBrowserAction ["LoadFile", "UI\\map\\_site\\index.html"];
```

In `fn_mapHandleUIEvents.sqf`:
```sqf
params ["_control", "_isConfirmDialog", "_message"];

private _eventData = fromJSON _message;
private _event = _eventData get "event";
private _data = _eventData get "data";

switch (_event) do {
    case "map::ready": {
        // Initialize
    };
    case "map::zoomIn": {
        // Handle zoom
    };
};
```

## Benefits of This Pattern

1. **Proper Arma Integration** - Uses native WebBrowser control (type 106)
2. **File System Compatibility** - A3API.RequestFile() works with Arma's file system
3. **Reliable Communication** - JSDialog event handler is more stable than htmlLoad
4. **Modular** - CSS and JS in separate files, dynamically loaded
5. **Consistent** - Matches bank module pattern used in FORGE

## Troubleshooting

**Files not loading:**
- Check paths use double backslashes: `"UI\\map\\_site\\style.css"`
- Verify files exist in the correct directory
- Check .rpt log for file loading errors

**Events not firing:**
- Verify JSDialog event handler is attached
- Check JSON formatting in A3API calls
- Look for JavaScript console errors (use OpenDevConsole)

**Map not showing:**
- Verify MapControl idc matches (9002)
- Check map control positioning in MapDisplay.h
- Ensure map control is rendered after browser control

## Developer Tools

Enable dev console in `fn_openMap.sqf`:
```sqf
_ctrl ctrlWebBrowserAction ["OpenDevConsole"];
```

This opens Chromium dev tools for debugging JavaScript, CSS, and network requests.

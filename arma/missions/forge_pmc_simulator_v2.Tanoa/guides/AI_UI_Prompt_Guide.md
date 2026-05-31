# AI Prompt: Creating Arma 3 UI Windows (Dialogs) - Complete Guide

This document provides a comprehensive prompt for creating UI windows (dialogs) for Arma 3 missions.

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Dialog File Structure](#dialog-file-structure)
3. [Base Control Classes](#base-control-classes)
4. [Opening Dialogs via Scripts](#opening-dialogs-via-scripts)
5. [Interacting with Controls](#interacting-with-controls)
6. [Complete Example: Creating a New Store Dialog](#complete-example-creating-a-new-store-dialog)
7. [Integration Steps](#integration-steps)

---

## Core Concepts

### What Are Dialogs?

Dialogs in Arma 3 are UI windows defined in `*.hpp` files using a class-based syntax. They are defined using config classes that inherit from base control classes.

### Key Properties

- **idd**: Dialog ID (must be unique, e.g., 420, 6969, 9290)
- **movingEnable**: Allows dragging the window (true/false)
- **enableSimulation**: Allows simulation when open (true/false)

### Position System

Arma 3 uses a screen-relative coordinate system:
- `safezoneW` = safe zone width
- `safezoneH` = safe zone height  
- `safezoneX` = safe zone X offset
- `safezoneY` = safe zone Y offset

Formula: `x = (position * safezoneW) + safezoneX`
Formula: `y = (position * safezoneH) + safezoneY`

Example: `x = 0.5 * safezoneW + safezoneX` places control at 50% screen width

---

## Dialog File Structure

### Basic Dialog Template

```cpp
/*

Dialog Name - Version by Author
[License/Credits]

################################## LET US BEGIN #################################### */

class Dialog_ClassName {
    idd = UNIQUE_ID;
	movingEnable = true;
	enableSimulation = true;

    class Controls {

        ////////////////////////////////////////////////////////
        // GUI EDITOR OUTPUT START
        ////////////////////////////////////////////////////////

        // Add your controls here

        ////////////////////////////////////////////////////////
        // GUI EDITOR OUTPUT END
        ////////////////////////////////////////////////////////
    };
};
```

---

## Base Control Classes

### 1. RscText (Static Text)

```cpp
class MyText: RscText {
    idc = 1000;
    text = "Label Text";
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.1 * safezoneW;
    h = 0.033 * safezoneH;
};
```

### 2. RscStructuredText (Rich Text with HTML-like formatting)

```cpp
class MyStructuredText: RscStructuredText {
    idc = 1100;
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.1 * safezoneW;
    h = 0.033 * safezoneH;
    colorBackground[] = {0,0,0,0};  // Optional background
};
```

Set text dynamically:
```cpp
_ChildControl ctrlSetStructuredText parseText format ["Value: %1", myValue];
```

### 3. RscPicture

```cpp
class MyPicture: RscPicture {
    idc = 1200;
    text = "images\myimage.paa";
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.2 * safezoneW;
    h = 0.15 * safezoneH;
};
```

### 4. RscButton

```cpp
class MyButton: RscButton {
    onButtonClick = "[] call myFunction;";
    idc = 1600;
    text = "Click Me";
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.1 * safezoneW;
    h = 0.033 * safezoneH;
    tooltip = "Tooltip text";
};
```

### 5. RscEdit (Input Field)

```cpp
class MyEdit: RscEdit {
    idc = 1400;
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.1 * safezoneW;
    h = 0.033 * safezoneH;
    tooltip = "Enter value here";
};
```

Get value:
```cpp
_value = ctrlText findDisplay DIALOG_ID displayCtrl CONTROL_ID;
```

### 6. RscListbox

```cpp
class MyListbox: RscListBox {
    onLBDblClick = "_this spawn myFunction;";
    idc = 1500;
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.3 * safezoneW;
    h = 0.4 * safezoneH;
};
```

Populate dynamically:
```cpp
lbClear CONTROL_ID;
{
    lbAdd [CONTROL_ID, _x select 0];
} forEach myArray;
```

Get selection:
```cpp
_selectedIndex = lbCurSel CONTROL_ID;
_selectedValue = myArray select _selectedIndex;
```

### 7. RscCombo (Dropdown)

```cpp
class MyCombo: RscCombo {
    onLBSelChanged = "_this spawn myFunction;";
    idc = 2100;
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.15 * safezoneW;
    h = 0.033 * safezoneH;
};
```

### 8. RscFrame (Window Border/Title)

```cpp
class MyFrame: RscFrame {
    Moving = 1;  // Allow moving with this frame
    idc = 1800;
    text = "Window Title";
    x = 0.3 * safezoneW + safezoneX;
    y = 0.3 * safezoneH + safezoneY;
    w = 0.4 * safezoneW;
    h = 0.4 * safezoneH;
};
```

### 9. RscClrButton (Colored/Image Button)

```cpp
class MyImageButton: RscClrButton {
    onButtonClick = "[] call myFunction;";
    idc = 2000;
    x = 0.5 * safezoneW + safezoneX;
    y = 0.5 * safezoneH + safezoneY;
    w = 0.2 * safezoneW;
    h = 0.1 * safezoneH;
    tooltip = "Button tooltip";
};
```

---

## Opening Dialogs via Scripts

### Method 1: Using CreateDialog (Simple)

```cpp
// In a script file (.sqf)
_handle = CreateDialog "Dialog_ClassName";
```

### Method 2: Using execVM

```cpp
// In a script file (.sqf)
execVM "scripts\myDialogScript.sqf";
```

The script then calls CreateDialog.

### Example: Triggering from an Action

```cpp
// Add to object's init line
this addAction ["Open Menu", "execVM 'scripts\myDialogScript.sqf'"];
```

---

## Interacting with Controls

### Finding the Display

```cpp
disableSerialization;
_disp = findDisplay DIALOG_ID;
```

### Getting a Control

```cpp
_ctrl = _disp displayCtrl CONTROL_ID;
```

### Setting Text

```cpp
_ctrl ctrlSetText "New Text";
```

### Getting Text

```cpp
_value = ctrlText CONTROL_ID;
```

### Setting Structured Text

```cpp
_ctrl ctrlSetStructuredText parseText format ["Value: %1", myValue];
```

### Setting Focus

```cpp
ctrlSetFocus _ctrl;
```

### Hiding/Showing Controls

```cpp
_ctrl ctrlShow false;  // Hide
_ctrl ctrlShow true;   // Show
```

### Enabling/Disabling Controls

```cpp
_ctrl ctrlEnable false;  // Disable
_ctrl ctrlEnable true;   // Enable
```

---

## Complete Example: Creating a New Store Dialog

### Step 1: Create the Dialog Definition File

File: `dialogs\MyNewStore.hpp`

```cpp
/*

My New Store GUI V 1.0 by [Your Name]

License:
[Your License]

################################## LET US BEGIN #################################### */

class A3M_MyNewStore {
    idd = 5000;  // Use a unique ID!
	movingEnable = true;
	enableSimulation = true;

    class Controls {

        ////////////////////////////////////////////////////////
        // GUI EDITOR OUTPUT START
        ////////////////////////////////////////////////////////

        class MyStore_Frame: RscFrame {
            Moving = 1;
            idc = 1800;
            text = "My New Store";
            x = 0.3 * safezoneW + safezoneX;
            y = 0.3 * safezoneH + safezoneY;
            w = 0.4 * safezoneW;
            h = 0.4 * safezoneH;
        };
        
        class MyStore_ExitButton: RscButton {
            onButtonClick = "closeDialog 0;";
            idc = 1600;
            text = "Exit";
            x = 0.65 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.04 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_CategoryTitle: RscText {
            idc = 1000;
            text = "Categories:";
            x = 0.32 * safezoneW + safezoneX;
            y = 0.32 * safezoneH + safezoneY;
            w = 0.08 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_Btn_Items: RscButton {
            onButtonClick = "[] call MyStore_fnc_loadItems;";
            idc = 1610;
            text = "Browse Items";
            x = 0.32 * safezoneW + safezoneX;
            y = 0.36 * safezoneH + safezoneY;
            w = 0.1 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_ItemList: RscListBox {
            onLBDblClick = "_this spawn MyStore_fnc_handleSelect;";
            idc = 1500;
            x = 0.32 * safezoneW + safezoneX;
            y = 0.41 * safezoneH + safezoneY;
            w = 0.36 * safezoneW;
            h = 0.2 * safezoneH;
        };
        
        class MyStore_InfoTitle: RscText {
            idc = 1001;
            text = "Information:";
            x = 0.5 * safezoneW + safezoneX;
            y = 0.32 * safezoneH + safezoneY;
            w = 0.1 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_InfoDisplay: RscStructuredText {
            idc = 1100;
            x = 0.5 * safezoneW + safezoneX;
            y = 0.36 * safezoneH + safezoneY;
            w = 0.18 * safezoneW;
            h = 0.1 * safezoneH;
            colorBackground[] = {0,0,0,0.3};
        };
        
        class MyStore_Btn_Purchase: RscButton {
            onButtonClick = "[] call MyStore_fnc_purchaseItem;";
            idc = 1620;
            text = "Purchase";
            x = 0.6 * safezoneW + safezoneX;
            y = 0.65 * safezoneW + safezoneW;
            w = 0.08 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_BalanceTitle: RscText {
            idc = 1002;
            text = "Balance:";
            x = 0.32 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.06 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        class MyStore_BalanceDisplay: RscStructuredText {
            idc = 1101;
            x = 0.38 * safezoneW + safezoneX;
            y = 0.65 * safezoneH + safezoneY;
            w = 0.1 * safezoneW;
            h = 0.033 * safezoneH;
        };
        
        ////////////////////////////////////////////////////////
        // GUI EDITOR OUTPUT END
        ////////////////////////////////////////////////////////
    };
};
```

### Step 2: Create the Handler Script

File: `scripts\MyNewStore.sqf`

```cpp
/*

My New Store Script by [Your Name]

################################## LET US BEGIN #################################### */

// Open the dialog
_handle = CreateDialog "A3M_MyNewStore";

// Define available items
myStoreItems = [
    ["Item Name 1", 100],
    ["Item Name 2", 200],
    ["Item Name 3", 300]
];

// Update balance display
MyStore_UpdateBalance = {
    disableSerialization;
    _disp = findDisplay 5000;
    if (str(_disp) != "no display") then {
        _ctrl = _disp displayCtrl 1101;
        _balance = player getVariable "myMoney";
        _ctrl ctrlSetStructuredText parseText format ["$%1", _balance];
    };
};
[] call MyStore_UpdateBalance;

// Load items into listbox
MyStore_fnc_loadItems = {
    lbClear 1500;
    {
        lbAdd [1500, format ["%1 - $%2", _x select 0, _x select 1]];
    } forEach myStoreItems;
};

// Handle selection
MyStore_fnc_handleSelect = {
    _index = _this select 1;
    _item = myStoreItems select _index;
    _disp = findDisplay 5000;
    _ctrl = _disp displayCtrl 1100;
    _ctrl ctrlSetStructuredText parseText format [
        "Selected: %1<br/>Price: $%2",
        _item select 0,
        _item select 1
    ];
};

// Purchase item
MyStore_fnc_purchaseItem = {
    _index = lbCurSel 1500;
    if (_index == -1) exitWith { hint "Select an item first!"; };
    
    _item = myStoreItems select _index;
    _price = _item select 1;
    _money = player getVariable "myMoney";
    
    if (_money < _price) exitWith { hint "Not enough money!"; };
    
    player setVariable ["myMoney", _money - _price];
    hint format ["Purchased %1 for $%2!", _item select 0, _price];
    
    [] call MyStore_UpdateBalance;
};
```

### Step 3: Add to description.ext

```cpp
#include "dialogs\MyNewStore.hpp"
```

### Step 4: Add Open Action (Optional)

Add to an object's init:
```cpp
this addAction ["Open Store", "execVM 'scripts\MyNewStore.sqf'"];
```

---

## Integration Steps

### 1. Create Dialog File (.hpp)

Create the dialog class definition in the `dialogs/` folder.

### 2. Include in description.ext

Add `#include "dialogs\YourDialog.hpp"` to the description.ext file.

### 3. Register Controls Used

If using custom control IDs, ensure they don't conflict with existing ones. Common ranges:
- 1000-1099: Text/Static controls
- 1100-1199: Structured text
- 1200-1299: Pictures
- 1400-1499: Edit fields
- 1500-1599: Listboxes
- 1600-1699: Buttons
- 1800-1899: Frames
- 2000-2999: Custom controls

### 4. Create Handler Script

Create an `.sqf` script file in the `scripts/` folder to handle the dialog logic.

### 5. Test Thoroughly

- Test opening/closing the dialog
- Test all buttons and interactions
- Test list population
- Test form validation
- Test error messages

---

## Best Practices

1. **Unique IDD**: Always use a unique dialog ID (idd)
2. **Organized Layout**: Use a consistent grid layout
3. **Clear Labels**: Always label information displays
4. **Exit Button**: Always include an exit/close button
5. **Form Validation**: Validate inputs before processing
6. **User Feedback**: Use hints to provide feedback
7. **Responsive Design**: Test on different aspect ratios
8. **Mod Support**: Consider adding mod compatibility checks

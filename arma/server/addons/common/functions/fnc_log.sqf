#include "..\script_component.hpp"

/*
 * File: fnc_log.sqf
 * Author: IDSolutions
 * Date: 2026-01-03
 * Last Update: 2026-01-18
 * Public: No
 *
 * Description:
 *     Writes a log entry.
 *
 * Parameter(s):
 *     0: Log level <STRING> (DEBUG, INFO, ERROR, WARNING, VERBOSE)
 *     1: Message to log <STRING>
 *     2: File that's being logged <STRING>
 *     3: File that called the file being logged <STRING> (Optional)
 *     4: Stack trace <BOOL> (Default: false)
 *     5: Identifier <STRING> (Default: "FORGE")
 *
 * Returns:
 *     N/A
 *
 * Example(s):
 *     ["ERROR", "Ooh, something went wrong"] call para_g_fnc_log;
 */

params ["_logLevel", "_message", "_file", "_callingFile", ["_stackTrace", false, [false]], ["_identifier", "FORGE", [""]]];

if (is3DENPreview) exitWith { diag_log text format ["[%1] %2: %3", _identifier, _logLevel, _message]; };
if !(_logLevel in ["DEBUG", "INFO", "ERROR", "WARNING", "VERBOSE"]) exitWith { diag_log text format ["[%1] ERROR: Invalid log level '%2'", _identifier, _logLevel]; };
if (_stackTrace) then {
    private _trace = diag_stacktrace;
    private _traceText = _trace apply { format ["%1 (Line %2)", _x # 0, _x # 1] } joinString endl;
    _message = _traceText;
};

// private _timestamp = format (["%1-%2-%3 %4:%5:%6:%7"] + systemTimeUTC);

if (isNil "_file") then { _file = ["", _fnc_scriptName] select (!isNil "_fnc_scriptName"); };
if (isNil "_callingFile" && !isNil "_fnc_scriptNameParent") then { _callingFile = _fnc_scriptNameParent; };

// private _callingFileText = if !(isNil "_callingFile") then { format ["Called By: %1", _callingFile] } else { "" };

// diag_log text format [
// 	"%1 | %2 | %3 | File: %4 | %5 | %6",
// 	_timestamp,
// 	_identifier,
// 	_logLevel,
// 	_file,
// 	_callingFileText,
// 	_message
// ];

diag_log text format ["[%1] %2: %3", _identifier, _logLevel, _message];

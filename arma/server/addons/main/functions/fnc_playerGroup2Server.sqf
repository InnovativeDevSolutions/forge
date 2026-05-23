#include "..\script_component.hpp"

params [["_ip", "127.0.0.1", [""]], ["_port", "2312", [""]], ["_password", "abc", [""]]];

private _units = units group player select { isPlayer _x };
private _machineIDs = _units apply { owner _x };

{
    [_ip, _port, _password] remoteExecCall ["forge_server_misc_fnc_redirectClient2Server", _x];
} forEach _machineIDs;

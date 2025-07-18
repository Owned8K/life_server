#include "\life_server\script_macros.hpp"
/*
    File: fn_fetchCompanyData.sqf
    Author: Gemini
    Description: Récupère les données de l'entreprise d'un joueur depuis la base de données.
*/

params [
    ["_player", objNull, [objNull]]
];

if (isNull _player) exitWith {};

private _uid = getPlayerUID _player;
private _query = format ["SELECT id, name, owner_name, owner_uid, bank FROM companies WHERE owner_uid='%1' LIMIT 1", _uid];

private _queryResult = [_query,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Query result: %1", _queryResult];

if (_queryResult isEqualTo []) then {
    [[0, "", "", "", 0], _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
} else {
    _queryResult params [
        ["_id", 0, [0]],
        ["_name", "", [""]],
        ["_ownerName", "", [""]],
        ["_ownerUID", "", [""]],
        ["_bank", 0, [0]]
    ];
    
    private _formattedData = [_id, _name, _ownerName, _ownerUID, _bank];
    [_formattedData, _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
}; 
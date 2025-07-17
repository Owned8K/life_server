#include "\life_server\script_macros.hpp"
/*
    File: fn_checkCompanyOwner.sqf
    Author: Your Name
    Description: Vérifie si le joueur possède une entreprise et a la licence
*/

params [
    ["_player", objNull, [objNull]],
    ["_playerUID", "", [""]]
];

if (isNull _player || _playerUID isEqualTo "") exitWith {
    diag_log "[COMPANY CHECK] Invalid parameters";
};

diag_log format ["[COMPANY CHECK] Checking company ownership for player %1 (%2)", name _player, _playerUID];

// Vérifier si le joueur a une entreprise
private _query = format ["SELECT id, name FROM companies WHERE owner_uid='%1' LIMIT 1", _playerUID];
private _queryResult = [_query, 2] call DB_fnc_asyncCall;

// Envoyer le résultat au client
[_queryResult, _player] remoteExecCall ["life_fnc_companyOwnershipReceived", owner _player];

// Log
diag_log format ["[COMPANY CHECK] Result for %1 (%2): %3", name _player, _playerUID, _queryResult]; 
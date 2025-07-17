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

diag_log "=== COMPANY OWNERSHIP CHECK ===";
diag_log format ["Player: %1", name _player];
diag_log format ["UID: %1", _playerUID];

// Vérifier si le joueur a une entreprise
private _query = format ["SELECT id, name FROM companies WHERE owner_uid='%1' LIMIT 1", _playerUID];
diag_log format ["Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["Query Result: %1", _queryResult];

// Envoyer le résultat au client
[_queryResult, _player] remoteExecCall ["life_fnc_companyOwnershipReceived", owner _player];

// Log
diag_log format ["Owner ID: %1", owner _player];
diag_log "=== END COMPANY CHECK ===";

if !(_queryResult isEqualTo []) then {
    diag_log format ["[SUCCESS] Found company for %1: %2", name _player, _queryResult select 1];
} else {
    diag_log format ["[INFO] No company found for %1", name _player];
}; 
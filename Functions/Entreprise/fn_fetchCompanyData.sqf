#include "\life_server\script_macros.hpp"
/*
    File: fn_fetchCompanyData.sqf
    Author: Gemini
    Description: Récupère les données de l'entreprise d'un joueur depuis la base de données.
*/

params [
    ["_player", objNull, [objNull]]
];

if (isNull _player) exitWith {
    diag_log "[COMPANY FETCH] Error: Player is null";
};

private _uid = getPlayerUID _player;
diag_log format ["[COMPANY FETCH] Fetching data for player UID: %1", _uid];

// Récupérer les données de l'entreprise
private _query = format ["SELECT c.id, c.name, ce_owner.player_name as owner_name, ce_owner.player_uid as owner_uid, c.bank 
    FROM companies c 
    INNER JOIN company_employees ce_owner ON c.id = ce_owner.company_id AND ce_owner.role = 'owner'
    LEFT JOIN company_employees ce ON c.id = ce.company_id 
    WHERE ce.player_uid = '%1' 
    LIMIT 1", _uid];

diag_log format ["[COMPANY FETCH] Company query: %1", _query];
private _queryResult = [_query,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Company query result: %1", _queryResult];

if (_queryResult isEqualTo []) exitWith {
    diag_log "[COMPANY FETCH] No company found, sending empty data";
    [[0, "", "", "", 0, []], _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
};

_queryResult params [
    ["_companyId", 0, [0]],
    ["_companyName", "", [""]],
    ["_ownerName", "", [""]],
    ["_ownerUID", "", [""]],
    ["_companyBank", 0, [0]]
];

// Récupérer la liste des employés
private _employeeQuery = format ["SELECT player_uid, player_name, role FROM company_employees WHERE company_id=%1", _companyId];
diag_log format ["[COMPANY FETCH] Employee query: %1", _employeeQuery];

private _employees = [_employeeQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Employees query result: %1", _employees];

// Formater les données des employés
private _formattedEmployees = [];
{
    _x params [
        ["_empUID", "", [""]],
        ["_empName", "", [""]],
        ["_empRole", "", [""]]
    ];
    
    // On considère que les employés normaux ont un salaire de 0 pour l'instant
    // Vous pourrez ajouter une colonne salary plus tard si nécessaire
    _formattedEmployees pushBack [_empUID, _empName, 0];
} forEach _employees;

private _formattedData = [_companyId, _companyName, _ownerName, _ownerUID, _companyBank, _formattedEmployees];
diag_log format ["[COMPANY FETCH] Sending formatted data: %1", _formattedData];
[_formattedData, _player] remoteExecCall ["life_fnc_companyDataReceived", _player]; 
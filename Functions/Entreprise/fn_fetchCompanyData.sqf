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

// D'abord, vérifions si le joueur est lié à une entreprise (propriétaire ou employé)
private _checkQuery = format ["SELECT company_id, role FROM company_employees WHERE player_uid='%1' LIMIT 1", _uid];
diag_log format ["[COMPANY FETCH] Check query: %1", _checkQuery];
private _checkResult = [_checkQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Check result: %1", _checkResult];

if (_checkResult isEqualTo []) exitWith {
    diag_log "[COMPANY FETCH] No company association found";
    [[0, "", "", "", 0, []], _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
};

_checkResult params [
    ["_companyId", 0, [0]],
    ["_playerRole", "", [""]]
];

// Maintenant, récupérons les informations de l'entreprise
private _query = format ["SELECT c.id, c.name, c.bank FROM companies c WHERE c.id=%1", _companyId];
diag_log format ["[COMPANY FETCH] Company query: %1", _query];
private _companyResult = [_query,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Company result: %1", _companyResult];

if (_companyResult isEqualTo []) exitWith {
    diag_log "[COMPANY FETCH] Company not found";
    [[0, "", "", "", 0, []], _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
};

_companyResult params [
    ["_companyId", 0, [0]],
    ["_companyName", "", [""]],
    ["_companyBank", 0, [0]]
];

// Récupérer les informations du propriétaire
private _ownerQuery = format ["SELECT player_uid, player_name FROM company_employees WHERE company_id=%1 AND role='owner' LIMIT 1", _companyId];
diag_log format ["[COMPANY FETCH] Owner query: %1", _ownerQuery];
private _ownerResult = [_ownerQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Owner result: %1", _ownerResult];

private _ownerUID = "";
private _ownerName = "";
if !(_ownerResult isEqualTo []) then {
    _ownerResult params [
        ["_tempOwnerUID", "", [""]],
        ["_tempOwnerName", "", [""]]
    ];
    _ownerUID = _tempOwnerUID;
    _ownerName = _tempOwnerName;
};

// Récupérer la liste des employés
private _employeeQuery = format ["SELECT player_uid, player_name, role FROM company_employees WHERE company_id=%1", _companyId];
diag_log format ["[COMPANY FETCH] Employee query: %1", _employeeQuery];
private _employees = [_employeeQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Employees result: %1", _employees];

// Formater les données des employés
private _formattedEmployees = [];
{
    _x params [
        ["_empUID", "", [""]],
        ["_empName", "", [""]],
        ["_empRole", "", [""]]
    ];
    
    // On considère que les employés normaux ont un salaire de 0 pour l'instant
    _formattedEmployees pushBack [_empUID, _empName, 0];
} forEach _employees;

private _formattedData = [_companyId, _companyName, _ownerName, _ownerUID, _companyBank, _formattedEmployees];
diag_log format ["[COMPANY FETCH] Sending formatted data: %1", _formattedData];
[_formattedData, _player] remoteExecCall ["life_fnc_companyDataReceived", _player]; 
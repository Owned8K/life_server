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

// Récupérer les données de l'entreprise
private _query = format ["SELECT id, name, owner_name, owner_uid, bank FROM companies WHERE owner_uid='%1' OR id IN (SELECT company_id FROM company_employees WHERE employee_uid='%1') LIMIT 1", _uid];
private _queryResult = [_query,2] call DB_fnc_asyncCall;

diag_log format ["[COMPANY FETCH] Company query result: %1", _queryResult];

if (_queryResult isEqualTo []) exitWith {
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
private _employeeQuery = format ["SELECT employee_uid, employee_name, salary FROM company_employees WHERE company_id=%1", _companyId];
private _employees = [_employeeQuery,2] call DB_fnc_asyncCall;

diag_log format ["[COMPANY FETCH] Employees query result: %1", _employees];

if (_employees isEqualTo []) then {
    _employees = [];
};

private _formattedData = [_companyId, _companyName, _ownerName, _ownerUID, _companyBank, _employees];
[_formattedData, _player] remoteExecCall ["life_fnc_companyDataReceived", _player]; 
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

// Vérifier si le joueur est propriétaire d'une entreprise
private _ownerQuery = format ["SELECT id, name, owner_name, owner_uid, bank FROM companies WHERE owner_uid = '%1'", _uid];
diag_log format ["[COMPANY FETCH] Owner query: %1", _ownerQuery];
private _ownerResult = [_ownerQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Owner result: %1", _ownerResult];

// Si le joueur n'est pas propriétaire, vérifier s'il est employé
if (_ownerResult isEqualTo []) then {
    private _employeeQuery = format ["SELECT c.id, c.name, c.owner_name, c.owner_uid, c.bank 
        FROM companies c 
        INNER JOIN company_employees ce ON c.id = ce.company_id 
        WHERE ce.player_uid = '%1'", _uid];
    
    diag_log format ["[COMPANY FETCH] Employee query: %1", _employeeQuery];
    _ownerResult = [_employeeQuery,2] call DB_fnc_asyncCall;
    diag_log format ["[COMPANY FETCH] Employee result: %1", _ownerResult];
};

if (_ownerResult isEqualTo []) exitWith {
    diag_log "[COMPANY FETCH] No company found";
    [[0, "", "", "", 0, []], _player] remoteExecCall ["life_fnc_companyDataReceived", _player];
};

_ownerResult params [
    ["_companyId", 0, [0]],
    ["_companyName", "", [""]],
    ["_ownerName", "", [""]],
    ["_ownerUID", "", [""]],
    ["_companyBank", 0, [0]]
];

diag_log format ["[COMPANY FETCH] Found company - ID: %1, Name: %2, Owner: %3, Bank: %4", 
    _companyId, _companyName, _ownerName, _companyBank];

// Récupérer la liste des employés
private _employeeQuery = format ["SELECT player_uid, player_name, role FROM company_employees WHERE company_id = %1", _companyId];
diag_log format ["[COMPANY FETCH] Employees query: %1", _employeeQuery];
private _employees = [_employeeQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY FETCH] Employees result: %1", _employees];

// Formater les données des employés
private _formattedEmployees = [];
{
    if (count _x >= 3) then {
        _x params [
            ["_empUID", "", [""]],
            ["_empName", "", [""]],
            ["_empRole", "", [""]]
        ];
        
        // Extraire le salaire du rôle (format: "salary_X")
        private _salary = 0;
        if (_empRole select [0,7] == "salary_") then {
            _salary = parseNumber (_empRole select [7]);
        };
        
        _formattedEmployees pushBack [_empUID, _empName, _salary];
        diag_log format ["[COMPANY FETCH] Added employee - UID: %1, Name: %2, Salary: %3", 
            _empUID, _empName, _salary];
    };
} forEach _employees;

private _formattedData = [_companyId, _companyName, _ownerName, _ownerUID, _companyBank, _formattedEmployees];
diag_log format ["[COMPANY FETCH] Final formatted data: %1", _formattedData];
[_formattedData, _player] remoteExecCall ["life_fnc_companyDataReceived", _player]; 
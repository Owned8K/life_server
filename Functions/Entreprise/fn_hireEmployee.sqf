#include "\life_server\script_macros.hpp"
/*
    File: fn_hireEmployee.sqf
    Author: Gemini
    Description: Ajoute un employé à une entreprise
*/

params [
    ["_owner", objNull, [objNull]],
    ["_employeeUID", "", [""]],
    ["_employeeName", "", [""]]
];

if (isNull _owner || _employeeUID isEqualTo "" || _employeeName isEqualTo "") exitWith {};

private _ownerUID = getPlayerUID _owner;

// Vérifier que le joueur est bien propriétaire
private _query = format ["SELECT id FROM companies WHERE owner_uid='%1' LIMIT 1", _ownerUID];
private _queryResult = [_query,2] call DB_fnc_asyncCall;

if (_queryResult isEqualTo []) exitWith {
    [1, "STR_Company_NotOwner"] remoteExecCall ["life_fnc_broadcast", _owner];
};

private _companyId = _queryResult select 0;

// Vérifier si l'employé n'est pas déjà dans l'entreprise
_query = format ["SELECT id FROM company_employees WHERE company_id=%1 AND employee_uid='%2'", _companyId, _employeeUID];
_queryResult = [_query,2] call DB_fnc_asyncCall;

if !(_queryResult isEqualTo []) exitWith {
    [1, "STR_Company_AlreadyEmployee"] remoteExecCall ["life_fnc_broadcast", _owner];
};

// Ajouter l'employé
_query = format ["INSERT INTO company_employees (company_id, employee_uid, employee_name, salary) VALUES (%1, '%2', '%3', 0)", _companyId, _employeeUID, _employeeName];
_queryResult = [_query,1] call DB_fnc_asyncCall;

if (_queryResult) then {
    // Rafraîchir les données pour tous les joueurs concernés
    [_owner] call TON_fnc_fetchCompanyData;
    
    // Notifier le propriétaire et l'employé
    [1, format [localize "STR_Company_Hired_Success", _employeeName]] remoteExecCall ["life_fnc_broadcast", _owner];
    
    private _employee = [_employeeUID] call TON_fnc_getPlayerObj;
    if !(isNull _employee) then {
        [1, format [localize "STR_Company_Hired_Notice", name _owner]] remoteExecCall ["life_fnc_broadcast", _employee];
    };
} else {
    [1, "STR_Company_Hired_Failed"] remoteExecCall ["life_fnc_broadcast", _owner];
}; 
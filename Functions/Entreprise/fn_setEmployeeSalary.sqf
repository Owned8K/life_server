#include "\life_server\script_macros.hpp"
/*
    File: fn_setEmployeeSalary.sqf
    Author: Gemini
    Description: Modifie le salaire d'un employé
*/

params [
    ["_owner", objNull, [objNull]],
    ["_employeeUID", "", [""]],
    ["_newSalary", 0, [0]]
];

if (isNull _owner || _employeeUID isEqualTo "" || _newSalary < 0) exitWith {};

private _ownerUID = getPlayerUID _owner;

// Vérifier que le joueur est bien propriétaire
private _query = format ["SELECT id FROM companies WHERE owner_uid='%1' LIMIT 1", _ownerUID];
private _queryResult = [_query,2] call DB_fnc_asyncCall;

if (_queryResult isEqualTo []) exitWith {
    [1, "STR_Company_NotOwner"] remoteExecCall ["life_fnc_broadcast", _owner];
};

private _companyId = _queryResult select 0;

// Récupérer les infos de l'employé
_query = format ["SELECT employee_name FROM company_employees WHERE company_id=%1 AND employee_uid='%2'", _companyId, _employeeUID];
_queryResult = [_query,2] call DB_fnc_asyncCall;

if (_queryResult isEqualTo []) exitWith {
    [1, "STR_Company_NotEmployee"] remoteExecCall ["life_fnc_broadcast", _owner];
};

private _employeeName = _queryResult select 0;

// Mettre à jour le salaire
_query = format ["UPDATE company_employees SET salary=%1 WHERE company_id=%2 AND employee_uid='%3'", _newSalary, _companyId, _employeeUID];
_queryResult = [_query,1] call DB_fnc_asyncCall;

if (_queryResult) then {
    // Rafraîchir les données pour tous les joueurs concernés
    [_owner] call TON_fnc_fetchCompanyData;
    
    // Notifier le propriétaire et l'employé
    [1, format [localize "STR_Company_Salary_Success", _employeeName, [_newSalary] call life_fnc_numberText]] remoteExecCall ["life_fnc_broadcast", _owner];
    
    private _employee = [_employeeUID] call TON_fnc_getPlayerObj;
    if !(isNull _employee) then {
        [1, format [localize "STR_Company_Salary_Notice", name _owner, [_newSalary] call life_fnc_numberText]] remoteExecCall ["life_fnc_broadcast", _employee];
    };
} else {
    [1, "STR_Company_Salary_Failed"] remoteExecCall ["life_fnc_broadcast", _owner];
}; 
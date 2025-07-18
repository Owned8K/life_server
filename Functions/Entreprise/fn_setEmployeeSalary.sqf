#include "\life_server\script_macros.hpp"
/*
    File: fn_setEmployeeSalary.sqf
    Author: Your Name
    
    Description:
    Met à jour le rôle (qui servira de salaire) d'un employé dans la table company_employees
*/

params [
    ["_companyId", 0, [0]],
    ["_employeeUID", "", [""]],
    ["_salary", 0, [0]],
    ["_owner", objNull, [objNull]]
];

if (_companyId isEqualTo 0 || _employeeUID isEqualTo "" || isNull _owner) exitWith {
    diag_log "SET_SALARY: Paramètres invalides";
};

// Convertir le salaire en chaîne pour le stocker dans le champ 'role'
private _salaryStr = format ["salary_%1", _salary];

// Mettre à jour le rôle/salaire de l'employé
private _query = format ["UPDATE company_employees SET role='%1' WHERE company_id='%2' AND player_uid='%3'", _salaryStr, _companyId, _employeeUID];
[_query, 1] call DB_fnc_asyncCall;

// Notifier le propriétaire
[1, format ["Le salaire a été défini à $%1", [_salary] call life_fnc_numberText]] remoteExecCall ["life_fnc_broadcast", owner _owner];

// Trouver l'employé et le notifier
private _employee = objNull;
{
    if (getPlayerUID _x isEqualTo _employeeUID) exitWith {
        _employee = _x;
    };
} forEach playableUnits;

if !(isNull _employee) then {
    [1, format ["Votre salaire a été fixé à $%1 par %2", [_salary] call life_fnc_numberText, name _owner]] remoteExecCall ["life_fnc_broadcast", owner _employee];
};

// Mettre à jour la liste des employés pour le propriétaire
[] remoteExec ["life_fnc_updateEmployeeCombo", owner _owner]; 
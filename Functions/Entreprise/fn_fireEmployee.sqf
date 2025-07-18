#include "\life_server\script_macros.hpp"
/*
    File: fn_fireEmployee.sqf
    Author: Your Name
    
    Description:
    Supprime un employé de la table company_employees
*/

params [
    ["_companyId", 0, [0]],
    ["_employeeUID", "", [""]],
    ["_owner", objNull, [objNull]]
];

if (_companyId isEqualTo 0 || _employeeUID isEqualTo "" || isNull _owner) exitWith {
    diag_log "FIRE_EMPLOYEE: Paramètres invalides";
};

// Supprimer l'employé de la base de données
private _query = format ["DELETE FROM company_employees WHERE company_id='%1' AND player_uid='%2'", _companyId, _employeeUID];
[_query, 1] call DB_fnc_asyncCall;

// Notifier le propriétaire
[1, "L'employé a été licencié avec succès."] remoteExecCall ["life_fnc_broadcast", owner _owner];

// Trouver le joueur licencié et le notifier
private _employee = objNull;
{
    if (getPlayerUID _x isEqualTo _employeeUID) exitWith {
        _employee = _x;
    };
} forEach playableUnits;

if !(isNull _employee) then {
    [1, format ["Vous avez été licencié par %1", name _owner]] remoteExecCall ["life_fnc_broadcast", owner _employee];
};

// Mettre à jour la liste des employés pour le propriétaire
[] remoteExec ["life_fnc_updateEmployeeCombo", owner _owner]; 
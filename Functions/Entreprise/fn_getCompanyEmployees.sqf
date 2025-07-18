#include "\life_server\script_macros.hpp"
/*
    File: fn_getCompanyEmployees.sqf
    Author: Your Name
    
    Description:
    Récupère la liste des employés d'une entreprise
*/

params [
    ["_companyId", 0, [0]],
    ["_owner", objNull, [objNull]]
];

if (_companyId isEqualTo 0 || isNull _owner) exitWith {
    diag_log "GET_EMPLOYEES: Paramètres invalides";
};

// Récupérer la liste des employés
private _query = format ["SELECT player_uid, player_name, role FROM company_employees WHERE company_id='%1'", _companyId];
private _queryResult = [_query, 2] call DB_fnc_asyncCall;

// Envoyer les résultats au client
[_queryResult] remoteExec ["life_fnc_updateEmployeesList", owner _owner]; 
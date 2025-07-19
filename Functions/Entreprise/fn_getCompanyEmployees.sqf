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

diag_log format ["[COMPANY] Getting employees for company ID: %1", _companyId];
diag_log format ["[COMPANY] Owner: %1", _owner];
diag_log format ["[COMPANY] Owner ID: %1", owner _owner];

// Récupérer la liste des employés
private _query = format ["SELECT player_uid, player_name, role FROM company_employees WHERE company_id='%1'", _companyId];
diag_log format ["[COMPANY] Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;

diag_log format ["[COMPANY] Found %1 employees", count _queryResult];
diag_log format ["[COMPANY] Query result: %1", _queryResult];

// Envoyer les résultats au client
[_queryResult] remoteExecCall ["life_fnc_updateEmployeeComboList", owner _owner];
diag_log format ["[COMPANY] Sent results to client ID: %1", owner _owner]; 
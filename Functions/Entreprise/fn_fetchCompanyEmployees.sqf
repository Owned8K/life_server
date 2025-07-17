#include "\life_server\script_macros.hpp"
/*
    File: fn_fetchCompanyEmployees.sqf
    Author: Your Name
    Description: Récupère la liste des employés d'une entreprise
*/

params [
    ["_companyId", "", [""]],
    ["_player", objNull, [objNull]]
];

if (_companyId isEqualTo "" || isNull _player) exitWith {};

private _query = format ["SELECT player_name, player_uid, role FROM company_employees WHERE company_id='%1'", _companyId];
private _queryResult = [_query, 2] call DB_fnc_asyncCall;

// Envoyer les résultats au client
[_queryResult] remoteExecCall ["life_fnc_updateCompanyEmployees", owner _player]; 
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

// Formater les données des employés
private _formattedEmployees = [];

// Vérifier si _queryResult est un tableau de tableaux ou un tableau simple
if (count _queryResult > 0) then {
    if (_queryResult select 0 isEqualType []) then {
        // C'est un tableau de tableaux (plusieurs employés)
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
                diag_log format ["[COMPANY] Formatted employee - UID: %1, Name: %2, Salary: %3", _empUID, _empName, _salary];
            };
        } forEach _queryResult;
    } else {
        // C'est un tableau simple (un seul employé)
        if (count _queryResult >= 3) then {
            _queryResult params [
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
            diag_log format ["[COMPANY] Formatted single employee - UID: %1, Name: %2, Salary: %3", _empUID, _empName, _salary];
        };
    };
};

diag_log format ["[COMPANY] Formatted employees: %1", _formattedEmployees];

// Envoyer les résultats au client
[_formattedEmployees] remoteExecCall ["life_fnc_updateEmployeeComboList", owner _owner];
diag_log format ["[COMPANY] Sent formatted results to client ID: %1", owner _owner]; 
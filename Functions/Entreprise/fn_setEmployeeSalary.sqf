#include "\life_server\script_macros.hpp"
/*
    File: fn_setEmployeeSalary.sqf
    Author: Your Name
    
    Description:
    Met à jour le rôle (qui servira de salaire) d'un employé et enregistre le paiement
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

diag_log format ["[COMPANY] Setting salary for employee UID: %1 in company %2 to $%3", _employeeUID, _companyId, _salary];

// Récupérer le nom de l'employé
private _query = format ["SELECT player_name FROM company_employees WHERE company_id='%1' AND player_uid='%2'", _companyId, _employeeUID];
diag_log format ["[COMPANY] Query for employee name: %1", _query];
private _result = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Query result: %1", _result];

if (_result isEqualTo []) exitWith {
    diag_log "[COMPANY] Employee not found in database";
    [1, "Employé non trouvé"] remoteExecCall ["life_fnc_broadcast", owner _owner];
};

private _employeeName = "";
if (count _result > 0) then {
    if (_result select 0 isEqualType []) then {
        // Si c'est un tableau de tableaux
        _employeeName = (_result select 0) select 0;
    } else {
        // Si c'est un tableau simple
        _employeeName = _result select 0;
    };
};

diag_log format ["[COMPANY] Employee name found: %1", _employeeName];

// Convertir le salaire en chaîne pour le stocker dans le champ 'role'
private _salaryStr = format ["salary_%1", _salary];
diag_log format ["[COMPANY] Salary string: %1", _salaryStr];

// Mettre à jour le rôle/salaire de l'employé
_query = format ["UPDATE company_employees SET role='%1' WHERE company_id='%2' AND player_uid='%3'", _salaryStr, _companyId, _employeeUID];
diag_log format ["[COMPANY] Update query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

// Enregistrer le paiement dans l'historique
_query = format ["INSERT INTO company_payments (company_id, player_uid, player_name, amount) VALUES ('%1', '%2', '%3', '%4')", 
    _companyId, _employeeUID, _employeeName, _salary];
diag_log format ["[COMPANY] Payment history query: %1", _query];
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

// Forcer la mise à jour des données de l'entreprise
[_owner] call TON_fnc_fetchCompanyData;

// Mettre à jour les listes
[] remoteExec ["life_fnc_updateEmployeeCombo", owner _owner];
[] remoteExec ["life_fnc_updatePaymentHistory", owner _owner]; 
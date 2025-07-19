#include "\life_server\script_macros.hpp"
/*
    File: fn_setEmployeeSalary.sqf
    Author: Your Name
    
    Description:
    Met à jour le salaire d'un employé et effectue le transfert d'argent
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

// Vérifier le solde de l'entreprise
private _query = format ["SELECT bank FROM companies WHERE id='%1'", _companyId];
private _companyResult = [_query, 2] call DB_fnc_asyncCall;

if (_companyResult isEqualTo []) exitWith {
    diag_log "[COMPANY] Company not found in database";
    [1, "Erreur: Entreprise non trouvée"] remoteExecCall ["life_fnc_broadcast", owner _owner];
};

// Le résultat est déjà un nombre
private _companyBank = _companyResult select 0;
diag_log format ["[COMPANY] Company bank balance: $%1", _companyBank];

if (_companyBank < _salary) exitWith {
    diag_log format ["[COMPANY] Not enough money in company bank ($%1 needed, $%2 available)", _salary, _companyBank];
    [1, format ["Fonds insuffisants. Il manque $%1", [(_salary - _companyBank)] call life_fnc_numberText]] remoteExecCall ["life_fnc_broadcast", owner _owner];
};

// Récupérer le nom et les données bancaires de l'employé
_query = format ["SELECT name, bankacc FROM players WHERE pid='%1'", _employeeUID];
diag_log format ["[COMPANY] Player query: %1", _query];
private _playerResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Player query result: %1", _playerResult];

if (_playerResult isEqualTo []) exitWith {
    diag_log "[COMPANY] Employee not found in players database";
    [1, "Employé non trouvé"] remoteExecCall ["life_fnc_broadcast", owner _owner];
};

private _employeeName = _playerResult select 0;
private _employeeBank = _playerResult select 1;

diag_log format ["[COMPANY] Employee found: %1, Current bank: $%2", _employeeName, _employeeBank];

// Mettre à jour le compte bancaire de l'employé
private _newEmployeeBank = _employeeBank + _salary;
_query = format ["UPDATE players SET bankacc='%1' WHERE pid='%2'", [_newEmployeeBank] call DB_fnc_numberSafe, _employeeUID];
diag_log format ["[COMPANY] Update player bank query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

// Mettre à jour le compte de l'entreprise
private _newCompanyBank = _companyBank - _salary;
_query = format ["UPDATE companies SET bank='%1' WHERE id='%2'", [_newCompanyBank] call DB_fnc_numberSafe, _companyId];
diag_log format ["[COMPANY] Update company bank query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

// Convertir le salaire en chaîne pour le stocker dans le champ 'role'
private _salaryStr = format ["salary_%1", _salary];
diag_log format ["[COMPANY] Salary string: %1", _salaryStr];

// Mettre à jour le rôle/salaire de l'employé
_query = format ["UPDATE company_employees SET role='%1' WHERE company_id='%2' AND player_uid='%3'", _salaryStr, _companyId, _employeeUID];
diag_log format ["[COMPANY] Update role query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

// Enregistrer le paiement dans l'historique
_query = format ["INSERT INTO company_payments (company_id, player_uid, player_name, amount) VALUES ('%1', '%2', '%3', '%4')", 
    _companyId, _employeeUID, _employeeName, _salary];
diag_log format ["[COMPANY] Payment history query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

// Notifier le propriétaire
[1, format ["Salaire de $%1 versé à %2", [_salary] call life_fnc_numberText, _employeeName]] remoteExecCall ["life_fnc_broadcast", owner _owner];

// Si le joueur est en ligne, le notifier aussi
private _employee = objNull;
{
    if (getPlayerUID _x isEqualTo _employeeUID) exitWith {
        _employee = _x;
    };
} forEach playableUnits;

if !(isNull _employee) then {
    [1, format ["Vous avez reçu votre salaire de $%1", [_salary] call life_fnc_numberText]] remoteExecCall ["life_fnc_broadcast", owner _employee];
};

// Forcer la mise à jour des données de l'entreprise
[_owner] call TON_fnc_fetchCompanyData;

// Mettre à jour les listes
[] remoteExecCall ["life_fnc_updateEmployeeCombo", owner _owner];
[] remoteExecCall ["life_fnc_updatePaymentHistory", owner _owner];

diag_log format ["[COMPANY] Salary payment completed - Amount: $%1, From: Company %2, To: %3", _salary, _companyId, _employeeName]; 
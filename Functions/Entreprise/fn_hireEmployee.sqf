#include "\life_server\script_macros.hpp"
/*
    File: fn_hireEmployee.sqf
    Author: Your Name
    
    Description:
    Gère l'embauche d'un employé dans une entreprise
*/

params [
    ["_companyId", 0, [0]],
    ["_playerUID", "", [""]],
    ["_playerName", "", [""]],
    ["_owner", objNull, [objNull]]
];

if (_companyId isEqualTo 0 || _playerUID isEqualTo "" || _playerName isEqualTo "" || isNull _owner) exitWith {
    diag_log "HIRE_EMPLOYEE: Paramètres invalides";
};

private _ownerUID = getPlayerUID _owner;

// Vérifier si le joueur est déjà employé
private _query = format ["SELECT COUNT(*) FROM company_employees WHERE player_uid='%1'", _playerUID];
private _result = [_query, 2] call DB_fnc_asyncCall;

if (_result isEqualType [] && {count _result > 0}) then {
    if ((_result select 0) > 0) exitWith {
        [1, "Ce joueur est déjà employé dans une entreprise."] remoteExecCall ["life_fnc_broadcast", owner _owner];
    };
    
    // Insérer le nouvel employé
    _query = format ["INSERT INTO company_employees (company_id, player_uid, player_name, role) VALUES ('%1', '%2', '%3', 'employee')",
        _companyId,
        _playerUID,
        _playerName
    ];
    [_query, 1] call DB_fnc_asyncCall;
    
    // Notifier le propriétaire
    [1, format ["Vous avez embauché %1 avec succès!", _playerName]] remoteExecCall ["life_fnc_broadcast", owner _owner];
    
    // Trouver le joueur embauché et le notifier
    private _player = objNull;
    {
        if (getPlayerUID _x isEqualTo _playerUID) exitWith {
            _player = _x;
        };
    } forEach playableUnits;
    
    if !(isNull _player) then {
        [1, format ["Vous avez été embauché par %1!", name _owner]] remoteExecCall ["life_fnc_broadcast", owner _player];
    };
    
    // Mettre à jour la liste des employés
    [] remoteExec ["life_fnc_updateEmployeeList", owner _owner];
} else {
    diag_log "HIRE_EMPLOYEE: Erreur lors de la vérification de l'employé";
    [1, "Une erreur s'est produite lors de l'embauche."] remoteExecCall ["life_fnc_broadcast", owner _owner];
}; 
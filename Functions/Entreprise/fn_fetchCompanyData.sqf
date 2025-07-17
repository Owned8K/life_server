#include "\life_server\script_macros.hpp"
/*
    File: fn_fetchCompanyData.sqf
    Author: Your Name
    Description: Récupère les données de l'entreprise depuis la base de données
*/

params [
    ["_player", objNull, [objNull]],
    ["_companyId", "", [""]]
];

if (isNull _player || _companyId isEqualTo "") exitWith {};

// Requête adaptée à la structure de table existante
private _query = format ["SELECT id, name, owner_name, owner_uid, bank FROM companies WHERE id='%1'", _companyId];
private _queryResult = [_query, 2] call DB_fnc_asyncCall;

if (_queryResult isEqualTo []) exitWith {
    [[], _player] remoteExecCall ["life_fnc_companyDataReceived", (owner _player)];
};

// Récupérer les employés
private _queryEmployees = format ["SELECT player_name, player_uid, role FROM company_employees WHERE company_id='%1'", _companyId];
private _employees = [_queryEmployees, 2, true] call DB_fnc_asyncCall;

// Formater les données
private _companyData = [
    (_queryResult select 0), // ID
    (_queryResult select 1), // Nom de l'entreprise
    (_queryResult select 2), // Nom du propriétaire
    (_queryResult select 3), // UID du propriétaire
    parseNumber (_queryResult select 4), // Balance
    _employees // Liste des employés
];

// Envoyer les données au client
[_companyData, _player] remoteExecCall ["life_fnc_companyDataReceived", (owner _player)];

// Log
diag_log format ["[COMPANY DATA] Fetched data for company %1 requested by %2 (%3)", _companyId, name _player, getPlayerUID _player]; 
#include "..\..\..\script_macros.hpp"
/*
    File: fn_dbCompanyCreate.sqf
    Author: Gemini
    Description: Logique serveur pour créer une entreprise et accorder la licence.
*/
params ["_companyName", "_companyClass", "_player"];
private _uid = getPlayerUID _player;
private _playerName = name _player;

if (!isServer) exitWith {};

// --- Validation Côté Serveur (sécurité) ---
private _price = M_CONFIG(getNumber, "CfgCompanies", _companyClass, "price");
private _licenseVar = M_CONFIG(getText, "CfgCompanies", _companyClass, "license");
private _licenseName = format["license_civ_%1", _licenseVar];

if ((_player getVariable ["life_atmbank", 0]) < _price) exitWith {
    [_player, "hint", localize "STR_NOTF_NotEnoughMoney_2"] remoteExecCall ["call", _player];
};
if (_player getVariable [_licenseName, false]) exitWith {
    [_player, "hint", localize "STR_CompanyCreate_AlreadyOwner"] remoteExecCall ["call", _player];
};

// Vérifie si le nom est unique
_companyNameSanitized = _companyName call BIS_fnc_escapeString;
private _query = format ["SELECT id FROM companies WHERE name='%1'", _companyNameSanitized];
private _queryResult = [_query, 2, true] call extDB_fnc_async;

if (count _queryResult > 0) exitWith {
    [_player, "hint", localize "STR_CompanyCreate_NameTaken"] remoteExecCall ["call", _player];
};

// --- Exécution de l'Achat ---
private _currentBank = _player getVariable ["life_atmbank", 0];
_player setVariable ["life_atmbank", (_currentBank - _price), true];

_player setVariable [_licenseName, true, true];

private _insertQuery = format ["INSERT INTO companies (name, owner_name, owner_uid, bank) VALUES ('%1', '%2', '%3', 0)", _companyNameSanitized, _playerName, _uid];
[_insertQuery, 1] call extDB_fnc_async;

// Synchronisation de l'argent côté client
[_player, "life_atmbank", (_currentBank - _price)] remoteExecCall ["life_fnc_setVariable", _player];

private _successMsg = format[localize "STR_CompanyCreate_Success", _companyName];
[_player, "hint", _successMsg] remoteExecCall ["call", _player]; 
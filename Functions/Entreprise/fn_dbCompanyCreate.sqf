#include "\life_server\script_macros.hpp"
/*
    File: fn_dbCompanyCreate.sqf
    Author: Gemini
    Description: Logique serveur pour créer une entreprise et accorder la licence.
*/
private ["_query","_queryResult","_currentBank","_successMsg"];
params [
    ["_companyName","",[""]],
    ["_companyClass","",[""]],
    ["_player",objNull,[objNull]]
];

if (isNull _player || _companyName isEqualTo "" || _companyClass isEqualTo "") exitWith {};
if (!isServer) exitWith {};

private _uid = getPlayerUID _player;
private _playerName = name _player;

// --- Validation Côté Serveur (sécurité) ---
private _price = M_CONFIG(getNumber, "CfgCompanies", _companyClass, "price");
private _licenseVar = M_CONFIG(getText, "CfgCompanies", _companyClass, "license");
private _licenseName = format["license_civ_%1", _licenseVar];

if ((_player getVariable ["life_atmbank", 0]) < _price) exitWith {
    ["STR_NOTF_NotEnoughMoney_2"] remoteExecCall ["life_fnc_broadcast", _player];
};
if (_player getVariable [_licenseName, false]) exitWith {
    ["STR_CompanyCreate_AlreadyOwner"] remoteExecCall ["life_fnc_broadcast", _player];
};

// Vérifie si le nom est unique
private _companyNameSanitized = [_companyName] call DB_fnc_mresString;
_query = format ["SELECT id FROM companies WHERE name='%1'", _companyNameSanitized];
_queryResult = [_query, 2] call DB_fnc_asyncCall;

if (EXTDB_SETTING(getNumber,"DebugMode") isEqualTo 1) then {
    diag_log format ["Company creation query: %1", _query];
    diag_log format ["Query result: %1", _queryResult];
};

if (count _queryResult > 0) exitWith {
    ["STR_CompanyCreate_NameTaken"] remoteExecCall ["life_fnc_broadcast", _player];
};

// --- Exécution de l'Achat ---
_currentBank = _player getVariable ["life_atmbank", 0];
_player setVariable ["life_atmbank", (_currentBank - _price), true];
_player setVariable [_licenseName, true, true];

// Insertion en base de données
_query = format ["INSERT INTO companies (name, owner_name, owner_uid, bank) VALUES ('%1', '%2', '%3', 0)", _companyNameSanitized, _playerName, _uid];
[_query, 1] call DB_fnc_asyncCall;

if (EXTDB_SETTING(getNumber,"DebugMode") isEqualTo 1) then {
    diag_log format ["Company insert query: %1", _query];
};

// Synchronisation côté client
[_player, "life_atmbank", (_currentBank - _price)] remoteExecCall ["life_fnc_setVariable", _player];

_successMsg = format[localize "STR_CompanyCreate_Success", _companyName];
[_successMsg] remoteExecCall ["life_fnc_broadcast", _player]; 
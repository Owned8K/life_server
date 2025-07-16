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

diag_log format ["[ENTREPRISE] fn_dbCompanyCreate appelé avec: companyName=%1, companyClass=%2, player=%3", _companyName, _companyClass, name _player];

if (isNull _player || _companyName isEqualTo "" || _companyClass isEqualTo "") exitWith {
    diag_log format ["[ENTREPRISE] ERREUR: Paramètres invalides - player=%1, companyName=%2, companyClass=%3", _player, _companyName, _companyClass];
};
if (!isServer) exitWith {
    diag_log "[ENTREPRISE] ERREUR: Script non exécuté côté serveur";
};

private _uid = getPlayerUID _player;
private _playerName = name _player;
diag_log format ["[ENTREPRISE] Joueur identifié: %1 (UID: %2)", _playerName, _uid];

// --- Récupération de l'argent depuis la base de données ---
private _playerQuery = format ["SELECT bankacc FROM players WHERE pid='%1'", _uid];
private _playerResult = [_playerQuery, 2] call DB_fnc_asyncCall;

diag_log format ["[ENTREPRISE] Résultat requête SQL: %1", _playerResult];
diag_log format ["[ENTREPRISE] Type du résultat: %1", typeName _playerResult];
diag_log format ["[ENTREPRISE] Taille du résultat: %1", count _playerResult];

if (count _playerResult == 0) exitWith {
    diag_log format ["[ENTREPRISE] ERREUR: Joueur %1 non trouvé en base", _uid];
    ["Erreur: Joueur non trouvé en base de données"] remoteExecCall ["life_fnc_broadcast", _player];
};

// Vérification du format avant d'accéder aux données
if (typeName _playerResult != "ARRAY" || count _playerResult == 0) exitWith {
    diag_log format ["[ENTREPRISE] ERREUR: Format de résultat invalide: %1", _playerResult];
    ["Erreur: Format de données invalide"] remoteExecCall ["life_fnc_broadcast", _player];
};

// Le résultat est un array simple avec le montant directement
private _playerBank = _playerResult select 0;
diag_log format ["[ENTREPRISE] Argent récupéré depuis BDD: %1 (type: %2)", _playerBank, typeName _playerBank];

// Conversion en nombre si nécessaire
if (typeName _playerBank == "STRING") then {
    _playerBank = parseNumber _playerBank;
    diag_log format ["[ENTREPRISE] Argent après conversion: %1", _playerBank];
};

// --- Validation Côté Serveur (sécurité) ---
private _price = M_CONFIG(getNumber, "CfgCompanies", _companyClass, "price");
private _licenseVar = M_CONFIG(getText, "CfgCompanies", _companyClass, "license");
private _licenseName = format["license_civ_%1", _licenseVar];

diag_log format ["[ENTREPRISE] Configuration entreprise: prix=%1, licence=%2, variable=%3", _price, _licenseVar, _licenseName];
diag_log format ["[ENTREPRISE] Argent joueur: %1 (requis: %2)", _playerBank, _price];

if (_playerBank < _price) exitWith {
    diag_log format ["[ENTREPRISE] ECHEC: Pas assez d'argent (%1 < %2)", _playerBank, _price];
    ["STR_NOTF_NotEnoughMoney_2"] remoteExecCall ["life_fnc_broadcast", _player];
};

private _hasLicense = _player getVariable [_licenseName, false];
diag_log format ["[ENTREPRISE] Licence existante (%1): %2", _licenseName, _hasLicense];

if (_hasLicense) exitWith {
    diag_log "[ENTREPRISE] ECHEC: Joueur possède déjà cette licence d'entreprise";
    ["STR_CompanyCreate_AlreadyOwner"] remoteExecCall ["life_fnc_broadcast", _player];
};

// Vérifie si le nom est unique
private _companyNameSanitized = [_companyName] call DB_fnc_mresString;
_query = format ["SELECT id FROM companies WHERE name='%1'", _companyNameSanitized];
diag_log format ["[ENTREPRISE] Vérification unicité nom: %1", _query];

_queryResult = [_query, 2] call DB_fnc_asyncCall;

if (EXTDB_SETTING(getNumber,"DebugMode") isEqualTo 1) then {
    diag_log format ["Company creation query: %1", _query];
    diag_log format ["Query result: %1", _queryResult];
};

diag_log format ["[ENTREPRISE] Résultat vérification nom: %1", _queryResult];

if (count _queryResult > 0) exitWith {
    diag_log format ["[ENTREPRISE] ECHEC: Nom d'entreprise déjà pris (%1)", _companyName];
    ["STR_CompanyCreate_NameTaken"] remoteExecCall ["life_fnc_broadcast", _player];
};

// --- Exécution de l'Achat ---
diag_log "[ENTREPRISE] Début de l'exécution de l'achat";

_currentBank = _playerBank;
_player setVariable ["life_atmbank", (_currentBank - _price), true];
_player setVariable [_licenseName, true, true];

diag_log format ["[ENTREPRISE] Argent débité: %1 -> %2", _currentBank, (_currentBank - _price)];
diag_log format ["[ENTREPRISE] Licence attribuée: %1 = true", _licenseName];

// Insertion en base de données
_query = format ["INSERT INTO companies (name, owner_name, owner_uid, bank) VALUES ('%1', '%2', '%3', 0)", _companyNameSanitized, _playerName, _uid];
diag_log format ["[ENTREPRISE] Insertion en base: %1", _query];

[_query, 1] call DB_fnc_asyncCall;

if (EXTDB_SETTING(getNumber,"DebugMode") isEqualTo 1) then {
    diag_log format ["Company insert query: %1", _query];
};

// Mise à jour de l'argent en base de données
[_uid, civilian, (_currentBank - _price), 1] call DB_fnc_updatePartial;
diag_log format ["[ENTREPRISE] Mise à jour argent en BDD: %1", (_currentBank - _price)];

// Notification de succès et synchronisation côté client
_successMsg = format[localize "STR_CompanyCreate_Success", _companyName];
[_successMsg, (_currentBank - _price)] remoteExecCall ["life_fnc_companyCreated", _player];

diag_log format ["[ENTREPRISE] SUCCES: Entreprise '%1' créée pour %2", _companyName, _playerName]; 
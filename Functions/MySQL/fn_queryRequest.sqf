#include "\life_server\script_macros.hpp"
/*
    File: fn_queryRequest.sqf
    Author: Bryan "Tonic" Boardwine

    Description:
    Handles the incoming request and sends an asynchronous query 
    request to the database.

    Return:
    ARRAY - If array has 0 elements it should be handled as an error in client-side files.
    STRING - The request had invalid handles or an unknown error and is logged to the RPT.
*/
private ["_uid","_side","_query","_queryResult","_tickTime","_tmp"];
_uid = [_this,0,"",[""]] call BIS_fnc_param;
_side = [_this,1,sideUnknown,[civilian]] call BIS_fnc_param;
_ownerID = [_this,2,objNull,[objNull]] call BIS_fnc_param;

if (isNull _ownerID) exitWith {};
_ownerID = owner _ownerID;

diag_log format ["[QUERY REQUEST] Starting query for player UID: %1, Side: %2", _uid, _side];

_query = switch (_side) do {
    case west: {format ["SELECT pid, name, cash, bankacc, adminlevel, donorlevel, cop_licenses, coplevel, cop_gear, blacklist FROM players WHERE pid='%1'",_uid];};
    case civilian: {format ["SELECT pid, name, cash, bankacc, adminlevel, donorlevel, civ_licenses, arrested, civ_gear FROM players WHERE pid='%1'",_uid];};
    case independent: {format ["SELECT pid, name, cash, bankacc, adminlevel, donorlevel, med_licenses, mediclevel, med_gear FROM players WHERE pid='%1'",_uid];};
};

_tickTime = diag_tickTime;
_queryResult = [_query,2] call DB_fnc_asyncCall;

diag_log format ["[QUERY REQUEST] Initial query result: %1", _queryResult];

if (_queryResult isEqualType "") exitWith {
    diag_log "[QUERY REQUEST] Error: Query returned string instead of array";
    [] remoteExecCall ["SOCK_fnc_insertPlayerInfo",_ownerID];
};

if (_queryResult isEqualTo []) exitWith {
    diag_log "[QUERY REQUEST] Error: Empty query result";
    [] remoteExecCall ["SOCK_fnc_insertPlayerInfo",_ownerID];
};

//Blah conversion thing from a2net->extdb3
private _tmp = _queryResult select 2;
_queryResult set[2,[_tmp] call DB_fnc_numberSafe];
_tmp = _queryResult select 3;
_queryResult set[3,[_tmp] call DB_fnc_numberSafe];

//Parse licenses (Always index 6)
_queryResult set[6,[_queryResult select 6] call DB_fnc_mresToArray];

//Convert tinyint to boolean
_queryResult set[7,([_queryResult select 7] call DB_fnc_bool)];

//Parse gear (Always index 8)
_queryResult set[8,[_queryResult select 8] call DB_fnc_mresToArray];

// Si c'est un civil, on vérifie s'il a une entreprise
if (_side isEqualTo civilian) then {
    private _companyQuery = format ["SELECT id, name, bank FROM companies WHERE owner_uid='%1' LIMIT 1", _uid];
    private _companyResult = [_companyQuery,2] call DB_fnc_asyncCall;
    
    private _company = [];
    if (!(_companyResult isEqualTo [])) then {
        _company = _companyResult;
        diag_log format ["[QUERY REQUEST] Found company for %1: %2", _uid, _company];
    };
    _queryResult pushBack _company;
};

diag_log format ["[QUERY REQUEST] Final data to send: %1", _queryResult];
[_queryResult] remoteExecCall ["SOCK_fnc_requestReceived", _ownerID];

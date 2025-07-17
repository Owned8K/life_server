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

_query = switch (_side) do {
    case west: {format ["SELECT playerid, name, cash, bankacc, adminlevel, donorlevel, cop_licenses, coplevel, cop_gear, blacklist FROM players WHERE playerid='%1'",_uid];};
    case civilian: {
        format ["SELECT players.playerid, name, cash, bankacc, adminlevel, donorlevel, civ_licenses, arrested, civ_gear, companies.id as company_id, companies.name as company_name, companies.bank as company_bank FROM players LEFT JOIN companies ON players.playerid=companies.owner_uid WHERE players.playerid='%1'",_uid];
    };
    case independent: {format ["SELECT playerid, name, cash, bankacc, adminlevel, donorlevel, med_licenses, mediclevel, med_gear FROM players WHERE playerid='%1'",_uid];};
};

_tickTime = diag_tickTime;
_queryResult = [_query,2] call DB_fnc_asyncCall;

if (_queryResult isEqualType "") exitWith {
    [] remoteExecCall ["SOCK_fnc_insertPlayerInfo",_ownerID];
};

if (_queryResult isEqualTo []) exitWith {
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

//Session ID
_queryResult pushBack getPlayerUID _ownerID;

if (_side isEqualTo civilian) then {
    private _company = [];
    if (!isNil {_queryResult select 9}) then {
        _company = [
            _queryResult select 9,  // ID
            _queryResult select 10, // Name
            _queryResult select 11  // Bank
        ];
        diag_log format ["[QUERY REQUEST] Found company for %1: %2", _uid, _company];
    };
    _queryResult pushBack _company;
};

[_queryResult,"SOCK_fnc_requestReceived",_ownerID,false] call life_fnc_MP;

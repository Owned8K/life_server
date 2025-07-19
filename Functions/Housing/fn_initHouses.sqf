#include "\life_server\script_macros.hpp"
/*
    File: fn_initHouses.sqf
    Author: Bryan "Tonic" Boardwine
    Description:
    Initalizes house setup when player joins the server.
*/
private ["_queryResult","_query","_count"];

_queryResult = ["SELECT COUNT(*) FROM houses WHERE owned='1'",2] call DB_fnc_asyncCall;
if (_queryResult isEqualTo []) exitWith {diag_log "Error getting house count from DB"};

_count = _queryResult select 0;
if (_count isEqualTo 0) exitWith {diag_log "No houses found in DB"};

for "_x" from 0 to _count step 10 do {
    _query = format ["SELECT houses.id, houses.pid, houses.pos, players.name, houses.garage FROM houses INNER JOIN players WHERE houses.owned='1' AND houses.pid = players.pid LIMIT %1,10",_x];
    _queryResult = [_query,2,true] call DB_fnc_asyncCall;
    if (_queryResult isEqualTo []) exitWith {};
    
    {
        _pos = call compile format ["%1",_x select 2];
        _house = nearestObject [_pos, "House"];
        if (!isNull _house) then {
            _house setVariable ["house_owner",[_x select 1,_x select 3],true];
            _house setVariable ["house_id",_x select 0,true];
            _house setVariable ["locked",true,true]; //Lock up all the stuff.
            if (_x select 4 isEqualTo 1) then {
                _house setVariable ["garageBought",true,true];
            };
            _numOfDoors = getNumber(configFile >> "CfgVehicles" >> (typeOf _house) >> "numberOfDoors");
            for "_i" from 1 to _numOfDoors do {
                _house setVariable [format ["bis_disabled_Door_%1",_i],1,true];
            };
        };
    } forEach _queryResult;
};

// Blacklisted houses handling
private ["_blacklistedHouses","_blacklistedGarages"];
_blacklistedHouses = "count (getArray (_x >> 'garageBlacklists')) > 0" configClasses (missionconfigFile >> "Housing" >> worldName);
_blacklistedGarages = "count (getArray (_x >> 'garageBlacklists')) > 0" configClasses (missionconfigFile >> "Garages" >> worldName);
_blacklistedHouses = _blacklistedHouses apply {configName _x};
_blacklistedGarages = _blacklistedGarages apply {configName _x};

{
    _className = _x;
    _positions = getArray(missionConfigFile >> "Housing" >> worldName >> _className >> "garageBlacklists");
    {
        _obj = nearestObject [_x,_className];
        if (!isNull _obj) then {
            _obj setVariable ["blacklistedGarage",true,true];
        };
    } forEach _positions;
} forEach _blacklistedHouses;

{
    _className = _x;
    _positions = getArray(missionConfigFile >> "Garages" >> worldName >> _className >> "garageBlacklists");
    {
        _obj = nearestObject [_x,_className];
        if (!isNull _obj) then {
            _obj setVariable ["blacklistedGarage",true,true];
        };
    } forEach _positions;
} forEach _blacklistedGarages;

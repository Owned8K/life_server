/*
    File: fn_server_fetchContacts.sqf
    Description: Récupère les contacts du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

private _pid = getPlayerUID _player;
private _query = format ["SELECT id, contact_name, contact_number FROM contacts WHERE owner_pid='%1'", _pid];

[_query, 2, true, _player] call DB_fnc_asyncCall;

// Callback pour envoyer les contacts au client
if (!isNil "_result") then {
    [_result] remoteExecCall ["life_fnc_receiveContacts", _player];
} 
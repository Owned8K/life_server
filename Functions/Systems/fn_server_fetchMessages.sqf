/*
    File: fn_server_fetchMessages.sqf
    Description: Récupère les messages du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

private _pid = getPlayerUID _player;
private _query = format ["SELECT id, sender_pid, content, sent_at, is_read FROM messages WHERE receiver_pid='%1' ORDER BY sent_at DESC LIMIT 50", _pid];

[_query, 2, true, _player] call DB_fnc_asyncCall;

// Callback pour envoyer les messages au client
if (!isNil "_result") then {
    [_result] remoteExecCall ["life_fnc_receiveMessages", _player];
} 
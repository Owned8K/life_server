/*
    File: fn_server_receiveMessage.sqf
    Description: Insère un message dans la table messages.
    Params: [sender_obj, receiver_pid, content]
*/
params [
    ["_sender", objNull, [objNull]],
    ["_receiver", "", [""]],
    ["_content", "", [""]]
];

private _sender_pid = getPlayerUID _sender;
if (_receiver isEqualTo "" || _content isEqualTo "" || _sender_pid isEqualTo "") exitWith {};

[format ["INSERT INTO messages (sender_pid, receiver_pid, content) VALUES('%1', '%2', '%3')", _sender_pid, _receiver, [_content] call DB_fnc_mresString], 1] call DB_fnc_asyncCall; 
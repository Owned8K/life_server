/*
    File: fn_server_addContact.sqf
    Description: Ajoute un contact à la table contacts.
    Params: [player_obj, contact_name, contact_number]
*/
params [
    ["_player", objNull, [objNull]],
    ["_name", "", [""]],
    ["_number", "", [""]]
];

private _pid = getPlayerUID _player;
if (_pid isEqualTo "" || _name isEqualTo "" || _number isEqualTo "") exitWith {};

[format ["INSERT INTO contacts (owner_pid, contact_name, contact_number) VALUES('%1', '%2', '%3')", _pid, [_name] call DB_fnc_mresString, [_number] call DB_fnc_mresString], 1] call DB_fnc_asyncCall; 
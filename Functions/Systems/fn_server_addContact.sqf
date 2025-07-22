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

diag_log format ["[SMARTPHONE][ADD_CONTACT] Appel avec pid=%1, name=%2, number=%3", _pid, _name, _number];
private _sql = format ["INSERT INTO contacts (owner_pid, contact_name, contact_number) VALUES('%1', '%2', '%3')", _pid, [_name] call DB_fnc_mresString, [_number] call DB_fnc_mresString];
diag_log format ["[SMARTPHONE][ADD_CONTACT] SQL: %1", _sql];
[_sql, 1] call DB_fnc_asyncCall; 
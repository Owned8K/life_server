/*
    File: fn_server_addContact.sqf
    Description: Ajoute un contact à la table contacts.
    Params: [player_obj, contact_name, contact_number]
*/

diag_log "=== DÉBUT fn_server_addContact.sqf ===";
diag_log format ["[SMARTPHONE][SERVER] Paramètres reçus: %1", _this];

params [
    ["_player", objNull, [objNull]],
    ["_name", "", [""]],
    ["_number", "", [""]]
];

diag_log format ["[SMARTPHONE][SERVER] Après params: player=%1, name=%2, number=%3", _player, _name, _number];

private _pid = getPlayerUID _player;
if (_pid isEqualTo "" || _name isEqualTo "" || _number isEqualTo "") exitWith {
    diag_log "[SMARTPHONE][SERVER] ERREUR: Paramètres invalides";
};

diag_log format ["[SMARTPHONE][SERVER] PID obtenu: %1", _pid];

// Nettoyer les chaînes avant insertion
private _cleanName = toString(toArray(_name));
private _cleanNumber = toString(toArray(_number));

private _query = format ["INSERT INTO contacts (owner_pid, contact_name, contact_number) VALUES('%1', '%2', '%3')", 
    _pid, 
    _cleanName,
    _cleanNumber
];
diag_log format ["[SMARTPHONE][SERVER] Requête SQL: %1", _query];

[_query, 1] call DB_fnc_asyncCall;
diag_log "=== FIN fn_server_addContact.sqf ===";

// Notifie le client et rafraîchit sa liste
[true] remoteExecCall ["life_fnc_contactAdded", _player]; 
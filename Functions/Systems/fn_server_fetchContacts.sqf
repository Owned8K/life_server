/*
    File: fn_server_fetchContacts.sqf
    Description: Récupère les contacts du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

diag_log "=== DÉBUT fn_server_fetchContacts.sqf ===";

private _pid = getPlayerUID _player;
diag_log format ["[CONTACTS][SERVER] Récupération des contacts pour PID: %1", _pid];

private _query = format ["SELECT id, contact_name, contact_number FROM contacts WHERE owner_pid='%1'", _pid];
diag_log format ["[CONTACTS][SERVER] Query: %1", _query];

private _result = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[CONTACTS][SERVER] Résultat: %1", _result];

// Envoie les contacts au client
[_result] remoteExecCall ["life_fnc_receiveContacts", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
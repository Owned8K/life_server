/*
    File: fn_server_fetchContacts.sqf
    Description: Récupère les contacts du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

diag_log "=== DÉBUT fn_server_fetchContacts.sqf ===";

if (isNull _player) exitWith {
    diag_log "[CONTACTS][SERVER] ERREUR: _player est null";
};

private _pid = getPlayerUID _player;
diag_log format ["[CONTACTS][SERVER] Récupération des contacts pour PID: %1", _pid];

private _query = format ["SELECT id, contact_name, contact_number FROM contacts WHERE owner_pid='%1'", _pid];
diag_log format ["[CONTACTS][SERVER] Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[CONTACTS][SERVER] Résultat brut: %1", _queryResult];

// Traitement du résultat
if (_queryResult isEqualTo []) then {
    diag_log "[CONTACTS][SERVER] Aucun contact trouvé";
    _queryResult = [];
} else {
    // Si on reçoit un seul résultat, on le met dans un tableau
    if ((_queryResult select 0) isEqualType "") then {
        _queryResult = [_queryResult];
        diag_log "[CONTACTS][SERVER] Contact unique converti en tableau";
    };
};

diag_log format ["[CONTACTS][SERVER] Contacts formatés: %1", _queryResult];
diag_log format ["[CONTACTS][SERVER] Envoi de %1 contacts au client", count _queryResult];

// Envoie les contacts au client
[_queryResult] remoteExecCall ["life_fnc_receiveContacts", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
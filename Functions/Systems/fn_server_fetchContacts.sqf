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

// Vérifie si le résultat est un tableau
if (!(_queryResult isEqualType [])) then {
    diag_log "[CONTACTS][SERVER] ERREUR: Résultat n'est pas un tableau";
    _queryResult = [];
};

// Envoie les contacts au client
diag_log format ["[CONTACTS][SERVER] Envoi de %1 contacts au client", count _queryResult];
[_queryResult] remoteExecCall ["life_fnc_receiveContacts", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
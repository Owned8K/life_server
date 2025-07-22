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

private _query = format ["SELECT id, REPLACE(REPLACE(contact_name, '""', ''), '\""', '') as contact_name, REPLACE(REPLACE(contact_number, '""', ''), '\""', '') as contact_number FROM contacts WHERE owner_pid='%1'", _pid];
diag_log format ["[CONTACTS][SERVER] Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[CONTACTS][SERVER] Résultat brut: %1", _queryResult];

// Traitement du résultat
private _contacts = [];
if (!(_queryResult isEqualTo [])) then {
    // Si le résultat est un contact unique (tableau avec 3 éléments: id, name, number)
    if (count _queryResult == 3 && (_queryResult select 1) isEqualType "") then {
        _contacts = [_queryResult];
        diag_log "[CONTACTS][SERVER] Contact unique détecté";
    } else {
        {
            if (_x isEqualType [] && {count _x == 3}) then {
                _contacts pushBack _x;
            };
        } forEach _queryResult;
        diag_log "[CONTACTS][SERVER] Liste de contacts récupérée";
    };
};

diag_log format ["[CONTACTS][SERVER] Contacts formatés: %1", _contacts];
diag_log format ["[CONTACTS][SERVER] Envoi de %1 contacts au client", count _contacts];

// Envoie les contacts au client
[_contacts] remoteExecCall ["life_fnc_receiveContacts", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
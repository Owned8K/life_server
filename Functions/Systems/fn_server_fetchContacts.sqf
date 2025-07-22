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

private _query = format ["SELECT id, contact_name, contact_number FROM contacts WHERE owner_pid='%1' ORDER BY contact_name ASC", _pid];
diag_log format ["[CONTACTS][SERVER] Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[CONTACTS][SERVER] Résultat brut: %1", _queryResult];
diag_log format ["[CONTACTS][SERVER] Type du résultat: %1", typeName _queryResult];
diag_log format ["[CONTACTS][SERVER] Nombre d'éléments: %1", count _queryResult];

// Traitement du résultat
private _contacts = [];
if (!(_queryResult isEqualTo [])) then {
    // Vérifie si c'est un tableau de tableaux (plusieurs contacts) ou un tableau simple (un seul contact)
    if ((_queryResult select 0) isEqualType []) then {
        diag_log "[CONTACTS][SERVER] Traitement de plusieurs contacts";
        {
            _x params [
                ["_id", 0, [0]],
                ["_name", "", [""]],
                ["_number", "", [""]]
            ];
            _contacts pushBack [_id, _name, _number];
            diag_log format ["[CONTACTS][SERVER] Contact ajouté: [%1, %2, %3]", _id, _name, _number];
        } forEach _queryResult;
    } else {
        // Un seul contact
        diag_log "[CONTACTS][SERVER] Traitement d'un contact unique";
        _queryResult params [
            ["_id", 0, [0]],
            ["_name", "", [""]],
            ["_number", "", [""]]
        ];
        _contacts = [[_id, _name, _number]];
        diag_log format ["[CONTACTS][SERVER] Contact unique ajouté: [%1, %2, %3]", _id, _name, _number];
    };
};

diag_log format ["[CONTACTS][SERVER] Contacts finaux: %1", _contacts];
diag_log format ["[CONTACTS][SERVER] Nombre total de contacts: %1", count _contacts];

// Envoie les contacts au client
[_contacts] remoteExecCall ["life_fnc_receiveContacts", _player];
diag_log format ["[CONTACTS][SERVER] RemoteExecCall effectué vers %1", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
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

// Fonction pour nettoyer une chaîne
private _cleanString = {
    params ["_str"];
    if (_str isEqualType "") then {
        private _clean = toString(toArray(_str));
        diag_log format ["[CONTACTS][SERVER] Nettoyage: '%1' -> '%2'", _str, _clean];
        _clean
    } else {
        diag_log format ["[CONTACTS][SERVER] ERREUR: Type invalide pour nettoyage: %1", typeName _str];
        ""
    };
};

// Traitement du résultat
private _contacts = [];
if (!(_queryResult isEqualTo [])) then {
    // Si le résultat est un contact unique (tableau avec 3 éléments: id, name, number)
    if (count _queryResult == 3 && (_queryResult select 1) isEqualType "") then {
        _queryResult params [
            ["_id", 0, [0]],
            ["_name", "", [""]],
            ["_number", "", [""]]
        ];
        private _cleanName = [_name] call _cleanString;
        private _cleanNumber = [_number] call _cleanString;
        _contacts = [[_id, _cleanName, _cleanNumber]];
        diag_log format ["[CONTACTS][SERVER] Contact unique détecté: [%1, %2, %3]", _id, _cleanName, _cleanNumber];
    } else {
        {
            _x params [
                ["_id", 0, [0]],
                ["_name", "", [""]],
                ["_number", "", [""]]
            ];
            private _cleanName = [_name] call _cleanString;
            private _cleanNumber = [_number] call _cleanString;
            _contacts pushBack [_id, _cleanName, _cleanNumber];
            diag_log format ["[CONTACTS][SERVER] Contact ajouté: [%1, %2, %3]", _id, _cleanName, _cleanNumber];
        } forEach _queryResult;
    };
};

diag_log format ["[CONTACTS][SERVER] Contacts nettoyés: %1", _contacts];
diag_log format ["[CONTACTS][SERVER] Envoi de %1 contacts au client", count _contacts];

// Envoie les contacts au client
[_contacts] remoteExecCall ["life_fnc_receiveContacts", _player];

diag_log "=== FIN fn_server_fetchContacts.sqf ==="; 
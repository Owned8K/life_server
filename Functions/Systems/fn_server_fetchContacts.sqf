/*
    File: fn_server_fetchContacts.sqf
    Description: Récupère les contacts du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

if (isNull _player) exitWith {
    diag_log "[CONTACTS][SERVER] ERREUR: _player est null";
};

private _pid = getPlayerUID _player;

// Vérifie d'abord le nombre total de contacts
private _countQuery = format ["SELECT COUNT(*) FROM contacts WHERE owner_pid='%1'", _pid];
private _countResult = [_countQuery, 2] call DB_fnc_asyncCall;

// Récupère les contacts avec le paramètre 2,true pour forcer un tableau de tableaux
private _query = format ["SELECT id, contact_name, contact_number FROM contacts WHERE owner_pid='%1' ORDER BY contact_name ASC", _pid];

private _queryResult = [_query, 2, true] call DB_fnc_asyncCall;
// Traitement du résultat
private _contacts = [];
{
    _x params [
        ["_id", 0, [0]],
        ["_name", "", [""]],
        ["_number", "", [""]]
    ];
    _contacts pushBack [_id, _name, _number];
} forEach _queryResult;


// Envoie les contacts au client
[_contacts] remoteExecCall ["life_fnc_receiveContacts", _player];
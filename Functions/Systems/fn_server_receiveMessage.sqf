/*
    File: fn_server_receiveMessage.sqf
    Description: Insère un message dans la table messages.
    Params: [sender_obj, receiver_pid, content]
*/
params [
    ["_sender", objNull, [objNull]],
    ["_receiver", "", [""]],
    ["_content", "", [""]]
];

diag_log "=== DÉBUT fn_server_receiveMessage.sqf ===";
diag_log format ["[MESSAGES][SERVER] Tentative d'envoi de message: Contenu='%1', Destinataire='%2'", _content, _receiver];

private _sender_pid = getPlayerUID _sender;
if (_receiver isEqualTo "" || _content isEqualTo "" || _sender_pid isEqualTo "") exitWith {
    diag_log "[MESSAGES][SERVER] ERREUR: Paramètres invalides";
    diag_log format ["[MESSAGES][SERVER] sender_pid: %1, receiver: %2, content: %3", _sender_pid, _receiver, _content];
};

// Nettoie et échappe le contenu
private _cleanContent = _content call DB_fnc_mresString;
_cleanContent = [_cleanContent, "'", "''"] call CBA_fnc_replace;
_cleanContent = [_cleanContent, "\", "\\"] call CBA_fnc_replace;

private _query = format ["INSERT INTO messages (sender_pid, receiver_pid, content) VALUES('%1', '%2', '%3')", 
    _sender_pid, 
    _receiver,
    _cleanContent
];

diag_log format ["[MESSAGES][SERVER] Query: %1", _query];
[_query, 1] call DB_fnc_asyncCall;

diag_log "[MESSAGES][SERVER] Message inséré avec succès";
diag_log "=== FIN fn_server_receiveMessage.sqf ==="; 
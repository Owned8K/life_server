/*
    File: fn_server_fetchMessages.sqf
    Description: Récupère les messages du joueur et les renvoie au client.
    Params: [player_obj]
*/
params [["_player", objNull, [objNull]]];

diag_log "=== DÉBUT fn_server_fetchMessages.sqf ===";

if (isNull _player) exitWith {
    diag_log "[MESSAGES][SERVER] ERREUR: _player est null";
};

private _pid = getPlayerUID _player;
diag_log format ["[MESSAGES][SERVER] Récupération des messages pour PID: %1", _pid];
diag_log format ["[MESSAGES][SERVER] Objet joueur: %1", _player];
diag_log format ["[MESSAGES][SERVER] Nom joueur: %1", name _player];

// Récupère les messages reçus et envoyés
private _query = format ["SELECT m.id, m.sender_pid, p1.name as sender_name, m.receiver_pid, p2.name as receiver_name, m.content, m.sent_at, m.is_read 
    FROM messages m 
    LEFT JOIN players p1 ON m.sender_pid = p1.pid 
    LEFT JOIN players p2 ON m.receiver_pid = p2.pid 
    WHERE m.sender_pid = '%1' OR m.receiver_pid = '%1' 
    ORDER BY m.sent_at DESC", _pid];

diag_log format ["[MESSAGES][SERVER] Query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[MESSAGES][SERVER] Résultat brut: %1", _queryResult];

// Traitement du résultat
private _messages = [];
if (!(_queryResult isEqualTo [])) then {
    // Si le résultat est un message unique
    if (count _queryResult == 8 && (_queryResult select 5) isEqualType "") then {
        _queryResult params [
            ["_id", 0, [0]],
            ["_senderPid", "", [""]],
            ["_senderName", "", [""]],
            ["_receiverPid", "", [""]],
            ["_receiverName", "", [""]],
            ["_content", "", [""]],
            ["_sentAt", "", [""]],
            ["_isRead", 0, [0]]
        ];
        _messages = [[_id, _senderPid, _senderName, _receiverPid, _receiverName, _content, _sentAt, _isRead]];
        diag_log format ["[MESSAGES][SERVER] Message unique détecté: [ID: %1, De: %2, À: %3, Date: %4]", _id, _senderName, _receiverName, _sentAt];
    } else {
        {
            _x params [
                ["_id", 0, [0]],
                ["_senderPid", "", [""]],
                ["_senderName", "", [""]],
                ["_receiverPid", "", [""]],
                ["_receiverName", "", [""]],
                ["_content", "", [""]],
                ["_sentAt", "", [""]],
                ["_isRead", 0, [0]]
            ];
            _messages pushBack [_id, _senderPid, _senderName, _receiverPid, _receiverName, _content, _sentAt, _isRead];
            diag_log format ["[MESSAGES][SERVER] Message ajouté: [ID: %1, De: %2, À: %3, Date: %4]", _id, _senderName, _receiverName, _sentAt];
        } forEach _queryResult;
    };
};

diag_log format ["[MESSAGES][SERVER] Envoi de %1 messages au client %2 (%3)", count _messages, name _player, _pid];

// Envoie les messages au client
[_messages] remoteExecCall ["life_fnc_receiveMessages", _player];
diag_log format ["[MESSAGES][SERVER] RemoteExecCall effectué vers %1", _player];

diag_log "=== FIN fn_server_fetchMessages.sqf ==="; 
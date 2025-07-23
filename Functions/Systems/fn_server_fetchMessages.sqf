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

// Récupère d'abord le nombre total de messages
private _countQuery = format ["SELECT COUNT(*) FROM messages WHERE sender_pid = '%1' OR receiver_pid = '%1'", _pid];
private _countResult = [_countQuery, 2] call DB_fnc_asyncCall;
diag_log format ["[MESSAGES][SERVER] Nombre total de messages: %1", _countResult];

// Récupère les messages reçus et envoyés
private _query = format ["SELECT 
    m.id, 
    m.sender_pid, 
    COALESCE(p1.name, 'Inconnu') as sender_name, 
    m.receiver_pid, 
    COALESCE(p2.name, 'Inconnu') as receiver_name, 
    m.content,
    DATE_FORMAT(m.sent_at, '%%Y-%%m-%%d %%H:%%i:%%s') as sent_at,
    m.is_read 
FROM messages m 
LEFT JOIN players p1 ON m.sender_pid = p1.pid 
LEFT JOIN players p2 ON m.receiver_pid = p2.pid 
WHERE m.sender_pid = '%1' OR m.receiver_pid = '%1' 
ORDER BY m.sent_at DESC", _pid];

diag_log format ["[MESSAGES][SERVER] Query: %1", _query];

private _queryResult = [_query, 2, true] call DB_fnc_asyncCall;
diag_log format ["[MESSAGES][SERVER] Type du résultat: %1", typeName _queryResult];
diag_log format ["[MESSAGES][SERVER] Résultat brut: %1", _queryResult];

// Traitement du résultat
private _messages = [];

if (_queryResult isEqualType []) then {
    {
        _x params [
            ["_id", 0, [0]],
            ["_senderPid", "", [""]],
            ["_senderName", "Inconnu", [""]],
            ["_receiverPid", "", [""]],
            ["_receiverName", "Inconnu", [""]],
            ["_content", "", [""]],
            ["_sentAt", "", [""]],
            ["_isRead", 0, [0]]
        ];

        // Nettoyage des données
        _senderName = if (_senderName == "") then {"Inconnu"} else {_senderName};
        _receiverName = if (_receiverName == "") then {"Inconnu"} else {_receiverName};
        _content = [_content] call DB_fnc_mresString;
        
        _messages pushBack [_id, _senderPid, _senderName, _receiverPid, _receiverName, _content, _sentAt, _isRead];
        diag_log format ["[MESSAGES][SERVER] Message ajouté: [ID: %1, De: %2, À: %3, Date: %4, Contenu: %5]", 
            _id, _senderName, _receiverName, _sentAt, _content];
    } forEach _queryResult;
} else {
    diag_log "[MESSAGES][SERVER] ERREUR: Le résultat n'est pas un tableau";
};

diag_log format ["[MESSAGES][SERVER] Envoi de %1 messages au client %2 (%3)", count _messages, name _player, _pid];

// Envoie les messages au client
[_messages] remoteExecCall ["life_fnc_receiveMessages", _player];
diag_log format ["[MESSAGES][SERVER] RemoteExecCall effectué vers %1", _player];

diag_log "=== FIN fn_server_fetchMessages.sqf ==="; 
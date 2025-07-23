/*
    File: fn_server_fetchConversation.sqf
    Description: Récupère tous les messages échangés entre le joueur et le destinataire donné, et les renvoie au client.
    Params: [player_obj, target_pid]
*/
params ["_player", "_targetPid"];

diag_log format ["[CONV][SERVER] fetchConversation pour %1 avec %2", name _player, _targetPid];

if (isNull _player) exitWith {
    diag_log "[CONV][SERVER] ERREUR: _player est null";
};

private _pid = getPlayerUID _player;

// Requête SQL pour récupérer tous les messages entre _pid et _targetPid
private _query = format [
    "SELECT m.id, m.sender_pid, COALESCE(p1.name, 'Inconnu') as sender_name, m.receiver_pid, COALESCE(p2.name, 'Inconnu') as receiver_name, m.content, DATE_FORMAT(m.sent_at, '%%Y-%%m-%%d %%H:%%i:%%s') as sent_at, m.is_read FROM messages m LEFT JOIN players p1 ON m.sender_pid = p1.pid LEFT JOIN players p2 ON m.receiver_pid = p2.pid WHERE (m.sender_pid = '%1' AND m.receiver_pid = '%2') OR (m.sender_pid = '%2' AND m.receiver_pid = '%1') ORDER BY m.sent_at ASC",
    _pid, _targetPid
];

diag_log format ["[CONV][SERVER] Query: %1", _query];

private _queryResult = [_query, 2, true] call DB_fnc_asyncCall;
diag_log format ["[CONV][SERVER] Résultat brut: %1", _queryResult];

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
        _messages pushBack [_id, _senderPid, _senderName, _receiverPid, _receiverName, _content, _sentAt, _isRead];
    } forEach _queryResult;
} else {
    diag_log "[CONV][SERVER] ERREUR: Le résultat n'est pas un tableau";
};

// Envoie la conversation au client
[_messages] remoteExecCall ["life_fnc_receiveConversation", _player];
diag_log format ["[CONV][SERVER] Conversation envoyée à %1 (%2) : %3 messages", name _player, _pid, count _messages]; 
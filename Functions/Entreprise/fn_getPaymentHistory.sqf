#include "\life_server\script_macros.hpp"
/*
    File: fn_getPaymentHistory.sqf
    Author: Your Name
    
    Description:
    Récupère l'historique des paiements d'une entreprise
*/

params [
    ["_companyId", 0, [0]],
    ["_player", objNull, [objNull]]
];

diag_log "=== TON_fnc_getPaymentHistory START ===";
diag_log format ["[COMPANY] Received payment history request for company ID: %1", _companyId];
diag_log format ["[COMPANY] From player: %1 (UID: %2)", name _player, getPlayerUID _player];

if (_companyId isEqualTo 0 || isNull _player) exitWith {
    diag_log "[COMPANY] ERROR: Invalid parameters received";
    diag_log format ["[COMPANY] Company ID: %1, Player: %2", _companyId, _player];
    diag_log "=== TON_fnc_getPaymentHistory END ===";
};

private _query = format ["SELECT employee_uid, employee_name, amount, payment_date FROM company_payments WHERE company_id = '%1' ORDER BY payment_date DESC LIMIT 50", _companyId];
diag_log format ["[COMPANY] Executing query: %1", _query];

private _queryResult = [_query,2,true] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Query result: %1", _queryResult];

if (_queryResult isEqualTo []) then {
    diag_log "[COMPANY] No payment history found";
    _queryResult = [];
} else {
    {
        _x set [3, [_x select 3] call DB_fnc_numberSafe];
    } forEach _queryResult;
    diag_log format ["[COMPANY] Processed payment history: %1", _queryResult];
};

// Envoyer les résultats au client
[_queryResult] remoteExecCall ["life_fnc_updatePaymentHistoryList", _player];
diag_log format ["[COMPANY] Sent payment history to player: %1", _queryResult];
diag_log "=== TON_fnc_getPaymentHistory END ==="; 
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

// Vérifier si des données existent
private _countQuery = format ["SELECT COUNT(*) as total FROM company_payments WHERE company_id='%1'", _companyId];
private _countResult = [_countQuery,2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Raw count result: %1", _countResult];

private _count = 0;
if (!(_countResult isEqualTo [])) then {
    _count = _countResult select 0;
    diag_log format ["[COMPANY] Number of payments found: %1", _count];
};

if (_count > 0) then {
    private _query = format ["SELECT employee_uid, employee_name, amount, payment_date FROM company_payments WHERE company_id='%1' ORDER BY payment_date DESC LIMIT 50", _companyId];
    diag_log format ["[COMPANY] Executing query: %1", _query];

    private _queryResult = [_query,2] call DB_fnc_asyncCall;
    diag_log format ["[COMPANY] Query result: %1", _queryResult];

    if (_queryResult isEqualTo []) then {
        diag_log "[COMPANY] No payment history found";
        _queryResult = [];
    } else {
        diag_log format ["[COMPANY] Found %1 payments", count _queryResult];
        {
            diag_log format ["[COMPANY] Processing payment - Employee: %1 (%2), Amount: %3, Date: %4", 
                _x select 1, _x select 0, _x select 2, _x select 3];
        } forEach _queryResult;
    };

    [_queryResult] remoteExecCall ["life_fnc_updatePaymentHistoryList", _player];
    diag_log format ["[COMPANY] Sent payment history to player: %1", _queryResult];
} else {
    diag_log "[COMPANY] No payments found in database";
    [[]] remoteExecCall ["life_fnc_updatePaymentHistoryList", _player];
};

diag_log "=== TON_fnc_getPaymentHistory END ==="; 
#include "\life_server\script_macros.hpp"
/*
    File: fn_getPaymentHistory.sqf
    Author: Your Name
    
    Description:
    Récupère l'historique des paiements d'une entreprise
*/

params [
    ["_companyId", 0, [0]],
    ["_owner", objNull, [objNull]]
];

diag_log "=== TON_fnc_getPaymentHistory START ===";
diag_log format ["Params - CompanyID: %1, Owner: %2", _companyId, _owner];
diag_log format ["Owner UID: %1", getPlayerUID _owner];
diag_log format ["Owner ID (netId): %1", owner _owner];

if (_companyId isEqualTo 0 || isNull _owner) exitWith {
    diag_log "GET_PAYMENT_HISTORY: Paramètres invalides";
    diag_log "=== TON_fnc_getPaymentHistory END (Invalid Params) ===";
};

// Vérifier la structure de la table
private _describeTable = "DESCRIBE company_payments";
private _tableStructure = [_describeTable, 2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Table structure: %1", _tableStructure];

// Vérifier si des données existent dans la table
private _countQuery = format ["SELECT COUNT(*) as count FROM company_payments WHERE company_id='%1'", _companyId];
private _countResult = [_countQuery, 2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Number of payments in table: %1", _countResult];

// Récupérer l'historique des paiements (les 50 derniers paiements)
private _query = format ["SELECT player_name, amount, payment_date FROM company_payments WHERE company_id='%1' ORDER BY payment_date DESC LIMIT 50", _companyId];
diag_log format ["[COMPANY] Payment history query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;
diag_log format ["[COMPANY] Query result type: %1", typeName _queryResult];
diag_log format ["[COMPANY] Query result: %1", _queryResult];

if (_queryResult isEqualTo []) then {
    diag_log "[COMPANY] No payment history found - Sending empty array to client";
    [[]] remoteExec ["life_fnc_updatePaymentHistoryList", owner _owner];
} else {
    diag_log format ["[COMPANY] Found %1 payments", count _queryResult];

    // Formater les données des paiements
    private _formattedPayments = [];
    {
        _x params [
            ["_playerName", "", [""]],
            ["_amount", 0, [0]],
            ["_paymentDate", "", [""]]
        ];
        
        _formattedPayments pushBack [_playerName, _amount, _paymentDate];
        diag_log format ["[COMPANY] Processing payment - Name: %1, Amount: %2, Date: %3", _playerName, _amount, _paymentDate];
    } forEach _queryResult;

    diag_log format ["[COMPANY] Sending %1 payments to client (Owner ID: %2)", count _formattedPayments, owner _owner];
    diag_log format ["[COMPANY] Formatted payments data: %1", _formattedPayments];
    [_formattedPayments] remoteExec ["life_fnc_updatePaymentHistoryList", owner _owner];
};

diag_log "=== TON_fnc_getPaymentHistory END ==="; 
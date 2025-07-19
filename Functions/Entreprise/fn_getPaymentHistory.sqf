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

if (_companyId isEqualTo 0 || isNull _owner) exitWith {
    diag_log "GET_PAYMENT_HISTORY: Paramètres invalides";
};

diag_log format ["[COMPANY] Getting payment history for company ID: %1", _companyId];
diag_log format ["[COMPANY] Owner: %1", _owner];
diag_log format ["[COMPANY] Owner ID: %1", owner _owner];

// Récupérer l'historique des paiements (les 50 derniers paiements)
private _query = format ["SELECT player_name, amount, payment_date FROM company_payments WHERE company_id='%1' ORDER BY payment_date DESC LIMIT 50", _companyId];
diag_log format ["[COMPANY] Payment query: %1", _query];

private _queryResult = [_query, 2] call DB_fnc_asyncCall;

diag_log format ["[COMPANY] Found %1 payments", count _queryResult];
diag_log format ["[COMPANY] Payment result: %1", _queryResult];

// Formater les données des paiements
private _formattedPayments = [];
{
    if (count _x >= 3) then {
        _x params [
            ["_playerName", "", [""]],
            ["_amount", 0, [0]],
            ["_paymentDate", "", [""]]
        ];
        
        _formattedPayments pushBack [_playerName, _amount, _paymentDate];
        diag_log format ["[COMPANY] Formatted payment - Name: %1, Amount: %2, Date: %3", _playerName, _amount, _paymentDate];
    };
} forEach _queryResult;

diag_log format ["[COMPANY] Formatted payments: %1", _formattedPayments];

// Envoyer les résultats au client
[_formattedPayments] remoteExec ["life_fnc_updatePaymentHistoryList", owner _owner];
diag_log format ["[COMPANY] Sent formatted payment results to client ID: %1", owner _owner]; 
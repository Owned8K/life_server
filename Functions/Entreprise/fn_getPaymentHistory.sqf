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

// Récupérer l'historique des paiements (les 50 derniers paiements)
private _query = format ["SELECT player_name, amount, payment_date FROM company_payments WHERE company_id='%1' ORDER BY payment_date DESC LIMIT 50", _companyId];
private _queryResult = [_query, 2] call DB_fnc_asyncCall;

// Envoyer les résultats au client
[_queryResult] remoteExec ["life_fnc_updatePaymentHistoryList", owner _owner]; 
/*
    File: fn_server_buyDistributeurItem.sqf
    Description: Traite l'achat d'un item dans le distributeur côté serveur
    Author: DreamLife
*/

params ["_distributeur", "_itemName", "_quantity", "_totalPrice", "_player"];

diag_log format ["[DISTRIBUTEUR][SERVER] Demande d'achat reçue: %1x %2 pour %3€ par %4", _quantity, _itemName, _totalPrice, _player];

// Vérifier que le joueur est valide
if (isNull _player) exitWith {
    diag_log "[DISTRIBUTEUR][SERVER] ERREUR: Joueur invalide";
};

// Récupérer l'ID du distributeur
private _distributeurId = _distributeur getVariable ["distributeur_id", -1];
if (_distributeurId == -1) exitWith {
    diag_log "[DISTRIBUTEUR][SERVER] ERREUR: ID du distributeur invalide";
    [false, "Distributeur invalide"] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
};

// Vérifier le stock actuel
private _stockJson = _distributeur getVariable ["distributeur_stock", "{}"];
private _stock = createHashMap;

try {
    _stock = call compile _stockJson;
    diag_log format ["[DISTRIBUTEUR][SERVER] Stock JSON parsé: %1", _stock];
} catch {
    diag_log format ["[DISTRIBUTEUR][SERVER] ERREUR parsing stock JSON: %1", _exception];
    [false, "Erreur de données"] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
};

private _currentStock = _stock getOrDefault [_itemName, 0];
diag_log format ["[DISTRIBUTEUR][SERVER] Stock actuel pour %1: %2", _itemName, _currentStock];

if (_currentStock < _quantity) exitWith {
    diag_log format ["[DISTRIBUTEUR][SERVER] ERREUR: Stock insuffisant (%1 demandé, %2 disponible)", _quantity, _currentStock];
    [false, format ["Stock insuffisant. Disponible: %1", _currentStock]] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
};

// Vérifier l'argent du joueur
private _playerCash = _player getVariable ["life_cash", 0];
if (_playerCash < _totalPrice) exitWith {
    diag_log format ["[DISTRIBUTEUR][SERVER] ERREUR: Fonds insuffisants (%1€ requis, %2€ disponible)", _totalPrice, _playerCash];
    [false, format ["Fonds insuffisants. Coût: %1€, Disponible: %2€", _totalPrice, _playerCash]] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
};

// Mettre à jour le stock
_stock set [_itemName, _currentStock - _quantity];
private _newStockJson = str _stock;

// Mettre à jour la base de données
private _query = format ["UPDATE distributeurs SET stock_actuel = '%1' WHERE id = %2", _newStockJson, _distributeurId];

diag_log format ["[DISTRIBUTEUR][SERVER] Requête SQL: %1", _query];

[_query, 1, [], {
    params ["_result"];
    
    diag_log format ["[DISTRIBUTEUR][SERVER] Résultat de la mise à jour DB: %1", _result];
    
    if (_result == 1) then {
        // Mise à jour réussie, traiter l'achat
        diag_log "[DISTRIBUTEUR][SERVER] Mise à jour DB réussie, traitement de l'achat...";
        
        // Mettre à jour les variables de l'objet
        _distributeur setVariable ["distributeur_stock", _newStockJson, true];
        
        // Déduire l'argent du joueur
        _player setVariable ["life_cash", _playerCash - _totalPrice, true];
        
        // Ajouter l'item à l'inventaire du joueur
        [_itemName, _quantity] remoteExecCall ["life_fnc_handleInv", _player];
        
        // Envoyer le résultat au client
        [true, format ["Achat réussi: %1x %2 pour %3€", _quantity, _itemName, _totalPrice]] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
        
        diag_log format ["[DISTRIBUTEUR][SERVER] Achat traité avec succès pour %1", _player];
        
    } else {
        diag_log "[DISTRIBUTEUR][SERVER] ERREUR: Échec de la mise à jour DB";
        [false, "Erreur lors de la mise à jour du stock"] remoteExecCall ["life_fnc_distributeurBuyResult", _player];
    };
    
}] call DB_fnc_asyncCall;

diag_log "[DISTRIBUTEUR][SERVER] Requête DB_fnc_asyncCall lancée"; 
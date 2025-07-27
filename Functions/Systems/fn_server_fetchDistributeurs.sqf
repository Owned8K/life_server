/*
    File: fn_server_fetchDistributeurs.sqf
    Description: Récupère les données dynamiques des distributeurs depuis la base de données et les stocke côté serveur.
    Params: []
*/
diag_log "[DISTRIBUTEUR][SERVER] fn_server_fetchDistributeurs appelé";

// Vérifier que DB_fnc_asyncCall est disponible
if (isNil "DB_fnc_asyncCall") exitWith {
    diag_log "[DISTRIBUTEUR][SERVER] ERREUR: DB_fnc_asyncCall non disponible";
};

// Requête pour récupérer les données dynamiques de tous les distributeurs
private _query = "SELECT id, stock_actuel, stock_max, prix FROM distributeurs";

diag_log format ["[DISTRIBUTEUR][SERVER] Requête SQL: %1", _query];

[_query, 2, [], {
    params ["_result"];
    
    diag_log format ["[DISTRIBUTEUR][SERVER] Résultat de la requête: %1", _result];
    diag_log format ["[DISTRIBUTEUR][SERVER] Type du résultat: %1", typeName _result];
    diag_log format ["[DISTRIBUTEUR][SERVER] Nombre d'éléments: %1", count _result];
    
    if (_result isEqualTo []) then {
        diag_log "[DISTRIBUTEUR][SERVER] Aucune donnée de distributeur trouvée dans la base de données";
        life_distributeurs_data = [];
        publicVariable "life_distributeurs_data";
        diag_log "[DISTRIBUTEUR][SERVER] Variable life_distributeurs_data initialisée avec tableau vide";
    } else {
        diag_log format ["[DISTRIBUTEUR][SERVER] %1 entrées de données trouvées, traitement en cours...", count _result];
        
        // Traiter chaque entrée de données
        private _distributeursData = [];
        {
            _x params ["_id", "_stock", "_stockMax", "_prix"];
            
            diag_log format ["[DISTRIBUTEUR][SERVER] Traitement données pour ID=%1", _id];
            diag_log format ["[DISTRIBUTEUR][SERVER] Stock actuel: %1", _stock];
            diag_log format ["[DISTRIBUTEUR][SERVER] Stock max: %1", _stockMax];
            diag_log format ["[DISTRIBUTEUR][SERVER] Prix: %1", _prix];
            
            // Ajouter les données à la liste
            _distributeursData pushBack [_id, _stock, _stockMax, _prix];
            diag_log format ["[DISTRIBUTEUR][SERVER] Données pour ID %1 ajoutées", _id];
            
        } forEach _result;
        
        diag_log format ["[DISTRIBUTEUR][SERVER] %1 entrées de données prêtes à être stockées", count _distributeursData];
        
        // Stocker les données côté serveur
        if (count _distributeursData > 0) then {
            life_distributeurs_data = _distributeursData;
            publicVariable "life_distributeurs_data";
            diag_log "[DISTRIBUTEUR][SERVER] Données stockées dans life_distributeurs_data et publiées";
        } else {
            life_distributeurs_data = [];
            publicVariable "life_distributeurs_data";
            diag_log "[DISTRIBUTEUR][SERVER] Variable life_distributeurs_data initialisée avec tableau vide";
        };
    };
}] call DB_fnc_asyncCall;

diag_log "[DISTRIBUTEUR][SERVER] Requête DB_fnc_asyncCall lancée"; 
/*
    File: fn_server_spawnDistributeurs.sqf
    Description: Crée les objets distributeurs sur la carte au démarrage du serveur.
    Author: DreamLife
*/

diag_log "[DISTRIBUTEUR][SERVER] Début de la création des distributeurs sur la carte...";

// Configuration des distributeurs côté serveur
// Format: [ID, Nom, PosX, PosY, PosZ, Direction, Zone]
private _distributeurs_config = [
    [1, "Distributeur Hopital Nord Ouest", 965.99, 5106.63, 0.00143909, 180, "Hopital"],
    [2, "Distributeur Super marché sud ouest", 790.683, 3489.36, 0.00143814, 90, "Marché"],
    [3, "Distributeur Super marché Union", 3591.03, 3198.15, 0.00143909, 270, "Marché"],
    [4, "Distributeur Super marché JamesTown", 1406.86, 1786.07, 0.00144005, 0, "Marché"],
    [5, "Distributeur Super marché GateWood", 2365.57, 944.141, 0.00143814, 180, "Marché"],
    [6, "Distributeur Perrytonia", 4814.51, 2193.55, 0.00143909, 180, "Perrytonia"],
    [7, "Distributeur WaterGates", 7375.8, 3584.2, 0.00143909, 180, "WaterGates"],
    [8, "Distributeur FallsChurch", 5403.13, 4300.23, 0.00143814, 180, "FallsChurch"],
    [9, "Distributeur LakeSide", 2043.23, 6098.04, 0.00144005, 180, "LakeSide"]
];

// Créer les objets distributeurs
{
    _x params [
        "_id",
        "_nom", 
        "_posX",
        "_posY", 
        "_posZ",
        "_dir",
        "_zone"
    ];
    
    diag_log format ["[DISTRIBUTEUR][SERVER] Création de %1 (ID: %2) à la position [%3, %4, %5]", _nom, _id, _posX, _posY, _posZ];
    
    // Créer l'objet distributeur
    private _distributeur = "Land_Icebox_F" createVehicle [_posX, _posY, _posZ];
    
    if (!isNull _distributeur) then {
        _distributeur setPosATL [_posX, _posY, _posZ];
        _distributeur setDir _dir;
        _distributeur enableSimulation false;
        
        // Stocker les données du distributeur
        _distributeur setVariable ["distributeur_id", _id, true];
        _distributeur setVariable ["distributeur_nom", _nom, true];
        _distributeur setVariable ["distributeur_zone", _zone, true];
        
        // Données par défaut (seront mises à jour depuis la DB)
        _distributeur setVariable ["distributeur_stock", '{"redgull":50,"waterBottle":30,"donuts":25,"apple":40,"peach":35}', true];
        _distributeur setVariable ["distributeur_stock_max", '{"redgull":100,"waterBottle":50,"donuts":50,"apple":80,"peach":70}', true];
        _distributeur setVariable ["distributeur_prix", '{"redgull":150,"waterBottle":50,"donuts":75,"apple":25,"peach":30}', true];
        
        // Ajouter l'action pour tous les joueurs
        _distributeur addAction [
            "<t color='#FFD700'>Utiliser le Distributeur</t>",
            {
                params ["_target", "_caller"];
                diag_log format ["[DISTRIBUTEUR][SERVER] Action utilisée par %1 sur %2", _caller, _target];
                [_target] remoteExecCall ["life_fnc_openDistributeur", _caller];
            },
            nil,
            1.5,
            true,
            true,
            "",
            "true"
        ];
        
        // Action alternative pour test
        _distributeur addAction [
            "<t color='#FF0000'>TEST - Ouvrir Distributeur</t>",
            {
                params ["_target", "_caller"];
                diag_log format ["[DISTRIBUTEUR][SERVER] ACTION TEST utilisée par %1 sur %2", _caller, _target];
                hint format ["Test: Ouverture du distributeur %1", _target getVariable ["distributeur_nom", "Inconnu"]];
                [_target] remoteExecCall ["life_fnc_openDistributeur", _caller];
            },
            nil,
            3.0,
            false,
            true,
            "",
            "true"
        ];
        
        // Forcer la synchronisation
        _distributeur setVariable ["distributeur_actions_added", true, true];
        diag_log format ["[DISTRIBUTEUR][SERVER] Actions ajoutées et synchronisées pour %1", _nom];
        
        diag_log format ["[DISTRIBUTEUR][SERVER] %1 créé avec succès", _nom];
    } else {
        diag_log format ["[DISTRIBUTEUR][SERVER] ERREUR: Impossible de créer %1", _nom];
    };
    
} forEach _distributeurs_config;

diag_log format ["[DISTRIBUTEUR][SERVER] %1 distributeurs créés sur la carte", count _distributeurs_config];

// Maintenant récupérer les données dynamiques depuis la DB et les appliquer
diag_log "[DISTRIBUTEUR][SERVER] Récupération des données dynamiques depuis la DB...";

// Vérifier que DB_fnc_asyncCall est disponible
if (isNil "DB_fnc_asyncCall") then {
    diag_log "[DISTRIBUTEUR][SERVER] ERREUR: DB_fnc_asyncCall non disponible, données par défaut utilisées";
} else {
    // Requête pour récupérer les données dynamiques
    private _query = "SELECT id, stock_actuel, stock_max, prix FROM distributeurs";
    
    [_query, 2, [], {
        params ["_result"];
        
        diag_log format ["[DISTRIBUTEUR][SERVER] Données DB reçues: %1 entrées", count _result];
        
        if (!(_result isEqualTo [])) then {
            {
                _x params ["_id", "_stock", "_stockMax", "_prix"];
                
                // Trouver l'objet distributeur correspondant
                private _distributeur = objNull;
                {
                    if ((_x getVariable ["distributeur_id", -1]) == _id) exitWith {
                        _distributeur = _x;
                    };
                } forEach (allMissionObjects "Land_Icebox_F");
                
                if (!isNull _distributeur) then {
                    _distributeur setVariable ["distributeur_stock", _stock, true];
                    _distributeur setVariable ["distributeur_stock_max", _stockMax, true];
                    _distributeur setVariable ["distributeur_prix", _prix, true];
                    diag_log format ["[DISTRIBUTEUR][SERVER] Données mises à jour pour ID %1", _id];
                };
                
            } forEach _result;
        };
        
        diag_log "[DISTRIBUTEUR][SERVER] Mise à jour des données terminée";
        
    }] call DB_fnc_asyncCall;
}; 
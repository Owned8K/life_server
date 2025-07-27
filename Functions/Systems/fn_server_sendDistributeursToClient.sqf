/*
    File: fn_server_sendDistributeursToClient.sqf
    Description: Envoie les données des distributeurs à un client spécifique.
    Params: [_client]
*/
params ["_client"];

diag_log format ["[DISTRIBUTEUR][SERVER] Envoi des données au client: %1", _client];

// Vérifier si les données sont disponibles
if (isNil "life_distributeurs_data") then {
    diag_log "[DISTRIBUTEUR][SERVER] ERREUR: life_distributeurs_data non disponible";
    [[]] remoteExecCall ["life_fnc_receiveDistributeurs", _client];
} else {
    diag_log format ["[DISTRIBUTEUR][SERVER] Envoi de %1 entrées de données au client", count life_distributeurs_data];
    [life_distributeurs_data] remoteExecCall ["life_fnc_receiveDistributeurs", _client];
    diag_log "[DISTRIBUTEUR][SERVER] Données envoyées au client";
}; 
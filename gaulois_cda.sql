
-- 1. Lister les personnages ayant bu plus de 2 potions différentes.
SELECT
	pe.id_personnage,
	pe.nom_personnage,
	SUM(bo.dose_boire) AS qttBue
FROM
	boire bo
INNER JOIN personnage pe ON pe.id_personnage = bo.id_personnage
INNER JOIN potion po ON po.id_potion = bo.id_potion
GROUP BY
	pe.id_personnage
HAVING qttBue > 2
ORDER BY 
	qttBue DESC

-- 2. Donner le total de casques pris par type, avec leur coût cumulé.
SELECT
	tc.id_type_casque,
	tc.nom_type_casque,
	SUM(pca.qte) AS total_casque,
	SUM(ca.cout_casque * pca.qte) AS totalCout
FROM
	prendre_casque pca
INNER JOIN casque ca ON pca.id_casque = ca.id_casque
INNER JOIN type_casque tc ON ca.id_type_casque = tc.id_type_casque
GROUP BY
	tc.id_type_casque,
	tc.nom_type_casque
-- 3. Pour chaque personnage, afficher le nombre de batailles auxquelles il a participé via la prise de casque.
SELECT
	pe.nom_personnage,
	COUNT(DISTINCT ba.id_bataille) AS totalBatailles
FROM
	prendre_casque pca
INNER JOIN personnage pe ON pca.id_personnage = pe.id_personnage
INNER JOIN bataille ba ON pca.id_bataille = ba.id_bataille
GROUP BY
	pe.nom_personnage
-- 4. Afficher les potions les plus bues (en dose totale).
SELECT
	po.nom_potion,
	SUM(bo.dose_boire) AS doseTotal
FROM
	boire bo
INNER JOIN potion po ON po.id_potion = bo.id_potion
GROUP BY
	po.nom_potion
ORDER BY 
	doseTotal DESC
-- 5. Afficher le top 5 des lieux dont les habitants ont bu le plus de potion (en dose totale), en incluant les égalités.
SELECT
	le.nom_lieu,
	SUM(bo.dose_boire) AS doseTotal
FROM
	boire bo
INNER JOIN potion po ON po.id_potion = bo.id_potion
INNER JOIN personnage pe ON bo.id_personnage = pe.id_personnage
INNER JOIN lieu le ON pe.id_lieu = le.id_lieu
GROUP BY
	le.id_lieu
ORDER BY
	doseTotal DESC
LIMIT 5
-- 6. Lister les potions autorisées pour un personnage mais jamais bues par lui.
SELECT 
	pe.id_personnage,
	pe.nom_personnage,
	po.id_potion,
	po.nom_potion
FROM 
	autoriser_boire ab
INNER JOIN personnage pe ON ab.id_personnage = pe.id_personnage
INNER JOIN potion po ON ab.id_potion = po.id_potion
LEFT JOIN boire bo ON bo.id_personnage = ab.id_personnage AND bo.id_potion = ab.id_potion
WHERE 
	bo.id_potion IS NULL
-- 7. Afficher les personnages avec toutes les potions qu'ils ont bues dans une seule colonne séparée par des virgules.
SELECT 
    pe.nom_personnage,
    GROUP_CONCAT(po.nom_potion ORDER BY po.nom_potion SEPARATOR ', ') AS potions_bues
FROM 
    boire bo
INNER JOIN potion po ON po.id_potion = bo.id_potion
INNER JOIN personnage pe ON pe.id_personnage = bo.id_personnage
GROUP BY
    pe.nom_personnage
-- 8. Donner la moyenne de doses bues par spécialité (avec gestion des cas sans consommation).
-- 9. Lister les personnages ayant bu au moins 3 potions différentes le même jour.
-- 10. Créer un trigger qui empêche un personnage de boire une potion non autorisée.
-- 11. Créer une procédure stockée permettant de savoir quelles potions un personnage peut consommer à partir d’une liste d’identifiants.
-- 12. Créer une procédure stockée qui met à jour la quantité de casques disponibles après une prise.
-- 13. Créer un index pertinent pour accélérer les recherches de casques pris par bataille.
-- 14. Proposer une amélioration du modèle pour normaliser les moments de consommation de potion.
-- 15. Créer une requête permettant de générer un journal des consommations : personnage, date, potion, dose, lieu.
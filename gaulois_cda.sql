
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
	SUM(bo.dose_boire) AS doseTotal,
	RANK() OVER (ORDER BY SUM(bo.dose_boire) DESC) AS TOP
FROM
	boire bo
INNER JOIN potion po ON po.id_potion = bo.id_potion
INNER JOIN personnage pe ON bo.id_personnage = pe.id_personnage
INNER JOIN lieu le ON pe.id_lieu = le.id_lieu
GROUP BY
	le.id_lieu
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
SELECT
	AVG(bo.dose_boire),
	pe.nom_personnage,
	spe.nom_specialite
FROM
	boire bo
LEFT JOIN personnage pe ON bo.id_personnage = pe.id_personnage
LEFT JOIN specialite spe ON pe.id_specialite = spe.id_specialite
GROUP BY 
	pe.nom_personnage,
	spe.nom_specialite

-- 9. Lister les personnages ayant bu au moins 3 potions différentes le même jour.
SELECT *
FROM 
	boire bo
WHERE bo.date_boire IN (
    SELECT 
		bo.date_boire
    FROM 
		boire bo
    GROUP BY 
		bo.date_boire
    HAVING COUNT(*) > 1
);

-- 10. Créer un trigger qui empêche un personnage de boire une potion non autorisée.
DELIMITER //

CREATE TRIGGER verifier_boisson_non_autorisee
BEFORE INSERT ON boire
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT * FROM autoriser_boire WHERE id_potion = NEW.id_potion AND id_personnage = NEW.id_personnage
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cette potion n''est pas autorisée.';
    END IF;
END;
//

DELIMITER ;

-- 11. Créer une procédure stockée permettant de savoir quelles potions un personnage peut consommer à partir d’une liste d’identifiants.
DELIMITER //
CREATE PROCEDURE liste_boisson_autorisee
(IN identifiants TEXT)
BEGIN
	SELECT * 
	FROM autoriser_boire 
	WHERE FIND_IN_SET(id_potion, identifiants);
END;
//
DELIMITER ;

-- 12. Créer une procédure stockée qui met à jour la quantité de casques disponibles après une prise.
DELIMITER //
CREATE PROCEDURE maj_qte_casque
(IN casqueId INT, IN persoId INT, IN batailleId INT, IN qteNb INT)
BEGIN
	UPDATE prendre_casque
    SET qte = qte - qteNb
	WHERE id_casque = casqueId AND id_personnage = persoId AND id_bataille = batailleId;
END;
//
DELIMITER ;

-- 13. Créer un index pertinent pour accélérer les recherches de casques pris par bataille.
CREATE INDEX IX_CASQUE_BATAILLE ON prendre_casque(id_casque, id_bataille);

-- 14. Proposer une amélioration du modèle pour normaliser les moments de consommation de potion.
CREATE TABLE evenement
(
    id_evenement INT PRIMARY KEY NOT NULL,
	id_boire INT NOT NULL,
	FOREIGN KEY (id_boire) REFERENCES boire(id_boire),
	nom_evenement VARCHAR(255)
);

-- 15. Créer une requête permettant de générer un journal des consommations : personnage, date, potion, dose, lieu.
CREATE VIEW journal_activites_consommations AS
SELECT
	pe.nom_personnage,
	bo.date_boire,
	po.nom_potion,
	bo.dose_boire,
	le.nom_lieu
FROM boire bo
INNER JOIN personnage pe ON bo.id_personnage = pe.id_personnage
INNER JOIN potion po ON bo.id_potion = po.id_potion
INNER JOIN lieu le ON pe.id_lieu = le.id_lieu
GROUP BY
	pe.nom_personnage,
	bo.date_boire,
	po.nom_potion,
	bo.dose_boire,
	le.nom_lieu

-- Bonus 1 – Détection de tricheurs
--Lister les personnages qui ont bu la même potion plus de 3 fois dans la même journée.
--Afficher : nom du personnage, nom de la potion, date, nombre de fois.
SELECT
	pe.nom_personnage,
	po.nom_potion,
	bo.date_boire,
	bo.dose_boire
FROM
	boire bo
LEFT JOIN personnage pe ON bo.id_personnage = pe.id_personnage
LEFT JOIN potion po ON bo.id_potion = po.id_potion
WHERE dose_boire > 3
GROUP BY
	pe.nom_personnage,
	po.nom_potion,
	bo.date_boire,
	bo.dose_boire

--Bonus 2 – Requête paramétrée pour historique personnalisé
--Écrire une procédure stockée qui, à partir d’un id_personnage en entrée, retourne toutes les potions bues avec les dates et les doses, triées par date décroissante.
DELIMITER //
CREATE PROCEDURE toutes_potions_bues
(IN personnageId INT)
BEGIN
	SELECT
		po.nom_potion,
		bo.dose_boire,
		bo.date_boire
	FROM
		boire bo
	INNER JOIN personnage pe ON bo.id_personnage = pe.id_personnage
	INNER JOIN potion po ON bo.id_potion = po.id_potion
	WHERE pe.id_personnage = personnageId
	ORDER BY
		bo.date_boire DESC;
END;
//
DELIMITER ;
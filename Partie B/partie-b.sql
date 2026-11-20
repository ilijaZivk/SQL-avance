-- =====================================================
-- Partie B
-- =====================================================

USE advanced_sql;


-- =====================================================
-- QUESTION 4 : Normalisation en troisième forme normale
-- =====================================================

-- 1. Création de la table brute

CREATE TABLE affectations_brutes (
    employe_id INT,
    employe_nom VARCHAR(100),
    dept_nom VARCHAR(100),
    projets_liste VARCHAR(255),
    chef_projet VARCHAR(100),
    chef_projet_tel VARCHAR(20)
);

-- 2. Insertion des données brutes

INSERT INTO affectations_brutes VALUES
(13, 'Laurent Mercier', 'Sécurité',
 'Projet Cloud, Projet IA', 'Laurent Mercier', '0600000001'),

(14, 'Céline Dumas', 'Sécurité',
 'Projet Cloud', 'Laurent Mercier', '0600000001'),

(15, 'Damien Charpentier', 'Sécurité',
 'Projet IA', 'Laurent Mercier', '0600000001'),

(17, 'Hugo Barbier', 'Data',
 'Projet IA', 'Hugo Barbier', '0600000002');


-- 3. Création des tables normalisées

CREATE TABLE departements_3fn (
    dept_id INT AUTO_INCREMENT PRIMARY KEY,
    dept_nom VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE employes_3fn (
    employe_id INT PRIMARY KEY,
    employe_nom VARCHAR(100) NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id)
        REFERENCES departements_3fn(dept_id)
);

CREATE TABLE chefs_projet_3fn (
    chef_projet_id INT AUTO_INCREMENT PRIMARY KEY,
    chef_projet VARCHAR(100) NOT NULL,
    chef_projet_tel VARCHAR(20)
);

CREATE TABLE projets_3fn (
    projet_id INT AUTO_INCREMENT PRIMARY KEY,
    projet_nom VARCHAR(100) NOT NULL,
    chef_projet_id INT,
    FOREIGN KEY (chef_projet_id)
        REFERENCES chefs_projet_3fn(chef_projet_id)
);

CREATE TABLE affectations_3fn (
    employe_id INT,
    projet_id INT,
    PRIMARY KEY (employe_id, projet_id),
    FOREIGN KEY (employe_id)
        REFERENCES employes_3fn(employe_id),
    FOREIGN KEY (projet_id)
        REFERENCES projets_3fn(projet_id)
);


-- 4. Insertion des départements

INSERT INTO departements_3fn (dept_nom)
VALUES ('Sécurité'), ('Data');


-- 5. Insertion des employés

INSERT INTO employes_3fn VALUES
(13, 'Laurent Mercier', 1),
(14, 'Céline Dumas', 1),
(15, 'Damien Charpentier', 1),
(17, 'Hugo Barbier', 2);


-- 6. Insertion des chefs de projet

INSERT INTO chefs_projet_3fn (chef_projet, chef_projet_tel)
VALUES
('Laurent Mercier', '0600000001'),
('Hugo Barbier', '0600000002');


-- 7. Insertion des projets

INSERT INTO projets_3fn (projet_nom, chef_projet_id)
VALUES
('Projet Cloud', 1),
('Projet IA', 2);


-- 8. Insertion des affectations

INSERT INTO affectations_3fn VALUES
(13, 1),
(13, 2),
(14, 1),
(15, 2),
(17, 2);


-- 9. Vérification de la normalisation

SELECT
    e.employe_nom,
    d.dept_nom,
    p.projet_nom,
    cp.chef_projet,
    cp.chef_projet_tel
FROM affectations_3fn a
JOIN employes_3fn e ON a.employe_id = e.employe_id
JOIN departements_3fn d ON e.dept_id = d.dept_id
JOIN projets_3fn p ON a.projet_id = p.projet_id
JOIN chefs_projet_3fn cp ON p.chef_projet_id = cp.chef_projet_id;

/* RÉSULTAT :
5 affectations retrouvées avec les employés,
leurs départements, leurs projets et les chefs de projet.

CONCLUSION :
La décomposition en 3FN permet de supprimer les
redondances et les dépendances transitives.
Les relations sont assurées par les PK et les FK.
*/


-- =====================================================
-- QUESTION 5 : CTE et DENSE_RANK()
-- =====================================================

WITH classement_produits AS (
    SELECT
        c.nom AS categorie,
        p.nom AS produit,
        p.prix_unitaire,
        DENSE_RANK() OVER (
            PARTITION BY c.id
            ORDER BY p.prix_unitaire DESC
        ) AS classement
    FROM produits p
    JOIN categories c ON p.categorie_id = c.id
)

SELECT
    categorie,
    produit,
    prix_unitaire,
    classement
FROM classement_produits
WHERE classement <= 2
ORDER BY categorie, classement;

/* RÉSULTAT ATTENDU :

Intelligence Artificielle & GPU :
- Serveur IA 4x GPU H100 : 14500.00
- Carte Accélératrice Tensor 80Go : 4200.00

Téléphonie & Visioconférence :
- Barre Visio Tout-en-Un 4K : 980.00
- Téléphone IP PoE Gigabit : 165.00

Sauvegarde & Archivage :
- Robot Bande LTO-9 24 Slots : 4850.00
- Cartouche LTO-9 18To : 115.00

CONCLUSION :
La CTE permet de préparer les données et DENSE_RANK()
classe les produits par prix décroissant dans chaque
catégorie. Seuls les deux premiers rangs sont conservés.
*/


-- =====================================================
-- QUESTION 6 : Organigramme avec WITH RECURSIVE
-- =====================================================

-- 1. Création du CTO s'il n'existe pas déjà

INSERT INTO employes
(nom, poste, manager_id, departement, salaire)
SELECT
    'Directeur Technique',
    'CTO',
    NULL,
    'Direction',
    90000.00
WHERE NOT EXISTS (
    SELECT 1
    FROM employes
    WHERE poste = 'CTO'
);


-- 2. Mise à jour des relations hiérarchiques

UPDATE employes e
JOIN employes m ON m.poste = 'CTO'
SET e.manager_id = m.id
WHERE e.nom IN ('Laurent Mercier', 'Hugo Barbier');

UPDATE employes e
JOIN employes m ON m.nom = 'Laurent Mercier'
SET e.manager_id = m.id
WHERE e.nom IN ('Céline Dumas', 'Damien Charpentier');

UPDATE employes e
JOIN employes m ON m.nom = 'Céline Dumas'
SET e.manager_id = m.id
WHERE e.nom = 'Mathilde Perrot';

UPDATE employes e
JOIN employes m ON m.nom = 'Hugo Barbier'
SET e.manager_id = m.id
WHERE e.nom = 'Manon Lemoine';


-- 3. Requête récursive pour afficher l'organigramme

WITH RECURSIVE organigramme AS (

    -- Point de départ : CTO
    SELECT
        id,
        nom,
        poste,
        manager_id,
        0 AS niveau,
        CAST(nom AS CHAR(1000)) AS chemin
    FROM employes
    WHERE poste = 'CTO'

    UNION ALL

    -- Recherche des employés subordonnés
    SELECT
        e.id,
        e.nom,
        e.poste,
        e.manager_id,
        o.niveau + 1,
        CONCAT(o.chemin, ' > ', e.nom)
    FROM employes e
    JOIN organigramme o
        ON e.manager_id = o.id
)

SELECT
    nom,
    poste,
    niveau,
    chemin
FROM organigramme
ORDER BY niveau, nom;


/* RÉSULTAT :

Niveau 0 : Directeur Technique (CTO)

Niveau 1 :
- Hugo Barbier
- Laurent Mercier

Niveau 2 :
- Céline Dumas
- Damien Charpentier
- Manon Lemoine

Niveau 3 :
- Mathilde Perrot

Total : 7 employés.

CONCLUSION :
WITH RECURSIVE permet de parcourir automatiquement
la hiérarchie depuis le CTO.

Le niveau indique la profondeur hiérarchique et
le chemin affiche le parcours complet depuis le CTO.
*/


-- =====================================================
-- FIN DU TP SQL AVANCÉ - PARTIE B
-- =====================================================

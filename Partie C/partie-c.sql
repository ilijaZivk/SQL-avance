-- =====================================================
-- Partie C
-- =====================================================

USE advanced_sql;


-- =====================================================
-- QUESTION 7 : Problème de NOT IN et correction fiable
-- =====================================================

-- 1. Requête initiale
SELECT id, nom
FROM employes
WHERE id NOT IN (
    SELECT manager_id
    FROM employes
);

/* RÉSULTAT :
Aucune ligne retournée (no data).

EXPLICATION :
La sous-requête retourne une valeur NULL,
correspondant au CTO qui n'a pas de manager.

Avec NOT IN, la présence de NULL peut rendre
les comparaisons inconnues (UNKNOWN).

Cela explique pourquoi aucune ligne
n'est retournée.
*/
-- 2. Correction avec NOT EXISTS

SELECT e.id, e.nom
FROM employes e
WHERE NOT EXISTS (
    SELECT 1
    FROM employes m
    WHERE m.manager_id = e.id
);

/* RÉSULTAT :
3 employés retournés :
- Damien Charpentier (ID 3)
- Mathilde Perrot (ID 4)
- Manon Lemoine (ID 6)

Ces employés ne dirigent aucun autre employé.
*/
-- 3. Vérification du résultat

SELECT
    e.id,
    e.nom,
    e.poste
FROM employes e
WHERE NOT EXISTS (
    SELECT 1
    FROM employes m
    WHERE m.manager_id = e.id
);


/* CONCLUSION :
NOT EXISTS est une solution fiable pour rechercher
les employés qui ne dirigent personne.

Contrairement à NOT IN, cette méthode n'est pas
perturbée par les valeurs NULL de manager_id.
*/

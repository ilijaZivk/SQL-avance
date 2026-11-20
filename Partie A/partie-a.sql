-- =====================================================
-- Partie A
-- =====================================================

USE advanced_sql;

-- =====================================================
-- QUESTION 1 : Audit de la requête (YEAR)
-- =====================================================
EXPLAIN ANALYZE
SELECT *
FROM commandes
WHERE statut = 'LIVREE'
  AND YEAR(date_commande) = 2026
ORDER BY montant_total DESC
LIMIT 10;

/* RÉSULTAT :
-> Limit: 10 row(s)  (cost=21.1 rows=10) (actual time=0.253..0.255 rows=10 loops=1)
    -> Sort: commandes.montant_total DESC, limit input to 10 row(s) per chunk  (cost=21.1 rows=208) (actual time=0.253..0.254 rows=10 loops=1)
        -> Filter: ((commandes.statut = 'LIVREE') and (year(commandes.date_commande) = 2026))  (cost=21.1 rows=208) (actual time=0.155..0.18 rows=37 loops=1)
            -> Table scan on commandes  (cost=21.1 rows=208) (actual time=0.0732..0.126 rows=208 loops=1)

DÉFAUTS :
1. YEAR(date_commande) n'est pas SARGable : aucun index utilisable, Table scan
   complet (208 lignes lues pour 37 retenues).
2. Tri (Sort) de toutes les lignes filtrées pour n'en garder que 10, et
   SELECT * lit toutes les colonnes inutilement.
*/

/*
Réponse écrite : Défaut 1 : YEAR(date_commande) n’est pas SARGable, donc l’optimiseur ne peut pas utiliser d'index. Défaut 2 : tous les enregistrements filtrés sont triés (filesort) pour n’en garder que 10, et SELECT * lit toutes les colonnes inutilement.
*/

-- =====================================================
-- QUESTION 2 : Index, partitionnement, requête SARGable
-- =====================================================
-- 1. Création de l'index
CREATE INDEX idx_date_commande
ON commandes(date_commande);

-- 2. Réécriture de la requête en version SARGable
EXPLAIN ANALYZE
SELECT id_commande, date_commande, statut, montant_total
FROM commandes
WHERE statut = 'LIVREE'
  AND date_commande >= '2026-01-01'
  AND date_commande < '2027-01-01'
ORDER BY montant_total DESC
LIMIT 10;

/* RÉSULTAT :
Coût estimé : 6.45
Temps réel : environ 1 ms
62 lignes parcourues pour 37 retenues.
Le plan affiche encore un Table scan.
*/

/* COMPARAISON :
- Avant : coût estimé de 21.1, 208 lignes parcourues.
- Après : coût estimé de 6.45, 62 lignes parcourues.
- Le coût estimé diminue d'environ 69,4 %.
*/

/* PARTITIONNEMENT RANGE :
Le partitionnement RANGE permet de répartir les commandes
selon leur date. Le partition pruning permet à MySQL de
ne parcourir que les partitions correspondant à la période
recherchée, par exemple p2026.

La vérification du partition pruning reste à effectuer
avec EXPLAIN.
*/

/* CONCLUSION :
La requête SARGable réduit le coût estimé et le nombre
de lignes parcourues. Cependant, le plan affiche encore
un Table scan : l'index n'est pas utilisé dans ce résultat.
*/

-- =====================================================
-- QUESTION 3 : Vue matérialisée mv_synthese_segments
-- =====================================================

USE advanced_sql;

-- 1. Création de la vue matérialisée (table simulée)
CREATE TABLE mv_synthese_segments AS
SELECT
    c.segment,
    COUNT(cmd.id) AS nb_commandes,
    SUM(cmd.montant_total) AS chiffre_affaires
FROM clients c
LEFT JOIN commandes cmd ON c.id = cmd.client_id
GROUP BY c.segment;


-- 2. Vérification du contenu
SELECT * FROM mv_synthese_segments;

-- 3. Insertion d'une commande test
INSERT INTO commandes
(client_id, date_commande, montant_total, statut)
VALUES
(25, '2026-11-20 10:00:00', 3500.00, 'LIVREE');


-- 4. Constat : la vue est obsolète
SELECT * FROM mv_synthese_segments;

/* RÉSULTAT :
La nouvelle commande n'apparaît pas dans la table
mv_synthese_segments.

La table n'est pas actualisée automatiquement :
elle contient donc des données obsolètes.
*/

-- 5. Rafraîchissement de la vue matérialisée
TRUNCATE TABLE mv_synthese_segments;

INSERT INTO mv_synthese_segments
SELECT
    c.segment,
    COUNT(cmd.id) AS nb_commandes,
    SUM(cmd.montant_total) AS chiffre_affaires
FROM clients c
LEFT JOIN commandes cmd ON c.id = cmd.client_id
GROUP BY c.segment;


-- 6. Vérification après rafraîchissement
SELECT * FROM mv_synthese_segments;

/* CONCLUSION :
Après le rafraîchissement, la nouvelle commande est
prise en compte dans les statistiques.

Le nombre de commandes et le chiffre d'affaires
par segment sont maintenant actualisés.
*/

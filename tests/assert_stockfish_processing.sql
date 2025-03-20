{{ config(warn_if = '>1', error_if = '>10') }}

WITH agg_game AS (
  SELECT 
    username,
    game_uuid,
    ANY_VALUE(pgn) AS pgn,
  FROM {{ ref ('games') }}
  GROUP BY 1, 2
)

, agg_moves AS (
  SELECT
    game_uuid,
    COUNT(*) AS nb_moves
  FROM {{ ref ('games_moves') }}
  GROUP BY 1
)

, extract_moves_count AS (
  SELECT 
    *,
    ( SELECT MAX(CAST(moves AS INT64)) FROM UNNEST(REGEXP_EXTRACT_ALL(pgn, r'(\d+)\. ')) AS moves ) AS nb_move_p1,
    ( SELECT MAX(CAST(moves AS INT64)) FROM UNNEST(REGEXP_EXTRACT_ALL(pgn, r'(\d+)\... ')) AS moves ) AS nb_move_p2,
  FROM agg_game
  LEFT OUTER JOIN agg_moves USING (game_uuid)
)

SELECT *
FROM extract_moves_count
WHERE COALESCE(nb_move_p1, 0) + COALESCE(nb_move_p2, 0) <> COALESCE(nb_moves, 0)
{{ config(warn_if = '>1', error_if = '>10') }}

WITH agg_game AS (
  SELECT DISTINCT -- game_uuid is only unique per [username]
    game_uuid, 
  FROM {{ ref ('games') }}
  GROUP BY 1
)

, agg_times AS (
  SELECT
    game_uuid,
    MAX(move_number) AS max_move_number_times,
    MIN(move_number) AS min_move_number_times,
  FROM {{ ref ('games_times') }}
  INNER JOIN {{ ref ('games') }} -- keep only relevant games
    USING (game_uuid)
  GROUP BY 1
)

, agg_moves AS (
  SELECT
    game_uuid,
    MAX(move_number) AS max_move_number_moves,
    MIN(move_number) AS min_move_number_moves,
  FROM {{ ref ('games_moves') }}
  INNER JOIN {{ ref ('games') }} -- keep only relevant games
    USING (game_uuid)
  GROUP BY 1
)

SELECT * FROM agg_times
FULL OUTER JOIN agg_moves
  USING (game_uuid)
WHERE TRUE  
  AND max_move_number_times <> max_move_number_moves
  OR min_move_number_times <> min_move_number_moves
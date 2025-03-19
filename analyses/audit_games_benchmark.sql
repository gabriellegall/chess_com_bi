-- SQL query to control the blunder rates calculations in Metabase against the source data
-- E.g. Rate Massive Blunder:

WITH agg_data AS (
  SELECT 
    COUNT(DISTINCT game_uuid) AS nb_games,
    COUNT(DISTINCT CASE WHEN miss_category_playing = 'Massive Blunder' THEN game_uuid ELSE NULL END) AS nb_games_massive_blunder
  FROM {{ ref("agg_games_with_moves") }}
  WHERE TRUE
    AND username = 'Zundorn'
    AND time_class = 'blitz'
    AND end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 MONTH, MONTH)
    AND playing_rating_range = opponent_rating_range
    AND playing_rating_range = '600-700'
)

SELECT
  *,
  nb_games_massive_blunder / nb_games AS rate_massive_blunder
FROM agg_data
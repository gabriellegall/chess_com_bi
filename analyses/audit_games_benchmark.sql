-- SQL query to control the blunder rates calculations in Metabase against the source data
-- game_phase can be added to control this aggregation level too.

WITH agg_data_username AS (
  SELECT 
    -- game_phase,
    COUNT(DISTINCT game_uuid) AS nb_games,
    COUNT(DISTINCT CASE WHEN miss_category_playing IN ('Blunder','Massive Blunder') THEN game_uuid ELSE NULL END) AS nb_games_blunder,
    COUNT(DISTINCT CASE WHEN miss_category_playing = 'Massive Blunder' THEN game_uuid ELSE NULL END) AS nb_games_massive_blunder,
  FROM {{ ref("games_with_moves") }}
  WHERE TRUE
    AND username = 'Zundorn'
    AND time_class = 'blitz'
    AND end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 MONTH, MONTH)
    AND playing_rating_range = opponent_rating_range
    AND playing_rating_range = '600-700'
  GROUP BY ALL
)

, agg_data_benchmark AS (
  SELECT 
    -- game_phase,
    COUNT(DISTINCT game_uuid) AS nb_games,
    COUNT(DISTINCT CASE WHEN miss_category_playing IN ('Blunder','Massive Blunder') THEN game_uuid ELSE NULL END) AS nb_games_blunder,
    COUNT(DISTINCT CASE WHEN miss_category_playing = 'Massive Blunder' THEN game_uuid ELSE NULL END) AS nb_games_massive_blunder,
  FROM {{ ref("games_with_moves") }}
  WHERE TRUE
    AND username <> 'Zundorn'
    AND time_class = 'blitz'
    -- AND end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 MONTH, MONTH)
    AND playing_rating_range = opponent_rating_range
    AND playing_rating_range = '600-700'
  GROUP BY ALL
)

SELECT
  "username",
  *,
  nb_games_blunder / nb_games AS rate_massive_blunder,
  nb_games_massive_blunder / nb_games AS rate_massive_blunder,
FROM agg_data_username

UNION ALL 

SELECT
  "benchmark",
  *,
  nb_games_blunder / nb_games AS rate_massive_blunder,
  nb_games_massive_blunder / nb_games AS rate_massive_blunder,
FROM agg_data_benchmark
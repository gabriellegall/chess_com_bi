{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH define_expected_moves AS (
SELECT  
    game_uuid,
    username,
    ANY_VALUE(time_class) AS time_class,
    ANY_VALUE(playing_result) AS playing_result,
    ANY_VALUE(opponent_rating_range) AS opponent_rating_range,
    ANY_VALUE(url) AS url,
    ANY_VALUE(end_time) AS end_time,
    ANY_VALUE(playing_as) AS playing_as,
    ARRAY_CONCAT([1], GENERATE_ARRAY(5, 60, 5)) AS expected_move_number
FROM {{ ref('games_with_moves') }}
WHERE 
    end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 WEEK, WEEK)
GROUP BY 1, 2
)

, unnest_and_join AS (
SELECT 
  expt.* EXCEPT (expected_move_number),
  move_number,
  games_moves.score_playing,
FROM define_expected_moves expt, 
  UNNEST (expected_move_number) AS move_number
LEFT OUTER JOIN {{ ref('games_with_moves') }} games_moves 
  USING (username, game_uuid, move_number)
)

SELECT 
  * EXCEPT (score_playing),
  COALESCE (
    score_playing,
    LAST_VALUE(score_playing IGNORE NULLS) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
  ) AS score_playing
FROM unnest_and_join
ORDER BY end_time DESC

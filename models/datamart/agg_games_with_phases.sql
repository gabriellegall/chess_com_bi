{{ config(materialized='view') }}

SELECT 
    username,
    game_uuid,
    game_phase,
    ANY_VALUE(end_time) AS end_time,
    ANY_VALUE(end_time_month) AS end_time_month, 
    ANY_VALUE(opponent_rating_range) AS opponent_rating_range,
    ANY_VALUE(playing_as) AS playing_as,
    ANY_VALUE(playing_result) AS playing_result,
    ANY_VALUE(time_class) AS time_class,
    ANY_VALUE(median_score_playing_game_phase) AS median_score_playing_game_phase,
FROM {{ ref ('games_with_moves') }}
GROUP BY 1, 2, 3

{{ config(materialized='view') }}

SELECT 
    username,
    game_uuid,
    game_phase,
    end_time,
    end_time_month, 
    opponent_rating_range,
    playing_as
    playing_result,
    time_class,
    ANY_VALUE(median_score_playing_game_phase) AS median_score_playing_game_phase,
FROM {{ ref ('games_with_moves') }}
GROUP BY ALL

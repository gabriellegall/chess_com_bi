{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

SELECT  
    game_uuid,
    username,
    time_class,
    playing_result,
    score_playing,
    opponent_rating_range,
    url,
    move_number,
    end_time,
    playing_as,
FROM {{ ref('games_with_moves') }}
WHERE 
    end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 MONTH, MONTH)
    AND (MOD(move_number, 5) = 0 OR move_number = 1)
    AND move_number <= 60
ORDER BY end_time DESC
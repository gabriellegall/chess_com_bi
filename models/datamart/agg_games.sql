{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

SELECT 
    username,
    game_uuid,
    ANY_VALUE(end_time) AS end_time,
    ANY_VALUE(end_time_month) AS end_time_month, 
    ANY_VALUE(opponent_rating_range) AS opponent_rating_range,
    ANY_VALUE(playing_as) AS playing_as,
    ANY_VALUE(playing_result) AS playing_result,
    ANY_VALUE(time_class) AS time_class,
    ANY_VALUE(game_total_nb_blunder) AS game_total_nb_blunder,
    ANY_VALUE(game_total_nb_massive_blunder) AS game_total_nb_massive_blunder,
    ANY_VALUE(game_total_nb_missed_opportunity) AS game_total_nb_missed_opportunity,
    ANY_VALUE(game_total_nb_throw) AS game_total_nb_throw,
    STRING_AGG(CAST(massive_blunder_move_number_playing AS STRING), ', ') AS massive_blunder_move_number_playing,
FROM {{ ref ('games_with_moves') }}
GROUP BY 1, 2

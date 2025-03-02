{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH aggregate_fields AS (
    SELECT 
        username,
        game_uuid,
        ANY_VALUE(url) AS url,
        ANY_VALUE(end_time) AS end_time,
        ANY_VALUE(end_time_date) AS end_time_date,
        ANY_VALUE(end_time_month) AS end_time_month, 
        ANY_VALUE(opponent_rating) AS opponent_rating,
        ANY_VALUE(opponent_rating_range) AS opponent_rating_range,
        ANY_VALUE(playing_as) AS playing_as,
        ANY_VALUE(playing_result) AS playing_result,
        ANY_VALUE(time_class) AS time_class,
        ANY_VALUE(median_score_playing) AS median_score_playing,
        ANY_VALUE(game_total_nb_blunder) AS game_total_nb_blunder,
        ANY_VALUE(game_total_nb_massive_blunder) AS game_total_nb_massive_blunder,
        ANY_VALUE(game_total_nb_missed_opportunity) AS game_total_nb_missed_opportunity,
        ANY_VALUE(game_total_nb_throw) AS game_total_nb_throw,
        STRING_AGG(CAST(massive_blunder_move_number_playing AS STRING), ', ') AS massive_blunder_move_number_playing,
        MAX(score_playing) AS max_score_playing,
        MIN(score_playing) AS min_score_playing,
        STDDEV_SAMP(score_playing) AS std_score_playing,
        MAX(move_number) AS total_move_number,
    FROM {{ ref ('games_with_moves') }}
    GROUP BY 1, 2
)

SELECT 
    *,
    COUNT(*) OVER (PARTITION BY username, end_time_month, time_class, opponent_rating_range) > {{ var('datamart')['min_games_played'] }} AS has_enough_games_for_username_month_timeclass_opprating,
FROM aggregate_fields
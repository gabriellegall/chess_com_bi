{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH aggregate_fields AS (
    SELECT 
        username,
        game_uuid,
        game_phase,
        -- Dimensions
        ANY_VALUE(url)                                                      AS url,
        ANY_VALUE(end_time)                                                 AS end_time,
        ANY_VALUE(end_time_date)                                            AS end_time_date,
        ANY_VALUE(end_time_month)                                           AS end_time_month, 
        ANY_VALUE(playing_rating)                                           AS playing_rating,
        ANY_VALUE(playing_rating_range)                                     AS playing_rating_range,
        ANY_VALUE(opponent_rating)                                          AS opponent_rating,
        ANY_VALUE(opponent_rating_range)                                    AS opponent_rating_range,
        ANY_VALUE(playing_as)                                               AS playing_as,
        ANY_VALUE(playing_result)                                           AS playing_result,
        ANY_VALUE(time_class)                                               AS time_class,
        -- Measures
        COUNTIF(miss_category_playing IN ('Blunder', 'Massive Blunder'))    AS nb_blunder_playing,
        COUNTIF(miss_category_playing = 'Massive Blunder')                  AS nb_massive_blunder_playing,
        COUNTIF(miss_context_playing = 'Throw')                             AS nb_throw_playing,
        COUNTIF(miss_context_playing = 'Missed Opportunity')                AS nb_missed_opportunity_playing,
        ANY_VALUE(median_score_playing_game_phase)                          AS median_score_playing,
    FROM {{ ref ('games_with_moves') }}
    GROUP BY 1, 2, 3
)

SELECT * FROM aggregate_fields
{{ config(
    enabled=True,
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH aggregate_fields AS (
    SELECT 
        username,
        game_uuid,
        game_phase,
        CASE 
            WHEN GROUPING(game_phase) = 1 THEN 'Recent Games'
            ELSE game_phase
            END AS game_phase_key,
        CASE 
            WHEN GROUPING(game_phase) = 1 THEN 'Games'
            ELSE 'Game Phases'
            END AS aggregation_level,
        -- Dimensions
        ANY_VALUE(url)                                                                                  AS url,
        ANY_VALUE(end_time)                                                                             AS end_time,
        ANY_VALUE(end_time_date)                                                                        AS end_time_date,
        ANY_VALUE(end_time_month)                                                                       AS end_time_month, 
        ANY_VALUE(playing_rating)                                                                       AS playing_rating,
        ANY_VALUE(playing_rating_range)                                                                 AS playing_rating_range,
        ANY_VALUE(opponent_rating)                                                                      AS opponent_rating,
        ANY_VALUE(opponent_rating_range)                                                                AS opponent_rating_range,
        ANY_VALUE(playing_as)                                                                           AS playing_as,
        ANY_VALUE(playing_result)                                                                       AS playing_result,
        ANY_VALUE(time_class)                                                                           AS time_class,
        ANY_VALUE(first_blunder_playing_turn_name)                                                      AS first_blunder_playing_turn_name,
        -- Measures                         
        COUNTIF(miss_category_playing IN ('Blunder', 'Massive Blunder'))                                AS nb_blunder_playing,
        COUNTIF(miss_category_playing = 'Massive Blunder')                                              AS nb_massive_blunder_playing,
        STRING_AGG(CAST(massive_blunder_move_number_playing AS STRING), ', ')                           AS massive_blunder_move_number_playing,
        COUNTIF(miss_context_playing = 'Throw')                                                         AS nb_throw_playing,
        COUNTIF(miss_context_playing = 'Missed Opportunity')                                            AS nb_missed_opportunity_playing,
        APPROX_QUANTILES(score_playing, 100)[OFFSET(50)]                                                AS median_score_playing,
        MAX(score_playing)                                                                              AS max_score_playing,
        MIN(score_playing)                                                                              AS min_score_playing,
        STDDEV_SAMP(score_playing)                                                                      AS std_score_playing,
        -- Calculated Dimensions
        CASE 
            WHEN MAX(score_playing) < {{ var('should_win_range')['low'] }} 
                THEN '0-{{ var('should_win_range')['low'] }}'
            WHEN MAX(score_playing) < {{ var('should_win_range')['mid'] }} 
                THEN '{{ var('should_win_range')['low'] }}-{{ var('should_win_range')['mid'] }}'
            ELSE '{{ var('should_win_range')['mid'] }}+' END                                            AS max_score_playing_range, 
        CASE    
            WHEN MAX(score_playing) > {{ var('should_win_range')['mid'] }} 
                THEN 'Decisive advantage'    
            ELSE 'No decisive advantage' END                                                            AS max_score_playing_type,
    FROM {{ ref ('games_with_moves') }}
    GROUP BY GROUPING SETS (
        (1, 2, 3),
        (1, 2)
        )
)

SELECT 
    *,
    COUNT(*) OVER (PARTITION BY username, time_class, end_time_month, opponent_rating_range, game_phase_key) > {{ var('datamart')['min_games_played'] }} AS has_enough_games
FROM aggregate_fields
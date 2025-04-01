{{ config(materialized='view') }}


WITH filter_table AS (
    SELECT 
        *
    FROM {{ source('staging', 'games') }} 
    WHERE TRUE 
        AND LENGTH(pgn) > 0             -- Only games respecting this condition are processed by Stockfish
        AND rules = 'chess'             -- Only games respecting this condition are processed by Stockfish
        AND LENGTH(initial_setup) = 0   -- Also, ignore games with a pre-setup
)

, cast_types AS (
    SELECT 
        *,
        DATETIME(TIMESTAMP_SECONDS(end_time_integer), {{ var('data_conversion')['utc_to_target_timezone'] }})                       AS end_time, 
        DATE(DATETIME(TIMESTAMP_SECONDS(end_time_integer), {{ var('data_conversion')['utc_to_target_timezone'] }}))                 AS end_time_date,
        FORMAT_DATE('%Y-%m', DATETIME(TIMESTAMP_SECONDS(end_time_integer), {{ var('data_conversion')['utc_to_target_timezone'] }})) AS end_time_month,
    FROM filter_table    
)

, define_playing AS (
    SELECT 
        *,
        CASE 
            WHEN LOWER(username) = LOWER(white_username) THEN 'White'
            WHEN LOWER(username) = LOWER(black_username) THEN 'Black'
            ELSE NULL END AS playing_as
    FROM cast_types
)

, define_result AS (
    SELECT 
        *,
        CASE
            WHEN playing_as = 'White' THEN white_result
            WHEN playing_as = 'Black' THEN black_result
            ELSE NULL END AS playing_result_detailed,
        CASE
            WHEN playing_as = 'White' THEN white_rating
            WHEN playing_as = 'Black' THEN black_rating
            ELSE NULL END AS playing_rating,
        CASE
            WHEN playing_as = 'White' THEN black_rating
            WHEN playing_as = 'Black' THEN white_rating
            ELSE NULL END AS opponent_rating
    FROM define_playing
)

, simplify_result AS (
    SELECT 
        *,
        CASE    
            WHEN playing_result_detailed IN ('checkmated', 'resigned', 'abandoned', 'timeout')                                      THEN 'Lose'
            WHEN playing_result_detailed IN ('win')                                                                                 THEN 'Win'
            WHEN playing_result_detailed IN ('stalemate', 'repetition', 'agreed', 'timevsinsufficient', 'insufficient', '50move')   THEN 'Draw'
            ELSE NULL END AS playing_result
    FROM define_result
)

SELECT 
    * 
FROM simplify_result
{{ config(materialized='view') }}


WITH cast_types AS (
    SELECT 
        * EXCEPT(end_time),
        DATE(end_time) AS end_time
    FROM {{ source('staging', 'games') }} 
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
            WHEN playing_result_detailed IN ('checkmated', 'resigned', 'abandoned', 'timeout')                           THEN 'Lose'
            WHEN playing_result_detailed IN ('win')                                                                      THEN 'Win'
            WHEN playing_result_detailed IN ('stalemate', 'repetition', 'agreed', 'timevsinsufficient', 'insufficient')  THEN 'Draw'
            ELSE NULL END AS playing_result
    FROM define_result
)

SELECT 
    * 
FROM simplify_result
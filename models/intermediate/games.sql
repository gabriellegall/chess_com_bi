{{ config(materialized='view') }}

WITH define_playing AS (
    SELECT 
        *,
        CASE 
            WHEN LOWER(username) = LOWER(white_username) THEN 'White'
            WHEN LOWER(username) = LOWER(black_username) THEN 'Black'
            ELSE NULL END AS playing_as
    FROM {{ source('staging', 'games') }}
)

, define_result AS (
    SELECT 
        *,
        CASE
            WHEN playing_as = 'White' THEN white_result
            WHEN playing_as = 'Black' THEN black_result
            ELSE NULL END AS playing_result_detailed
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
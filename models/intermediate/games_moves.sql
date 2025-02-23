{{ config(materialized='view') }}

WITH cast_types AS (
    SELECT 
        * EXCEPT(move_number),
        CAST(move_number AS INT64) AS move_number
    FROM {{ source('staging', 'games_moves') }}
)

, color_definition AS (
    SELECT 
        *,
        IF(MOD(move_number, 2) = 1, 'White', 'Black')  AS player_color_turn,
        - score_white                                  AS score_black,
        1 / (1 + EXP(-0.004 * score_white))            AS win_probability_white,
        1 - 1 / (1 + EXP(-0.004 * score_white))        AS win_probability_black,
    FROM cast_types
)

SELECT 
    *
FROM color_definition
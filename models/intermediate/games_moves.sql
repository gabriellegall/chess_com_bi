{{ config(materialized='view') }}

WITH color_definition AS (
    SELECT 
        *,
        move_number - 1                                 AS move_number_chesscom,
        IF(MOD(move_number, 2) = 1, 'White', 'Black')   AS player_color_turn,
        - score_white                                   AS score_black,
        1 / (1 + EXP(-0.004 * score_white))             AS win_probability_white,
        1 - 1 / (1 + EXP(-0.004 * score_white))         AS win_probability_black,
    FROM {{ source('staging', 'games_moves') }}
)

SELECT 
    *
FROM color_definition
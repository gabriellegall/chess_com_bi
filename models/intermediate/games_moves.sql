{{ config(materialized='view') }}

WITH color_definition AS (
    SELECT 
        *,
        move_number - 1                                 AS move_number_chesscom,
        IF(MOD(move_number, 2) = 1, 'White', 'Black')   AS player_color_turn,
        1 / (1 + EXP(-0.004 * score))                   AS win_probability
    FROM {{ source('staging', 'games_moves') }}
)

SELECT 
    *,
    CASE
        WHEN player_color_turn = 'White' THEN - score 
        WHEN player_color_turn = 'Black' THEN score 
        ELSE NULL END AS score_black_pov,
    CASE
        WHEN player_color_turn = 'White' THEN score 
        WHEN player_color_turn = 'Black' THEN - score 
        ELSE NULL END AS score_white_pov,
    CASE
        WHEN player_color_turn = 'White' THEN 1 - win_probability 
        WHEN player_color_turn = 'Black' THEN win_probability 
        ELSE NULL END AS win_probability_black_pov,
    CASE
        WHEN player_color_turn = 'White' THEN win_probability 
        WHEN player_color_turn = 'Black' THEN 1 - win_probability 
        ELSE NULL END AS win_probability_white_pov,
FROM color_definition
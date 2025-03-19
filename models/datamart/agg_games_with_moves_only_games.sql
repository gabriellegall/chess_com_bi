{{ config(
    enabled=True,
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

SELECT * FROM {{ ref('agg_games_with_moves') }}
WHERE aggregation_level = 'Games'
{{ config(materialized='view') }}

SELECT 
    *,
    CASE 
        WHEN LOWER(username) = LOWER(white_username) THEN 'White'
        WHEN LOWER(username) = LOWER(black_username) THEN 'Black'
        ELSE NULL END AS playing_as
FROM {{ source('staging', 'games') }}
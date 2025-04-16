{{ config(materialized='view') }}

WITH games_times AS (
  SELECT 
    username,
    game_uuid,
    REGEXP_EXTRACT_ALL(pgn, r'\{\[%clk [^]]+\]\}') AS game_times
  FROM {{ ref ("games") }}
)

, extract_time AS (
  SELECT 
    username,
    game_uuid,
    ROW_NUMBER() OVER (PARTITION BY game_uuid ORDER BY time_remaining ASC) AS move_number,
    time_remaining,
    CAST(REGEXP_EXTRACT(time_remaining, r'(\d{1,2})') AS INT64)                         AS time_part_remaining_hours, -- first 1 or 2 digits
    CAST(REGEXP_EXTRACT(time_remaining, r'\d{1,2}:(\d{2})') AS INT64)                   AS time_part_remaining_minutes, -- second 2 digits after ":"
    CAST(REGEXP_EXTRACT(time_remaining, r'\d{1,2}:\d{2}:(\d{2}(?:\.\d+)?)') AS FLOAT64) AS time_part_remaining_seconds, -- third 2 digits after ":", with the digit after "." if any
  FROM games_times, UNNEST(game_times) AS time_remaining
)

, calculate_minutes_remaining AS (
  SELECT 
    *,
    time_part_remaining_hours * 3600 + time_part_remaining_minutes * 60 + time_part_remaining_seconds AS time_remaining_seconds
  FROM extract_time
)

SELECT 
  * EXCEPT (time_part_remaining_hours, time_part_remaining_minutes, time_part_remaining_seconds) 
FROM calculate_minutes_remaining
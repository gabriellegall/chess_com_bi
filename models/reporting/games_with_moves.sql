{{ config(materialized='view') }}

WITH score_defintion AS (
  SELECT 
    games.game_uuid,
    games.archive_url,
    games.username,
    games.url,
    games.end_time,
    games.time_class,
    games.white_username,
    games.white_rating,
    games.black_username,
    games.black_rating,
    games.bq_load_date,
    games_moves.move_number_chesscom,
    games_moves.move,
    games.playing_as, 
    games_moves.player_color_turn,
    CASE 
      WHEN playing_as = 'White' THEN score_white
      WHEN playing_as = 'Black' THEN score_black
      ELSE NULL END AS score_playing,
    CASE 
      WHEN playing_as = 'White' THEN win_probability_white
      WHEN playing_as = 'Black' THEN win_probability_black
      ELSE NULL END AS win_probability_playing
  FROM {{ ref ('games') }} AS games
  INNER JOIN {{ ref ('games_moves') }} AS games_moves
    USING (game_uuid)
)

, previous_score AS (
  SELECT 
    *,
    LAG(score_playing) OVER (PARTITION BY game_uuid ORDER BY move_number_chesscom ASC)                      AS prev_score_playing,
    score_playing - LAG(score_playing) OVER (PARTITION BY game_uuid ORDER BY move_number_chesscom ASC)      AS variance_score_playing
  FROM score_defintion
)

, position_definition AS (
  SELECT 
    *,
    CASE 
      WHEN variance_score_playing <= -1000 THEN 'Massive Blunder'
      WHEN variance_score_playing <= -300 THEN 'Blunder'
      WHEN variance_score_playing <= -100 THEN 'Mistake'
      ELSE NULL END AS move_category_playing,
    CASE
      WHEN variance_score_playing >= 1000 THEN 'Massive Blunder'
      WHEN variance_score_playing >= 300 THEN 'Blunder'
      WHEN variance_score_playing >= 100 THEN 'Mistake'
      ELSE NULL END AS move_category_opponent,
    CASE  
      WHEN ABS(score_playing) <= 100 THEN 'Even'
      WHEN score_playing <= 100 THEN 'Disadvantage'
      WHEN score_playing >= 100 THEN 'Advantage'
      ELSE NULL END AS position_advantage_status_playing
  FROM previous_score
)

SELECT * FROM position_definition
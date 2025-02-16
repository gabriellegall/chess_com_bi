{{ config(materialized='view') }}

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
    WHEN playing_as = 'White' THEN score_white_pov
    WHEN playing_as = 'Black' THEN score_black_pov
    ELSE NULL END AS score_playing_pov,
  CASE 
    WHEN playing_as = 'White' THEN win_probability_white_pov
    WHEN playing_as = 'Black' THEN win_probability_black_pov
    ELSE NULL END AS win_probability_playing_pov
FROM {{ ref ('games') }} AS games
INNER JOIN {{ ref ('games_moves') }} AS games_moves
  USING (game_uuid)
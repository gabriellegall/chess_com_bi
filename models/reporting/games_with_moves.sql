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
    games_moves.move_number,
    games_moves.move,
    CASE  
      WHEN move_number <= 15 THEN 'Early Game'
      WHEN move_number <= 30 THEN 'Mid Game'
      ELSE 'Late Game' END as game_phase,
    games_moves.player_color_turn,
    games.playing_as,
    games.playing_rating, 
    CASE 
        WHEN games.playing_rating < 500 THEN '0-500'
        WHEN games.playing_rating < 600 THEN '500-600'
        ELSE '600+'
    END AS playing_rating_range,
    games.opponent_rating, 
    CASE 
        WHEN games.opponent_rating < 500 THEN '0-500'
        WHEN games.opponent_rating < 600 THEN '500-600'
        ELSE '600+'
    END AS opponent_rating_range,
    games.playing_result,
    CASE 
      WHEN playing_as = 'White' THEN score_white
      WHEN playing_as = 'Black' THEN score_black
      ELSE NULL END AS score_playing,
    CASE 
      WHEN playing_as = 'White' THEN win_probability_white
      WHEN playing_as = 'Black' THEN win_probability_black
      ELSE NULL END AS win_probability_playing,
  FROM {{ ref ('games') }} AS games
  INNER JOIN {{ ref ('games_moves') }} AS games_moves
    USING (game_uuid)
)

, previous_score AS (
  SELECT 
    *,
    LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)                      AS prev_score_playing,
    score_playing - LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)      AS variance_score_playing,
    PERCENTILE_CONT(score_playing, 0.5) OVER (PARTITION BY game_uuid, username, game_phase)                  AS median_score_playing_game_phase,
    MAX(move_number) OVER (PARTITION BY game_uuid, username)                                                 AS game_total_nb_moves,
  FROM score_defintion
)

, position_definition AS (
  SELECT 
    *,
    -- To do : check why the condition is necessary here : player_color_turn = playing_as
    CASE 
      WHEN player_color_turn = playing_as AND variance_score_playing <= -600 AND prev_score_playing > -300 AND score_playing < 300 THEN 'Massive Blunder'
      WHEN player_color_turn = playing_as AND variance_score_playing <= -300 AND prev_score_playing > -300 AND score_playing < 300 THEN 'Blunder'
      WHEN player_color_turn = playing_as AND variance_score_playing <= -100 THEN 'Mistake'
      ELSE NULL END AS miss_category_playing,
    CASE 
      WHEN player_color_turn = playing_as AND variance_score_playing <= -100 THEN move_number
      ELSE NULL END AS miss_move_number_playing,
    CASE 
      WHEN player_color_turn = playing_as AND variance_score_playing <= -600 AND prev_score_playing > -300 AND score_playing < 300 THEN move_number
      ELSE NULL END AS massive_blunder_move_number_playing,
    CASE
      WHEN player_color_turn <> playing_as AND variance_score_playing >= 600 AND prev_score_playing < 300 AND score_playing > -300 THEN 'Massive Blunder'
      WHEN player_color_turn <> playing_as AND variance_score_playing >= 300 AND prev_score_playing < 300 AND score_playing > -300 THEN 'Blunder'
      WHEN player_color_turn <> playing_as AND variance_score_playing >= 100 THEN 'Mistake'
      ELSE NULL END AS miss_category_opponent,
    CASE 
      WHEN player_color_turn <> playing_as AND variance_score_playing >= 100 THEN move_number
      ELSE NULL END AS miss_move_number_opponent,
    CASE  
      WHEN ABS(score_playing) <= 250 THEN 'Even'
      WHEN score_playing <= -250 THEN 'Disadvantage'
      WHEN score_playing >= 250 THEN 'Advantage'
      ELSE NULL END AS position_status_playing
  FROM previous_score
)

, prev_position_definition AS (
  SELECT 
    *,
    LAG(position_status_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC) AS prev_position_status_playing,
  FROM position_definition
)

, context_definition AS (
  SELECT 
    *,
    CASE  
      WHEN miss_category_playing IS NOT NULL AND prev_position_status_playing IN ('Even', 'Disadvantage')   THEN 'Throw'
      WHEN miss_category_playing IS NOT NULL AND prev_position_status_playing IN ('Advantage')              THEN 'Missed Opportunity' 
      ELSE NULL END AS  miss_context_playing,
    CASE  
      WHEN miss_category_opponent IS NOT NULL AND prev_position_status_playing IN ('Even', 'Disadvantage')  THEN 'Throw'
      WHEN miss_category_opponent IS NOT NULL AND prev_position_status_playing IN ('Advantage')             THEN 'Missed Opportunity' 
      ELSE NULL END AS  miss_context_opponent
  FROM prev_position_definition
)

SELECT 
  *,
  COUNTIF(miss_category_playing = 'Massive Blunder') OVER (PARTITION BY game_uuid, username)    AS game_total_nb_massive_blunder,
  COUNTIF(miss_category_playing = 'Blunder') OVER (PARTITION BY game_uuid, username)            AS game_total_nb_blunder,
  COUNTIF(miss_context_playing = 'Throw') OVER (PARTITION BY game_uuid, username)               AS game_total_nb_throw,
  COUNTIF(miss_context_playing = 'Missed Opportunity') OVER (PARTITION BY game_uuid, username)  AS game_total_nb_missed_opportunity,
FROM context_definition
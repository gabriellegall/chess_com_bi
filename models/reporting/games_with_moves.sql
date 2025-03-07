{{ config(materialized='view') }}

WITH games_scope AS (
  SELECT
    *
  FROM {{ ref ('games') }}
  WHERE end_time_date >= {{ var('data_scope')['first_end_date'] }}
)

, score_defintion AS (
  SELECT 
    games.game_uuid,
    games.archive_url,
    games.username,
    games.url,
    games.end_time,
    games.end_time_date,
    games.end_time_month,
    games.time_class,
    games.white_username,
    games.white_rating,
    games.black_username,
    games.black_rating,
    games.bq_load_date,
    games_moves.move_number,
    games_moves.move,
    CASE  
      WHEN move_number <= {{ var('game_phases')['end_early_game_move'] }} THEN '1-Early Game'
      WHEN move_number <= {{ var('game_phases')['end_mid_game_move'] }} THEN '2-Mid Game'
      ELSE '3-Late Game' END as game_phase,
    games_moves.player_color_turn,
    games.playing_as,
    player_color_turn = playing_as AS is_playing_turn,
    CASE
      WHEN player_color_turn = playing_as THEN 'Playing Turn'
      ELSE 'Opponent Turn' END AS playing_turn_name,
    games.playing_rating, 
    CASE 
      WHEN games.playing_rating < {{ var('elo_range')['low'] }} THEN '0-{{ var('elo_range')['low'] }}'
      WHEN games.playing_rating < {{ var('elo_range')['mid'] }} THEN '{{ var('elo_range')['low'] }}-{{ var('elo_range')['mid'] }}'
      ELSE '{{ var('elo_range')['mid'] }}+' END AS playing_rating_range,
    games.opponent_rating,
    CASE 
      WHEN games.opponent_rating < {{ var('elo_range')['low'] }} THEN '0-{{ var('elo_range')['low'] }}'
      WHEN games.opponent_rating < {{ var('elo_range')['mid'] }} THEN '{{ var('elo_range')['low'] }}-{{ var('elo_range')['mid'] }}'
      ELSE '{{ var('elo_range')['mid'] }}+' END AS opponent_rating_range,
    games.playing_result,
    CASE 
      WHEN playing_as = 'White' THEN score_white
      WHEN playing_as = 'Black' THEN score_black
      ELSE NULL END AS score_playing,
    CASE 
      WHEN playing_as = 'White' THEN win_probability_white
      WHEN playing_as = 'Black' THEN win_probability_black
      ELSE NULL END AS win_probability_playing,
  FROM games_scope AS games
  INNER JOIN {{ ref ('games_moves') }} AS games_moves
    USING (game_uuid)
)

, previous_score AS (
  SELECT 
    *,
    LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)                      AS prev_score_playing,
    score_playing - LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)      AS variance_score_playing,
    PERCENTILE_CONT(score_playing, 0.5) OVER (PARTITION BY game_uuid, username, game_phase)                  AS median_score_playing_game_phase,
  FROM score_defintion
)

, position_definition AS (
  SELECT 
    *,
    -- Playing
    CASE 
      WHEN is_playing_turn 
          AND variance_score_playing <= -{{ var('score_thresholds')['variance_score_massive_blunder'] }} 
          AND prev_score_playing > -{{ var('score_thresholds')['score_balanced_limit'] }} 
          AND score_playing < {{ var('score_thresholds')['score_balanced_limit'] }} 
          THEN 'Massive Blunder'
      WHEN is_playing_turn 
          AND variance_score_playing <= -{{ var('score_thresholds')['variance_score_blunder'] }} 
          AND prev_score_playing > -{{ var('score_thresholds')['score_balanced_limit'] }} 
          AND score_playing < {{ var('score_thresholds')['score_balanced_limit'] }} 
          THEN 'Blunder'
      WHEN is_playing_turn 
          AND variance_score_playing <= -{{ var('score_thresholds')['variance_score_mistake'] }} 
          THEN 'Mistake'
      ELSE NULL END AS miss_category_playing,
    CASE 
      WHEN is_playing_turn 
          AND variance_score_playing <= -{{ var('score_thresholds')['variance_score_mistake'] }} 
          THEN move_number
      ELSE NULL END AS miss_move_number_playing,
    CASE 
      WHEN is_playing_turn 
          AND variance_score_playing <= -{{ var('score_thresholds')['variance_score_massive_blunder'] }} 
          AND prev_score_playing > -{{ var('score_thresholds')['score_balanced_limit'] }} 
          AND score_playing < {{ var('score_thresholds')['score_balanced_limit'] }} 
          THEN move_number
      ELSE NULL END AS massive_blunder_move_number_playing,
    -- Opponent
    CASE
      WHEN NOT is_playing_turn 
          AND variance_score_playing >= {{ var('score_thresholds')['variance_score_massive_blunder'] }} 
          AND prev_score_playing < {{ var('score_thresholds')['score_balanced_limit'] }} 
          AND score_playing > -{{ var('score_thresholds')['score_balanced_limit'] }} 
          THEN 'Massive Blunder'
      WHEN NOT is_playing_turn 
          AND variance_score_playing >= {{ var('score_thresholds')['variance_score_blunder'] }} 
          AND prev_score_playing < {{ var('score_thresholds')['score_balanced_limit'] }} 
          AND score_playing > -{{ var('score_thresholds')['score_balanced_limit'] }} 
          THEN 'Blunder'
      WHEN NOT is_playing_turn 
          AND variance_score_playing >= {{ var('score_thresholds')['variance_score_mistake'] }} 
          THEN 'Mistake'
      ELSE NULL END AS miss_category_opponent,
    CASE 
      WHEN NOT is_playing_turn 
          AND variance_score_playing >= {{ var('score_thresholds')['variance_score_mistake'] }} 
          THEN move_number
      ELSE NULL END AS miss_move_number_opponent,
    CASE  
      WHEN ABS(score_playing) <= {{ var('score_thresholds')['even_score_limit'] }} THEN 'Even'
      WHEN score_playing <= -{{ var('score_thresholds')['even_score_limit'] }} THEN 'Disadvantage'
      WHEN score_playing >= {{ var('score_thresholds')['even_score_limit'] }} THEN 'Advantage'
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
      WHEN miss_category_playing IN ('Blunder', 'Massive Blunder') AND prev_position_status_playing IN ('Even', 'Disadvantage')   THEN 'Throw'
      WHEN miss_category_playing IN ('Blunder', 'Massive Blunder') AND prev_position_status_playing IN ('Advantage')              THEN 'Missed Opportunity' 
      ELSE NULL END AS miss_context_playing,
    CASE  
      WHEN miss_category_opponent IN ('Blunder', 'Massive Blunder') AND prev_position_status_playing IN ('Even', 'Disadvantage')  THEN 'Throw'
      WHEN miss_category_opponent IN ('Blunder', 'Massive Blunder') AND prev_position_status_playing IN ('Advantage')             THEN 'Missed Opportunity' 
      ELSE NULL END AS miss_context_opponent,
  FROM prev_position_definition
)

, game_level_calculation AS (
  SELECT 
    *,
    PERCENTILE_CONT(score_playing, 0.5) OVER game_window                                                                          AS game_median_score_playing,
    COUNTIF(miss_category_playing = 'Massive Blunder') OVER game_window                                                           AS game_total_nb_massive_blunder,
    CASE    
      WHEN COUNTIF(miss_category_playing = 'Massive Blunder') OVER game_window > 0 THEN 'Massive Blunder(s)'    
      ELSE 'No Massive Blunder' END                                                                                               AS game_total_massive_blunder,
    COUNTIF(miss_category_playing = 'Blunder') OVER game_window                                                                   AS game_total_nb_blunder,
    COUNTIF(miss_context_playing = 'Throw') OVER game_window                                                                      AS game_total_nb_throw,
    COUNTIF(miss_context_playing = 'Missed Opportunity') OVER game_window                                                         AS game_total_nb_missed_opportunity,
    MAX(score_playing) OVER game_window                                                                                           AS game_max_score_playing,
    CASE    
      WHEN MAX(score_playing) OVER game_window > {{ var('score_thresholds')['should_win_score'] }} THEN 'Decisive advantage'    
      ELSE 'No decisive advantage' END                                                                                            AS game_decisive_advantage,
    MIN(score_playing) OVER game_window                                                                                           AS game_min_score_playing,
    STDDEV_SAMP(score_playing) OVER game_window                                                                                   AS game_std_score_playing,
    MAX(move_number) OVER game_window                                                                                             AS game_total_move_number,
    FIRST_VALUE (
      CASE WHEN COALESCE(miss_category_playing, miss_category_opponent) = 'Massive Blunder' THEN playing_turn_name ELSE NULL END IGNORE NULLS)
      OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)   AS game_playing_turn_name_first_blunder,
  FROM context_definition
  WINDOW game_window AS (PARTITION BY game_uuid, username)
)

SELECT * FROM game_level_calculation
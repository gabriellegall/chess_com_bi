{{ config(materialized='view') }}

WITH games_scope AS (
  SELECT
    *
  FROM {{ ref ('games') }}
  WHERE TRUE
    AND end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL {{ var('data_scope')['month_history_depth'] }} MONTH, MONTH)
    AND rated
)

, score_defintion AS (
  SELECT 
    games.game_uuid,
    games.archive_url,
    COALESCE(username_mapping.target_username, games.username) AS username, -- Use the target username from the mapping table if it exists
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
      WHEN move_number <= {{ var('game_phases')['early']['end_game_move'] }} THEN {{ var('game_phases')['early']['name'] }}
      WHEN move_number <= {{ var('game_phases')['mid']['end_game_move'] }} THEN {{ var('game_phases')['mid']['name'] }}
      WHEN move_number <= {{ var('game_phases')['late']['end_game_move'] }} THEN {{ var('game_phases')['late']['name'] }}
      ELSE {{ var('game_phases')['very_late']['name'] }} END AS game_phase,
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
  LEFT OUTER JOIN {{ ref ('username_mapping') }} username_mapping
    ON LOWER(username_mapping.username) = LOWER(games.username) 
)

, previous_score AS (
  SELECT 
    *,
    LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)                      AS prev_score_playing,
    score_playing - LAG(score_playing) OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC)      AS variance_score_playing,
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
  FROM prev_position_definition
)

SELECT 
  *,
  MAX(move_number) OVER (PARTITION BY game_uuid, username) AS total_nb_moves,
  FIRST_VALUE (
    CASE WHEN COALESCE(miss_category_playing, miss_category_opponent) = 'Massive Blunder' THEN playing_turn_name ELSE NULL END IGNORE NULLS)
    OVER (PARTITION BY game_uuid, username ORDER BY move_number ASC ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_blunder_playing_turn_name, 
FROM context_definition
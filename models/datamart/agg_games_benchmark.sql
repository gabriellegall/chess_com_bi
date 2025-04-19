{{ config(
    enabled=True,
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH username_info AS (
  SELECT 
    username,
    time_class,
    playing_rating_range,
    game_phase_key,
    aggregation_level,
    COUNTIF(nb_blunder_playing > 0) / COUNT(*)                                    AS rate_nb_blunder_playing,
    COUNTIF(nb_massive_blunder_playing > 0) / COUNT(*)                            AS rate_nb_massive_blunder_playing,
    COUNTIF(first_massive_blunder_playing_prct_time_remaining > 0.5) / COUNT(*)   AS rate_nb_massive_blunder_playing_prct_time_50,
    COUNTIF(first_massive_blunder_playing_prct_time_remaining > 0.7) / COUNT(*)   AS rate_nb_massive_blunder_playing_prct_time_70,
    COUNTIF(first_massive_blunder_playing_prct_time_remaining > 0.9) / COUNT(*)   AS rate_nb_massive_blunder_playing_prct_time_90,
    COUNTIF(nb_throw_playing > 0) / COUNT(*)                                      AS rate_nb_throw_playing,
    COUNTIF(nb_missed_opportunity_playing > 0) / COUNT(*)                         AS rate_nb_missed_opportunity_playing,
    AVG(median_score_playing)                                                     AS avg_score_playing,
    COUNT(*)                                                                      AS nb_games,
  FROM {{ ref ('agg_games_with_moves') }}
  WHERE TRUE
    AND playing_rating_range = opponent_rating_range -- ensure that the level of both players is relevant
    AND end_time_date >= DATE_TRUNC(CURRENT_DATE - INTERVAL 1 MONTH, MONTH)
  GROUP BY ALL
  HAVING COUNT(*) > {{ var('datamart')['min_games_played'] }} -- ensure that enough observations are captured
)

SELECT 
  u.username,
  u.game_phase_key,
  u.time_class,
  u.playing_rating_range,
  u.aggregation_level,
  -- Playing metrics
  ANY_VALUE(u.rate_nb_blunder_playing)                                            AS rate_nb_blunder_playing,
  ANY_VALUE(u.rate_nb_massive_blunder_playing)                                    AS rate_nb_massive_blunder_playing,
  ANY_VALUE(u.rate_nb_massive_blunder_playing_prct_time_50)                       AS rate_nb_massive_blunder_playing_prct_time_50,
  ANY_VALUE(u.rate_nb_massive_blunder_playing_prct_time_70)                       AS rate_nb_massive_blunder_playing_prct_time_70,
  ANY_VALUE(u.rate_nb_massive_blunder_playing_prct_time_90)                       AS rate_nb_massive_blunder_playing_prct_time_90,
  ANY_VALUE(u.rate_nb_throw_playing)                                              AS rate_nb_throw_playing,
  ANY_VALUE(u.rate_nb_missed_opportunity_playing)                                 AS rate_nb_missed_opportunity_playing,
  ANY_VALUE(u.nb_games)                                                           AS nb_games,
  -- Other players metrics (benchmark)                      
  COUNTIF(gp.nb_blunder_playing > 0) / COUNT(*)                                   AS bench_rate_nb_blunder_playing,
  COUNTIF(gp.nb_massive_blunder_playing > 0) / COUNT(*)                           AS bench_rate_nb_massive_blunder_playing,
  COUNTIF(gp.first_massive_blunder_playing_prct_time_remaining > 0.5) / COUNT(*)  AS bench_rate_nb_massive_blunder_playing_prct_time_50,
  COUNTIF(gp.first_massive_blunder_playing_prct_time_remaining > 0.7) / COUNT(*)  AS bench_rate_nb_massive_blunder_playing_prct_time_70,
  COUNTIF(gp.first_massive_blunder_playing_prct_time_remaining > 0.9) / COUNT(*)  AS bench_rate_nb_massive_blunder_playing_prct_time_90,
  COUNTIF(gp.nb_throw_playing > 0) / COUNT(*)                                     AS bench_rate_nb_throw_playing,
  COUNTIF(gp.nb_missed_opportunity_playing > 0) / COUNT(*)                        AS bench_rate_nb_missed_opportunity_playing,
  COUNT(*)                                                                        AS bench_nb_games,
FROM username_info u
LEFT OUTER JOIN {{ ref ('agg_games_with_moves') }} gp 
  ON gp.username <> u.username
  AND gp.game_phase_key = u.game_phase_key
  AND gp.time_class = u.time_class
  AND gp.playing_rating_range = u.playing_rating_range
WHERE gp.playing_rating_range = gp.opponent_rating_range -- ensure that the level of both players is relevant
GROUP BY ALL
HAVING COUNT(*) > {{ var('datamart')['min_games_played'] }} -- ensure that enough observations are captured
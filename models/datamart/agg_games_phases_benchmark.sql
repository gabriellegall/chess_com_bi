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
    COUNTIF(nb_blunder_playing > 0) / COUNT(*)              AS rate_nb_blunder_playing,
    COUNTIF(nb_massive_blunder_playing > 0) / COUNT(*)      AS rate_nb_massive_blunder_playing,
    COUNTIF(nb_throw_playing > 0) / COUNT(*)                AS rate_nb_throw_playing,
    COUNTIF(nb_missed_opportunity_playing > 0) / COUNT(*)   AS rate_nb_missed_opportunity_playing,
    AVG(median_score_playing)                               AS avg_score_playing,
    COUNT(*)                                                AS nb_games,
  FROM {{ ref ('agg_games_phases') }}
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
  ANY_VALUE(u.rate_nb_blunder_playing)                      AS rate_nb_blunder_playing,
  ANY_VALUE(u.rate_nb_massive_blunder_playing)              AS rate_nb_massive_blunder_playing,
  ANY_VALUE(u.rate_nb_throw_playing)                        AS rate_nb_throw_playing,
  ANY_VALUE(u.rate_nb_missed_opportunity_playing)           AS rate_nb_missed_opportunity_playing,
  ANY_VALUE(u.avg_score_playing)                            AS avg_score_playing,
  ANY_VALUE(u.nb_games)                                     AS nb_games,
  -- Other players metrics (benchmark)
  COUNTIF(gp.nb_blunder_playing > 0) / COUNT(*)             AS bench_rate_nb_blunder_playing,
  COUNTIF(gp.nb_massive_blunder_playing > 0) / COUNT(*)     AS bench_rate_nb_massive_blunder_playing,
  COUNTIF(gp.nb_throw_playing > 0) / COUNT(*)               AS bench_rate_nb_throw_playing,
  COUNTIF(gp.nb_missed_opportunity_playing > 0) / COUNT(*)  AS bench_rate_nb_missed_opportunity_playing,
  AVG(gp.median_score_playing)                              AS bench_avg_score_playing,
  COUNT(*)                                                  AS bench_nb_games,
FROM username_info u
LEFT OUTER JOIN {{ ref ('agg_games_phases') }} gp 
  ON gp.username <> u.username
  AND gp.game_phase_key = u.game_phase_key
  AND gp.time_class = u.time_class
  AND gp.playing_rating_range = u.playing_rating_range
WHERE gp.playing_rating_range = gp.opponent_rating_range -- ensure that the level of both players is relevant
GROUP BY ALL
HAVING COUNT(*) > {{ var('datamart')['min_games_played'] }} -- ensure that enough observations are captured
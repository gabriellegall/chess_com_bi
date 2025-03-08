{{ config(
    materialized='table',
    pre_hook="DROP TABLE IF EXISTS {{ this }}"
) }}

WITH username_info AS (
  SELECT 
    username,
    game_phase,
    time_class,
    playing_rating_range,
    AVG(nb_blunder_playing)              AS avg_nb_blunder_playing,
    AVG(nb_massive_blunder_playing)      AS avg_nb_massive_blunder_playing,
    AVG(nb_throw_playing)                AS avg_nb_throw_playing,
    AVG(nb_missed_opportunity_playing)   AS avg_nb_missed_opportunity_playing,
    AVG(median_score_playing)            AS avg_score_playing,
    COUNT(*)                             AS nb_games,
  FROM {{ ref ('agg_games_phases') }}
  WHERE playing_rating_range = opponent_rating_range
    AND end_time_date >= CURRENT_DATE - INTERVAL 3 MONTH
  GROUP BY ALL
  HAVING COUNT(*) > 20
)

SELECT 
  u.username,
  u.game_phase,
  u.time_class,
  u.playing_rating_range,
  ANY_VALUE(u.avg_nb_blunder_playing)             AS avg_nb_blunder_playing,
  ANY_VALUE(u.avg_nb_massive_blunder_playing)     AS avg_nb_massive_blunder_playing,
  ANY_VALUE(u.avg_nb_throw_playing)               AS avg_nb_throw_playing,
  ANY_VALUE(u.avg_nb_missed_opportunity_playing)  AS avg_nb_missed_opportunity_playing,
  ANY_VALUE(u.avg_score_playing)                  AS avg_score_playing,
  ANY_VALUE(u.nb_games)                           AS nb_games,
  AVG(gp.nb_blunder_playing)                      AS bench_avg_nb_blunder_playing,
  AVG(gp.nb_massive_blunder_playing)              AS bench_avg_nb_massive_blunder_playing,
  AVG(gp.nb_throw_playing)                        AS bench_avg_nb_throw_playing,
  AVG(gp.nb_missed_opportunity_playing)           AS bench_avg_nb_missed_opportunity_playing,
  AVG(gp.median_score_playing)                    AS bench_avg_score_playing,
  COUNT(*)                                        AS bench_nb_games,
FROM username_info u
LEFT OUTER JOIN {{ ref ('agg_games_phases') }} gp 
  ON gp.username <> u.username
  AND gp.game_phase = u.game_phase
  AND gp.time_class = u.time_class
  AND gp.playing_rating_range = u.playing_rating_range
WHERE gp.playing_rating_range = gp.opponent_rating_range
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) > 30
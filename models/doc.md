# Games

{% docs archive_url %}
Partition queried via the API to fetch the games. Contains the month and the username.
{% enddocs %}

{% docs username %}
Username of the player queried via the API to fetch the games.
{% enddocs %}

{% docs bq_load_date %}
Date when the game was loaded into BigQuery.
{% enddocs %}

{% docs url %}
Direct URL to the game in chess.com.
{% enddocs %}

{% docs pgn %}
PGN (Portable Game Notation) of the game. Contains all the moves in a raw format.
{% enddocs %}

{% docs time_control %}
PGN-compliant time control of the game (e.g. 300+5, 180+2, etc.).
{% enddocs %}

{% docs end_time_integer %}
End time of the game in integer (raw) format. The time is expressed in Unix timestamp, which represents the number of seconds since January 1, 1970 (the Unix epoch).
{% enddocs %}

{% docs end_time %}
End time of the game.
{% enddocs %}

{% docs rated %}
Boolean flag indicating whether the game was rated.
{% enddocs %}

{% docs tcn %}
TCN encoding of the game.
{% enddocs %}

{% docs game_uuid %}
Unique identifier for the game.
{% enddocs %}

{% docs initial_setup %}
Initial setup of the chessboard.
{% enddocs %}

{% docs fen %}
FEN (Forsyth-Edwards Notation) string of the game.
{% enddocs %}

{% docs time_class %}
Time class of the game (e.g., bullet, blitz, rapid).
{% enddocs %}

{% docs rules %}
Game variant information (e.g. chess960).
{% enddocs %}

{% docs white_username %}
Username of the white player.
{% enddocs %}

{% docs white_rating %}
ELO rating of the white player after the game has finished.
{% enddocs %}

{% docs white_result %}
Result from the perspective of the white player.
{% enddocs %}

{% docs white_id %}
URL of the white player's profile.
{% enddocs %}

{% docs white_uuid %}
UUID for the white player.
{% enddocs %}

{% docs black_username %}
Username of the black player.
{% enddocs %}

{% docs black_rating %}
ELO rating of the black player after the game has finished.
{% enddocs %}

{% docs black_result %}
Result from the perspective of the black player.
{% enddocs %}

{% docs black_id %}
URL of the black player's profile.
{% enddocs %}

{% docs black_uuid %}
UUID for the black player.
{% enddocs %}

# Games moves

{% docs move_number %}
Sequential move number starting from 1.
{% enddocs %}

{% docs move %}
Move played.
{% enddocs %}

{% docs score_white %}
Stockfish evaluation (in centipawns) of the position (after the move has been played), from the perspective of white. When >0 white has an advantage, when <0 black has an advantage.
{% enddocs %}

# Processed - Games

{% docs end_time_date %}
End time field casted as DATE.
{% enddocs %}

{% docs end_time_month %}
End time field casted as STRING YYYY-MM.
{% enddocs %}

{% docs playing_as %}
Color that the username is playing in the game.
{% enddocs %}

{% docs playing_result_detailed %}
Game result field, from the perspective of the username playing.
{% enddocs %}

{% docs playing_rating %}
ELO rating of the username playing.
{% enddocs %}

{% docs opponent_rating %}
ELO rating of the opponent of username.
{% enddocs %}

{% docs playing_result %}
Simplified result of the game, from the perspective of the username playing.
{% enddocs %}

# Processed - Games moves

{% docs player_color_turn %}
Color of the player who played the move, derived from the move number : white's turn on odd numbers, black's turn on even numbers.
{% enddocs %}

{% docs score_black %}
Score of the black player calculated by Stockfish, derived as the opposite of white's score.
{% enddocs %}

{% docs win_probability_white %}
Translation of the white score into a win probability, derived using the sigmoid function, converts the Stockfish evaluation into a probability between 0 and 1.
{% enddocs %}

{% docs win_probability_black %}
Translation of the black score into a win probability, derived using the sigmoid function, converts the Stockfish evaluation into a probability between 0 and 1.
{% enddocs %}

# Games with moves

{% docs game_phase %}
Game phase determined by the move number.
{% enddocs %}

{% docs is_playing_turn %}
Indicates if it is the username's turn (`player_color_turn = playing_as`).
{% enddocs %}

{% docs playing_turn_name %}
Describes the player's turn: 'Opponent' if the opponent has played, 'Playing' if username has played.
{% enddocs %}

{% docs playing_rating_range %}
ELO range based on the username's rating.
{% enddocs %}

{% docs opponent_rating_range %}
ELO range based on the opponent's rating.
{% enddocs %}

{% docs score_playing %}
Score defined from the perspective of username. This normalized field is used in all subsequent calculations whenever the notion of score is used. 
{% enddocs %}

{% docs win_probability_playing %}
Win probability defined from the perspective of username. 
{% enddocs %}

{% docs prev_score_playing %}
Score in the previous turn.
{% enddocs %}

{% docs variance_score_playing %}
Variance in the score between the previous and the current turn.
{% enddocs %}

{% docs miss_category_playing %}
If the move is an inaccuracy (from the perspective of username), classification of the type of miss is as follows : 'Mistake' < 'Blunder' < 'Massive Blunder'
{% enddocs %}

{% docs miss_move_number_playing %}
Move number associated with any of the username's inaccuracy.
{% enddocs %}

{% docs massive_blunder_move_number_playing %}
Move number associated with any of the username's massive blunder.
{% enddocs %}

{% docs miss_category_opponent %}
If the move is an inaccuracy (from the perspective of the opponent), classification of the type of miss is as follows : 'Mistake' < 'Blunder' < 'Massive Blunder'
{% enddocs %}

{% docs miss_move_number_opponent %}
Move number associated with the opponent's inaccuracy.
{% enddocs %}

{% docs position_status_playing %}
Description of the current score advantage/disadvantage, from the perspective of the username.
{% enddocs %}

{% docs prev_position_status_playing %}
Position status on the previous turn, from the perspective of the username.
{% enddocs %}

{% docs miss_context_playing %}
Defines if the blunder or massive blunder (from the username's perspective) is made in the context of a 'Throw' or a 'Missed Opportunity'.
A 'Throw' occurs when the previous situation was even or already disadvantageous (for the player username).
A 'Missed Opportunity' occurs when the previous situation was advantageous (for the player username).
{% enddocs %}

{% docs total_nb_moves %}
Total number of moves played in the game.
{% enddocs %}

{% docs first_blunder_playing_turn_name %}
Definition of who ('Opponent' vs 'Playing') made the first massive blunder - at the game_uuid level.
{% enddocs %}

# Agg games with moves

{% docs max_score_playing_type %}
Simplification of the maximum game score, aiming to define if the username was in a decisive winning position (at any point).
{% enddocs %}

{% docs aggregation_level %}
Aggregation level at which the metrics are defined. Several different and independent aggregation levels are mixed within the table.
{% enddocs %}

{% docs game_phase_key %}
`game_phase` if applicable for the given aggregation level, otherwise returns a generic values describing the aggregation.
{% enddocs %}

{% docs nb_blunder_playing %}
Number of blunders detected in the game, technically it is a count of 'Blunder' OR 'Massive Blunder' on the field `miss_category_playing`
{% enddocs %}

{% docs nb_massive_blunder_playing %}
Number of massive blunders detected in the game, technically it is a count of 'Massive Blunder' on the field `miss_category_playing`
{% enddocs %}

{% docs nb_throw_playing %}
Number of throws detected in the game, technically it is a count of 'Throw' on the field `miss_context_playing`
{% enddocs %}

{% docs nb_missed_opportunity_playing %}
Number of throws detected in the game, technically it is a count of 'Missed Opportunity' on the field `miss_context_playing`
{% enddocs %}

{% docs median_score_playing %}
Median evaluation score of the username’s position throughout the game.
{% enddocs %}

{% docs max_score_playing %}
Maximum evaluation score reached by username during the game.
{% enddocs %}

{% docs min_score_playing %}
Minimum evaluation score reached by username during the game.
{% enddocs %}

{% docs std_score_playing %}
Standard deviation of the evaluation scores, indicating the volatility of the game.
{% enddocs %}

{% docs max_score_playing_range %}
Categorical range representation of the maximum evaluation score.
{% enddocs %}

{% docs has_enough_games %}
Boolean indicating whether username has played a sufficient number of games for statistical relevance. This field is used as a filter on reports/dashboards.
{% enddocs %}
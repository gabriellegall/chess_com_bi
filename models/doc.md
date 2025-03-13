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
End time of the game in integer (raw) format.
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
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

# Game moves

{% docs move_number %}
Sequential move number starting from 1.
{% enddocs %}

{% docs moves %}
Move played.
{% enddocs %}

{% docs scores_white %}
Stockfish evaluation of the position (after the move has been played), from the perspective of white. When >0 white has an advantage, when <0 black has an advantage.
{% enddocs %}
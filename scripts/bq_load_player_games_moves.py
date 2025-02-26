import os
import pandas as pd
from pandas_gbq import read_gbq, to_gbq
from google.cloud import bigquery
import chess.pgn
import chess.engine
import io
import asyncio
from datetime import datetime

# Set up BigQuery client
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../keyfile.json"
client = bigquery.Client()

# Define the BigQuery dataset and table names
dataset_id = 'chesscom-451104.staging'
table_games = f'{dataset_id}.games_infos_*'
table_games_prefix = 'games_moves_'  # Prefix for wildcard tables

print("step 1")

# Check if at least one table with the prefix "games_moves_" exists
def table_with_prefix_exists(client, dataset_id, prefix):
    tables = client.list_tables(dataset_id)  # List all tables in the dataset
    return any(table.table_id.startswith(prefix) for table in tables)

# Check if games_moves_* tables exist
if table_with_prefix_exists(client, dataset_id, table_games_prefix):
    # Define SQL query to get games not yet processed using wildcard tables
    query = f"""
    SELECT *
    FROM `{table_games}` game
    LEFT OUTER JOIN (SELECT DISTINCT game_uuid FROM `{dataset_id}.games_moves_*`) games_moves
    USING (game_uuid)
    WHERE games_moves.game_uuid IS NULL
    """
else:
    # If no games_moves_* table exists, select all games
    query = f"SELECT * FROM `{table_games}`"

print("step 2")

# Run the query and load the result into a DataFrame
games = read_gbq(query, project_id='chesscom-451104', dialect='standard')

print("Query executed successfully!")

# Set the path to Stockfish
engine_path = "/usr/games/stockfish"

# if __name__ == "__main__" and hasattr(asyncio, 'WindowsProactorEventLoopPolicy'):
#     asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

def analyze_chess_game(game_uuid: str, pgn: str, engine_path: str):
    # Load the PGN
    game = chess.pgn.read_game(io.StringIO(pgn))

    # Initialize lists to hold data
    move_numbers = []
    moves = []
    scores_white = []

    # Analyze the game
    with chess.engine.SimpleEngine.popen_uci(engine_path) as engine:
        board = game.board()

        for i, move in enumerate(game.mainline_moves(), 1):
            board.push(move)
            info = engine.analyse(board, chess.engine.Limit(time=0.1))
            score_white = info["score"].white().score(mate_score=1000)

            # Append data to lists
            move_numbers.append(i)
            moves.append(move.uci())
            scores_white.append(score_white)

    # Create a DataFrame
    df = pd.DataFrame({
        "game_uuid": [game_uuid] * len(move_numbers),
        "move_number": move_numbers,
        "move": moves,
        "score_white": scores_white
    })

    return df

def analyze_multiple_games(games: pd.DataFrame, engine_path: str):
    # Initialize an empty list to store individual game dataframes
    game_dfs = []

    # Track the number of processed games
    processed_games = 0

    # Iterate over each game in the dataframe
    for _, row in games.iterrows():
        game_uuid = row['game_uuid']
        pgn = row['pgn']

        # Analyze the game and append the result to the list
        game_df = analyze_chess_game(game_uuid, pgn, engine_path)
        game_dfs.append(game_df)

        # Increment and print the number of processed games
        processed_games += 1
        print(f"Processed {processed_games} games")

    # Concatenate all dataframes into one
    return pd.concat(game_dfs, ignore_index=True)

print("step 3")

# Call the function with the games DataFrame and get the result
games_moves = analyze_multiple_games(games, engine_path)

# Set up BigQuery client
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../keyfile.json"
client = bigquery.Client()

# Define the BigQuery dataset
dataset_id = 'chesscom-451104.staging'

print("step 4")

# Generate the table name with current date, hour, and minute
date_suffix = datetime.now().strftime('%Y%m%d_%H%M')
table_id = f'{dataset_id}.games_moves_{date_suffix}'

# Load the DataFrame into BigQuery
to_gbq(games_moves, table_id, project_id='chesscom-451104', if_exists='replace')

if not games_moves.empty:
    # Load the DataFrame into BigQuery using pandas_gbq
    to_gbq(games_moves, table_id, project_id='chesscom-451104', if_exists='replace') # DROP & CREATE data load (full)
    print(f"Data loaded into BigQuery table: {table_id}")
else:
    print("The games DataFrame is empty. No data loaded into BigQuery.")

print("step 5")

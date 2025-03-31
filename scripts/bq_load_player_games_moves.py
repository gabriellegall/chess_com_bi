import os
import pandas as pd
from pandas_gbq import read_gbq, to_gbq
from google.cloud import bigquery
import chess.pgn
import chess.engine
import io
import asyncio
import yaml
from datetime import datetime
import platform

def table_with_prefix_exists(client: bigquery.Client, dataset_id: str, prefix: str) -> bool:
    tables = client.list_tables(dataset_id)  # List all tables in the dataset
    return any(table.table_id.startswith(prefix) for table in tables)

def analyze_chess_game(game_uuid: str, pgn: str, engine_path: str) -> pd.DataFrame:
    # Load the PGN
    game = chess.pgn.read_game(io.StringIO(pgn))

    if game is None:
        print(f"Warning: Failed to parse PGN for game {game_uuid}")
        return pd.DataFrame(columns=["game_uuid", "move_number", "move", "score_white"])

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

def analyze_multiple_games(games: pd.DataFrame, engine_path: str) -> pd.DataFrame:
    game_dfs = []
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
        print(f"Processed {processed_games} games", flush=True)

    # Concatenate all dataframes into one
    return pd.concat(game_dfs, ignore_index=True)

def get_stockfish_path():
    if platform.system() == "Windows":
        if hasattr(asyncio, 'WindowsProactorEventLoopPolicy'):
            asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
        return "C:/Program Files/ChessEngines/stockfish_16/stockfish-windows-x86-64-avx2.exe"
    return "/usr/games/stockfish"

# Open the config file if it exists
config_path = os.path.join(os.getcwd(), "scripts", "config.yml")
with open(config_path, "r") as file:
    config = yaml.safe_load(file)

# Set up BigQuery client
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "./keyfile.json"
client = bigquery.Client()

# Define the BigQuery dataset and table prefix
project_id                  = config["bigquery"]["config"]["project_id"]
dataset_id                  = config["bigquery"]["config"]["dataset_id"]
table_games_prefix          = config["bigquery"]["tables"]["games_prefix"]
table_games_moves_prefix    = config["bigquery"]["tables"]["games_moves_prefix"]

# Define the BigQuery dataset and table names
table_games         = f'{dataset_id}.{table_games_prefix}*'
tables_games_moves  = f'{dataset_id}.{table_games_moves_prefix}*'

if table_with_prefix_exists(client, dataset_id, table_games_moves_prefix):
    # Define SQL query to get unique games not yet processed
    # Remark: we use QUALIFY to remove duplicates when several [username] share the same [game_uuid] (playing against each other)
    query = f"""
    SELECT *
    FROM `{table_games}` game
    LEFT OUTER JOIN (SELECT DISTINCT game_uuid FROM `{tables_games_moves}`) games_moves
    USING (game_uuid)
    WHERE 
        games_moves.game_uuid IS NULL
        AND LENGTH(game.pgn) > 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY game_uuid) = 1
    """
else:
    # If no games_moves_* table exists, select all games
    query = f"SELECT * FROM `{table_games}`"

# Run the query and load the result into a DataFrame
games = read_gbq(query, project_id='chesscom-451104', dialect='standard')
print("Query to fetch games executed successfully!")

# Calculate all games moves for all games
engine_path = get_stockfish_path()
games_moves = analyze_multiple_games(games, engine_path)

# Generate the table name with current date, hour, and minute
date_suffix = datetime.now().strftime('%Y%m%d_%H%M')
table_id = f'{dataset_id}.{table_games_moves_prefix}{date_suffix}'

if not games_moves.empty:
    to_gbq(games_moves, table_id, project_id='chesscom-451104', if_exists='replace')
    print(f"Data loaded into BigQuery table: {table_id}")
else:
    print("The games DataFrame is empty. No data loaded into BigQuery.")

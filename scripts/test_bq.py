import os
import yaml
import pandas as pd
from pandas_gbq import read_gbq, to_gbq
from google.cloud import bigquery
import requests
from datetime import datetime
import platform

# Set up BigQuery client
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../keyfile.json"
client = bigquery.Client()

# Define the BigQuery dataset and table prefix
dataset_id = 'chesscom-451104.staging'
table_games_prefix = 'games_infos_'

# Check if at least one table with the prefix exists
def table_with_prefix_exists(client, dataset_id, prefix):
    tables = client.list_tables(dataset_id) # List all tables in the dataset
    return any(table.table_id.startswith(prefix) for table in tables)

# If at least one table exists, check when the latest integrated occured for each username
if table_with_prefix_exists(client, dataset_id, table_games_prefix):
    query = f"""
    SELECT
        username,
        MAX(archive_url) AS latest_url,
        MAX(end_time_integer) AS latest_end_time
    FROM `{dataset_id}.{table_games_prefix}*`
    GROUP BY 1
    """
    username_import = read_gbq(query, project_id='chesscom-451104', dialect='standard')
    print("Query executed successfully!")
# If no table exists, return an empty dataframe
else:
    print(f"No tables with the prefix '{table_games_prefix}' found.")
    username_import = pd.DataFrame()

def get_player_archive_and_filter(username, email):
    headers = {'User-Agent': f'username: {username}, email: {email}'}
    URL = f'https://api.chess.com/pub/player/{username}/games/archives'

    response = requests.get(URL, headers=headers)
    archives = response.json()

    # If the DataFrame is empty (no data in BQ), return the full archive (all URLs)
    if username_import.empty:
        print(f"No user history for '{username}'")
        return archives

    # If a username is found, return URL archives >= the latest archive integrated
    # If no username history is found, return the full archive (all URLs)
    user_row = username_import[username_import['username'] == username]
    if not user_row.empty:
        latest_url = user_row.iloc[0]['latest_url']
    else:
        latest_url = ""

    filtered_archives = [
        archive_url for archive_url in archives.get("archives", [])
        if latest_url == "" or archive_url >= latest_url
    ]

    archives['archives'] = filtered_archives

    return archives

def fetch_and_union_game_data(usernames, email):
    all_game_data = []
    current_timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    for username in usernames:
        # Get the archives URL(s) to be queried via the API
        archives = get_player_archive_and_filter(username, email)

        # Define the player's latest_end_time (the latest game integrated in BQ)
        if username_import.empty:
            latest_end_time = 0
        else:
            user_row = username_import[username_import['username'] == username]
            if not user_row.empty:
                latest_end_time = user_row.iloc[0]['latest_end_time']
            else:
                latest_end_time = 0

        # Loop through each archive URL
        for archive_url in archives.get("archives", []):
            response = requests.get(archive_url, headers={'User-Agent': f'username: {username}, email: {email}'})
            archive_data = response.json()

            game_data = [
                {
                    # Fields relative to audit information
                    "archive_url": archive_url,
                    "username": username,
                    "bq_load_date": current_timestamp,
                    # Fields relative to general game information
                    "url": game.get("url", ""),
                    "pgn": game.get("pgn", ""),
                    "time_control": game.get("time_control", ""),
                    "end_time_integer" : game.get("end_time", 0),
                    "end_time": datetime.fromtimestamp(game.get("end_time", 0)).strftime("%Y-%m-%d %H:%M:%S"),
                    "rated": game.get("rated", False),
                    "tcn": game.get("tcn", ""),
                    "game_uuid": game.get("uuid", ""),
                    "initial_setup": game.get("initial_setup", ""),
                    "fen": game.get("fen", ""),
                    "time_class": game.get("time_class", ""),
                    "rules": game.get("rules", ""),
                    # Fields relative to 'white' subfields
                    "white_username": game.get("white", {}).get("username", ""),
                    "white_rating": game.get("white", {}).get("rating", ""),
                    "white_result": game.get("white", {}).get("result", ""),
                    "white_id": game.get("white", {}).get("@id", ""),
                    "white_uuid": game.get("white", {}).get("uuid", ""),
                    # Fields relative to 'black' subfields
                    "black_username": game.get("black", {}).get("username", ""),
                    "black_rating": game.get("black", {}).get("rating", ""),
                    "black_result": game.get("black", {}).get("result", ""),
                    "black_id": game.get("black", {}).get("@id", ""),
                    "black_uuid": game.get("black", {}).get("uuid", ""),
                }
                for game in archive_data.get("games", [])
                # Keep only games > latest_end_time. Games which do not respect this condition are expected to be already loaded
                if game.get("end_time", 0) > latest_end_time
            ]
            # Append the results
            all_game_data.extend(game_data)

    df = pd.DataFrame(all_game_data)

    return df

# Construct the path to config.yml located under 'scripts' folder
config_path = os.path.join(os.getcwd(), "scripts", "config.yml")

# Open the config file if it exists
with open(config_path, "r") as file:
    config = yaml.safe_load(file)

usernames = config["api"]["usernames"]
email = config["api"]["email"]

games = fetch_and_union_game_data(usernames, email)

# Set up BigQuery client
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../keyfile.json"
client = bigquery.Client()

# Define the BigQuery dataset and table name
dataset_id = 'chesscom-451104.staging'

# Generate the table name with current date, hour, and minute
date_suffix = datetime.now().strftime('%Y%m%d_%H%M')
table_id = f'{dataset_id}.games_infos_{date_suffix}'

if not games.empty:
    # Load the DataFrame into BigQuery using pandas_gbq
    to_gbq(games, table_id, project_id='chesscom-451104', if_exists='replace')
    print(f"Data loaded into BigQuery table: {table_id}")
else:
    print("The games DataFrame is empty. No data loaded into BigQuery.")

print(platform.system())

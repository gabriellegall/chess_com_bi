import os
import pandas as pd
from pandas_gbq import read_gbq
from google.cloud import bigquery

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
    print(username_import.head(10))
# If no table exists, return an empty dataframe
else:
    print(f"No tables with the prefix '{table_games_prefix}' found.")
    username_import = pd.DataFrame()

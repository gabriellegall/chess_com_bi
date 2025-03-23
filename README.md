# Purpose

## Overview
This project is an end-to-end data solution aiming to extract informtion from chess.com and construct insightfull analysis on the player's performance.
The key questions answered are:
- "Do I manage to beat stronger players and improve ?"
- "Am I weaker at specific game phases on average ?"
- "Do I manage to reduce the frequency at which I make blunders in my games ?"
- "Do I make more or less blunders compared to other similar players ? Is it true for all game phases ?"
- "What are the games I should review to address the most important issues I have ?"

## Repository
This repository contains all the scripts aiming to: 
1. Extract the games played data from the chess.com API and load it in BigQuery.
2. Extract the individual moves for each game played, evaluate the position using the Stockfish engine, and load it in BigQuery.
3. Construct a data model using DBT to define metrics and dimensions (blunders, game phases, ELO ranges, etc.).

# Tooling
## Stack
- Extract & Load: Python
- Data storage & compute: BigQuery (free tier)
- Data transformation: DBT
- Data visualization: Metabase (via Docker on a VPS)
- Orchestration: GitHub Workflows (using GitHub Runners)
- Documentation: DBT Docs (on a GitHub Page)

## Requirements
- Python, with the required libraries installed
- A BigQuery project, with a `keyfile.json` containing the credentials
- Docker Desktop
- /i\ The Stockfish engine (for local execution of the script `bq_load_player_games_moves.py`)

## Commands
- Load the chess.com data into BigQuery:
- Run the Stockfish engine and load results in BigQuery:
- Run all DBT models: `dbt run`
- Run all DBT tests: `dbt test`
- Generate and view the documentation: `dbt docs generate; dbt docs serve`
/i\ Here, integrate the commands we can used inside the container

# Project

## Data extraction
The script `bq_load_player_games.py` gets the data from the chess.com API and loads it in BigQuery.
It uses the `config.yml` to define usernames and history depth to be queried, as well as BigQuery project information with table names to be used.

### Unit testing
Following changes in the integration, unit test scenarios have been defined using pytest.
More unit tests could be developped to avoid regressions and side effects.
Those tests could be executed on the CI or on ad-hoc basis when modifying the query.

### Incremental strategy
The chess.com games information are partitioned by username and month on the API requests. 
Therefore, the script has been designed to query only the partitions that are greater than or equal to the latest partitions integrated in BigQuery for each username.
Then, a second filter is applied to load only games played after the latest end_time integrated in BigQuery. This ensures that only newer games played are integrated.
Since the free tier of BigQuery does not allow for DML operations (like INSERT), I use a CREATE table statement for each data integration execution. Each incremental table has a suffix corresponding to the execution date.

## Stockfish evaluation
The script `bq_load_player_games_moves.py` reads the integrated chess.com data and parses the `[pgn]` field to extract the individual game moves and evaluate a score using the Stockfish engine.
It uses the `config.yml` to define the BigQuery project information with table names to be used.

### Incremental strategy 
Only games not yet processed are processed by the Stockfish engine. To identify those games, a query is executed in BigQuery, comparing the games loaded with the games loaded for which game moves have been already evaluated.
Since the free tier of BigQuery does not allow for DML operations (like INSERT), I use a CREATE table statement for each data integration execution. Each incremental table has a suffix corresponding to the execution date.

## DBT

#### Layers
The datawarehouse is structured through several layers in order to ensure (1) performance (2) clarity and (3) modularity:
- **'staging'**: raw data extracted from chess.com and evaluated using the stockfish engine. This layer also contains a .csv DBT seed used as a hard coded mapping table for some users owning several accounts.
- **'intermediate'**: virtualized layer on top of the staging layer, aiming to cast data types and derive calculated fields. Tables in the intermediate layer share a 1:1 relationship with tables in the staging layer and preserve the same granularity (i.e. no join or aggregation/duplication is performed).
- **'reporting'**: core tables, ready to be used by data analysts. Those models merge intermediate tables together to derive business metrics & dimensions, based on rules and parameters. Those tables are exhaustive as they contain all the necessary information in one place (One-Big-Table approach).
- **'datamart'**: subset of the reporting layer, aiming to (1) optimize BigQuery data scans on limited volumes, tailored for reporting needs (2) version and document SQL business logics into the codebase. Since the datavisualization tool used is Metabase (SQL-based), it makes sense to create a dedicated and optimized layer. Technically, we could have leveraged Metabase "models" feature to create reusable business logics on top of the reporting layer, but this approach would have increased the data scans on each query. As of March 2025, Metabase does not support persistent models for BigQuery.

#### Materialization strategy
As explained earlier, it is not possible to perform DML operations under the BigQuery free tier (e.g. INSERT). Therefore, I use the 'table' or 'view' materialization with a DROP TABLE pre-hook if necessary. To avoid big write operations while optimizing Metabase query performance, I only materialize aggregated and filtered tables as 'table'. intermediate models or highly granular reporting tables are materialized as 'view'.

### Data quality and testing 
DBT tests have been developped to monitor data quality:
- generic DBT tests 'not_null' on key fields and business rules expecting to always be filled.
- a custom DBT test on the Stockfish games evaluation, to ensure that all games are processed as expected and all moves are evaluated.

### Documentation
All models are documented in DBT via yaml files. 
Since several models share the same fields, I use a markdown file `doc.md` to centralize new definitions and I call those definitions inside each yaml.
To ensure that there is a perfect match between the `doc.md` and the various yaml files, I create a script `test_doc.py` which can be executed to make a full gap analysis and raise warnings if any.
DBT documentation is hosted using GitHub Pages and updated on each merge with the main branch.

## Orchestration
GitHub Workflows are used as an orchestration tool. Those have two main benefits (1) simple integration with GitHub, the CI workflow, and the GitHub Secrets (2) free virtual machines (runners) to execute the scripts. Given the data volume processed in incremental mode, GitHub runners are perfectly sufficient.
Several workflows have been defined:
1. Full run (daily): `bq_load_player_games.yml` -> (if OK) `bq_load_player_games_moves.yml` -> (if OK) `dbt_run` 
2. Testing (weekly): `dbt_test`
3. Documentaton update (CI): `dbt_documentation`

# Outlooks

## Possible improvements

### Data analytics
- Integration of the remaining clock time on each move, to evaluate time management and the relationship with misplays.
- Extension of the benchmark model to integrate more metrics.

### Code
- the two Python scripts to fetch data from the API and evaluate moves using Stockfish could be improved with more modular functions, facilitating debugging and reading.
- those two scripts could be complemented with more unit tests, using Pytest.
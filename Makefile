# Docker executions:
docker_build_project:
	docker build -t chess-com-bi .

docker_run_games_load:
	docker run --rm chess-com-bi python3 scripts/bq_load_player_games.py

docker_run_games_moves_load:
	docker run --rm chess-com-bi python3 scripts/bq_load_player_games_moves.py

docker_run_dbt:
	docker run --rm chess-com-bi dbt run

# Metabase local development:
docker_launch_metabase:
	docker pull metabase/metabase
	docker run -d -p 3000:3000 --name metabase metabase/metabase

docker_backup_metabasedb:
	powershell -ExecutionPolicy Bypass -Command "if (Test-Path .\metabase.db) { Remove-Item -Path .\metabase.db -Recurse -Force }"
	docker stop metabase
	docker cp metabase:/metabase.db C:\Users\User\chess_com_bi\metabase.db
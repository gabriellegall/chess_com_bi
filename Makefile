docker_backup_metabase:
	powershell -ExecutionPolicy Bypass -Command "if (Test-Path .\metabase.db) { Remove-Item -Path .\metabase.db -Recurse -Force }"
	docker stop metabase
	docker cp metabase:/metabase.db C:\Users\User\chess_com_bi\metabase.db
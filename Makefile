docker_start:
	docker build -t chess_com_bi .
	docker run --name chess-com-container -it chess_com_bi /bin/bash

docker_end:
	docker stop chess-com-container
	docker rm chess-com-container
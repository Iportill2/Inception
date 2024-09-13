all:
	docker-compose -f srcs/docker-compose.yml  up -d --build
down:
	docker-compose -f srcs/docker-compose.yml  down
clean: down
	yes | docker system prune -a
.PHONY: all down clean
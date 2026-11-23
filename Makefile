NAME		= inception
LOGIN		= ludebarn
DATA_DIR	= /home/$(LOGIN)/data
BACKUP_DIR	= /home/$(LOGIN)/backup
COMPOSE		= docker compose -f srcs/docker-compose.yml -p $(NAME)

all: up

up:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress $(BACKUP_DIR)
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --rmi all

fclean:
	$(COMPOSE) down --rmi all -v
	sudo rm -rf $(DATA_DIR)

re: fclean all

.PHONY: all up down clean fclean re

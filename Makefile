
NAME = rabbitmq-cli-consumer

all: $(NAME)

$(NAME):
		docker-compose run consumer go build -tags netgo -o $(NAME)

clean:
		rm -rf $(NAME)

re: clean all

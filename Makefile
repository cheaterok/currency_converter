IMAGE_NAME=currency_converter
IMAGE_TAG=latest
TESTING_IMAGE_TAG=testing

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

build-testing:
	docker build --build-arg MIX_ENV=test -t $(IMAGE_NAME):$(TESTING_IMAGE_TAG) .

run: build
	IMAGE_TAG=$(IMAGE_TAG) docker-compose run --rm app iex -S mix do ecto.create, ecto.migrate, run

test: build-testing
	IMAGE_TAG=$(TESTING_IMAGE_TAG) docker-compose run --rm app mix test

teardown:
	IMAGE_TAG= docker-compose down

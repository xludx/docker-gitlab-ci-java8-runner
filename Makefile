all: build

build:
	@docker build --tag=ludx/gitlab-ci-java8-runner .

release: build
	@docker build --tag=ludx/gitlab-ci-java8-runner:$(shell cat VERSION) .

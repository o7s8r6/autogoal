.PHONY: build
build:
	docker build -t autogoal/autogoal:latest --build-arg BACKEND=cpu .
	docker build -t autogoal/autogoal:gpu --build-arg BACKEND=gpu .

# .PHONY: test-fast
# test-fast:
# 	PYTHON_VERSION=${BASE_VERSION} docker-compose run autogoal-tester-${ENVIRONMENT} make dev-test-fast

# .PHONY: notebook
# notebook:
# 	PYTHON_VERSION=${BASE_VERSION} docker-compose up

.PHONY: docs
docs:
	docker run --rm -it -u $(id -u):$(id -g) -v `pwd`:/code -v `pwd`/autogoal:/usr/local/lib/python3.6/site-packages/autogoal --network host autogoal/autogoal:latest bash -c "python /code/docs/make_docs.py && mkdocs build"
	(cd site && rm -rf .git && git init && git remote add origin git@github.com:autogoal/autogoal.github.io && git add . && git commit -a -m "Update docs" && git push -f origin master)

# .PHONY: docs-deploy
# docs-deploy:
# 	PYTHON_VERSION=${BASE_VERSION} docker-compose run autogoal-tester-${ENVIRONMENT} python /code/docs/make_docs.py && cp docs/index.md Readme.md && mkdocs gh-deploy

.PHONY: shell
shell:
	docker run --rm -it -u $(id -u):$(id -g) -v `pwd`:/code -v `pwd`/autogoal:/usr/local/lib/python3.6/site-packages/autogoal --network host autogoal/autogoal:latest bash

.PHONY: shell-gpu
shell-gpu:
	docker run --rm --gpus all -it -u $(id -u):$(id -g) -v `pwd`:/code -v `pwd`/autogoal:/usr/local/lib/python3.6/site-packages/autogoal --network host autogoal/autogoal:gpu bash

# Below are the commands that will be run INSIDE the development environment, i.e., inside Docker or Travis
# These commands are NOT supposed to be run by the developer directly, and will fail to do so.

.PHONY: dev-ensure
dev-ensure:
	# Check if you are inside a development environment
	echo ${BUILD_ENVIRONMENT} | grep "development" >> /dev/null

.PHONY: dev-install
dev-install: dev-ensure
	curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3
	ln -s ${HOME}/.poetry/bin/poetry /usr/bin/poetry
	poetry config virtualenvs.create false
	poetry install

.PHONY: dev-test-fast
dev-test-fast: dev-ensure
	# python -m mypy -p autogoal --ignore-missing-imports
	python -m pytest autogoal tests --doctest-modules -m "not slow" --ignore=autogoal/contrib/torch --ignore=autogoal/_old --cov=autogoal --cov-report=term-missing -v

.PHONY: dev-test-full
dev-test-full: dev-ensure
	# python -m mypy -p autogoal --ignore-missing-imports
	python -m pytest autogoal tests --doctest-modules --ignore=autogoal/contrib/torch --ignore=autogoal/_old --cov=autogoal --cov-report=term-missing -v

.PHONY: dev-cov
dev-cov: dev-ensure
	python -m codecov

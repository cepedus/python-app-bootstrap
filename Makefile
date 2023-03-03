include .pythonrc
PYTHON_VERSION?=
PYTHON_CURRENT_VERSION := $(shell python --version | cut -d " " -f 2)
PROJECT_NAME=app

# CI variables
CI_EXCLUDED_DIRS = __pycache__
CI_DIRECTORIES=$(filter-out $(CI_EXCLUDED_DIRS), $(foreach dir, $(dir $(wildcard */)), $(dir:/=)))

# Container variables
PYTHON_DOCKER_IMAGE=python:${PYTHON_VERSION}-slim
APP_DOCKER_IMAGE=$(PROJECT_NAME)-server


# Project targets
confirm:
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

exists-%:
	@which "$*" > /dev/null && echo 1 || echo 0

config: check-python-env
	@cp -n .env.sample .env || true

print-%: ; @echo $* = $($*)

check-python-env:
	@if [ "$(PYTHON_VERSION)" == "" ] || [ "$(PYTHON_VERSION)" != "$(PYTHON_CURRENT_VERSION)" ]; \
		then echo "The PYTHON_VERSION env variable must be set in .pythonrc and must be the same as the local Python environment before running this command" && exit 1;\
	fi



# Poetry
POETRY_AVAILABLE := $(shell which poetry > /dev/null && echo 1 || echo 0)


init: check-python-env
ifneq ($(POETRY_AVAILABLE), 1)
	@make setup-poetry
endif
	@poetry check --no-ansi --quiet
	@echo "✅ Poetry is installed"
	@echo "💡 Using Python $(PYTHON_CURRENT_VERSION)"
	@poetry config virtualenvs.in-project true
	@poetry env use $(PYTHON_CURRENT_VERSION) --quiet

setup-poetry:
	@echo "⏳ Installing Poetry..."
	@curl -sSL https://install.python-poetry.org | python3 -

install: init
	@echo "⏳ Installing dependencies..."
	@poetry install --quiet
	@echo "✅ Dependencies installed"

update: init
	@poetry update

clean-poetry:
	@echo "🧹 Cleaning Poetry cache..."
	@yes | poetry cache clear . --all --quiet
	
# CI targets 
lint-%:
	@echo lint-"$*"
	@find "$*" -name '*.py' | xargs poetry run pylint

lint: $(addprefix lint-, $(CI_DIRECTORIES))

typecheck-%:
	@echo typecheck-"$*"
	@find "$*" -name '*.py' | xargs poetry run mypy

typecheck: $(addprefix typecheck-, $(CI_DIRECTORIES))

test:
	@poetry run pytest --rootdir ./  --cache-clear tests

python-clean:
	@echo "🧹 Cleaning Python bytecode..."
	@poetry run pyclean . --quiet

# App
app-build: check-python-env
	@echo "Building Server image: $(APP_DOCKER_IMAGE)"
	@docker buildx bake  -f docker-compose.yaml \
	--set $(APP_DOCKER_IMAGE).args.PYTHON_DOCKER_IMAGE=$(PYTHON_DOCKER_IMAGE) 

app-run: config app-build
	@docker-compose up --force-recreate --remove-orphans

app-ci: lint typecheck test


clean-docker:
	@echo "🧹 Cleaning Docker cache..."
	@docker system prune --volumes --all --force >/dev/null || true

# Global
clean: confirm python-clean clean-poetry clean-docker
	@echo "✨ All clean"
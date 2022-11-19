PROJECT_NAME=app
PYTHON_MAJOR_VERSION=3.11

# CI variables
CI_EXCLUDED_DIRS = __pycache__
CI_DIRECTORIES=$(filter-out $(CI_EXCLUDED_DIRS), $(foreach dir, $(dir $(wildcard */)), $(dir:/=)))

# Container variables
PYTHON_DOCKER_IMAGE=python:${PYTHON_MAJOR_VERSION}-slim
APP_DOCKER_IMAGE=$(PROJECT_NAME)-server


# Project targets
confirm:
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]

exists-%: 
	@which "$*" > /dev/null && echo 1 || echo 0

config:
	@cp -n .env.sample .env || true


# Poetry
POETRY_AVAILABLE := $(shell which poetry > /dev/null && echo 1 || echo 0)

init:
ifneq ($(POETRY_AVAILABLE), 1)
	@make setup-poetry
endif
	@poetry check --no-ansi --quiet
	@echo "✅ Poetry is installed"
	@echo "💡 Using Python $(PYTHON_MAJOR_VERSION)"
	@poetry config virtualenvs.in-project true
	@poetry env use $(PYTHON_MAJOR_VERSION) --quiet

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
app-build:
	@echo "Building Server image: $(APP_DOCKER_IMAGE)"
	@docker buildx bake  -f docker-compose.yaml \
	--set $(APP_DOCKER_IMAGE).args.PYTHON_DOCKER_IMAGE=$(PYTHON_DOCKER_IMAGE)
app-run: config app-build
	@docker-compose up --force-recreate --remove-orphans

app-ci: lint typecheck test


# Global
clean: confirm python-clean clean-poetry
	@echo "✨ All clean"
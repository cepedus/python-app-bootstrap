PROJECT_NAME=app

# Python env
PYTHON_PROJECT_VERSION := $(shell cat .python-version | tr -d '[:space:]')
PYTHON_SHELL_VERSION := $(shell python --version | cut -d " " -f 2)
POETRY_AVAILABLE := $(shell which poetry > /dev/null && echo 1 || echo 0)

# CI variables
CI_EXCLUDED_DIRS = __pycache__
CI_DIRECTORIES=$(filter-out $(CI_EXCLUDED_DIRS), $(foreach dir, $(dir $(wildcard */)), $(dir:/=)))

# Container variables
PYTHON_DOCKER_IMAGE=python:${PYTHON_PROJECT_VERSION}-slim
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
	@if [ "$(PYTHON_PROJECT_VERSION)" == "" ] || [ "$(PYTHON_PROJECT_VERSION)" != "$(PYTHON_SHELL_VERSION)" ]; \
		then echo "The PYTHON_VERSION env variable must be set in .python-version and must be the same as the local Python environment before running this command" && exit 1;\
	fi

init: check-python-env
ifneq ($(POETRY_AVAILABLE), 1)
	@echo "No Poetry executable found, cannot init project" && exit 1;
endif
	@poetry check --no-ansi --quiet
	@echo "✅ Poetry is installed"
	@echo "💡 Using Python $(PYTHON_SHELL_VERSION)"
	@poetry config virtualenvs.in-project true
	@poetry config virtualenvs.create true
	@poetry install

# CI targets 
lint-%:
	@echo lint-"$*"
	@poetry run ruff "$*"
	@echo "    ✅ All good"

lint: $(addprefix lint-, $(CI_DIRECTORIES))

typecheck-%:
	@echo typecheck-"$*"
	@poetry run mypy "$*"

typecheck: $(addprefix typecheck-, $(CI_DIRECTORIES))

test:
	@poetry run pytest --rootdir ./  --cache-clear tests

ci: lint typecheck test


# App
app-build: check-python-env
	@echo "Building Server image: $(APP_DOCKER_IMAGE)"
	@docker buildx bake  -f docker-compose.yaml \
	--set $(APP_DOCKER_IMAGE).args.PYTHON_DOCKER_IMAGE=$(PYTHON_DOCKER_IMAGE) 

app-run: config app-build
	@docker-compose up --force-recreate --remove-orphans



clean-docker:
	@echo "🧹 Cleaning Docker cache..."
	@docker system prune --volumes --all --force >/dev/null || true

python-clean:
	@echo "🧹 Cleaning Python bytecode..."
	@poetry run pyclean . --quiet

clean-cache:
	@echo "🧹 Cleaning cache..."
	@find . -regex ".*_cache" -type d -print0|xargs -0 rm -r --
# Global
clean: confirm clean-cache python-clean clean-docker
	@echo "✨ All clean"
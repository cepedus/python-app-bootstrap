ARG PYTHON_DOCKER_IMAGE
# Base Poetry layer
FROM $PYTHON_DOCKER_IMAGE AS python-base

# Bootstrap folders & non-root user
RUN mkdir -p /app && \
    chown 1000:1000 -R /app

# System env
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV PATH="/root/.local/bin:/app:${PATH}"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y gcc \
    && apt-get clean

# Python env
ENV PYTHONPATH="/root/.local/bin:/app:${PYTHONPATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONASYNCIODEBUG=1
ENV PIP_NO_CACHE_DIR=1

# Bootstrap poetry
WORKDIR /app
ENV POETRY_VIRTUALENVS_CREATE=false
RUN pip install poetry --no-warn-script-location

# Requirements layer
FROM python-base AS python-app
COPY pyproject.toml ./pyproject.toml
COPY poetry.lock ./poetry.lock
RUN poetry install --only=main --no-root --no-interaction --no-ansi

FROM python-app as app
# Add server source & entrypoint
COPY server ./server
RUN chmod +x /app/server/entrypoint.sh

# Add modules

# App environment
ENV HOSTNAME=0.0.0.0
ENV PORT=5001
# #
# ENV JWT_SECRET=
# ENV JWT_ENCRYPTION_ALGORITHM=
# #
# ENV MONGODB_DATABASE=
# ENV MONGODB_HOST=
# ENV MONGODB_USER=
# ENV MONGODB_PASSWORD=
# ENV MONGODB_PROTOCOL=mongodb+srv
#
ENV ENABLE_HTTPS_REDIRECT=
ENV USE_JSON_LOGGING=

# Launch app
USER 1000
ENTRYPOINT ["server/entrypoint.sh"]
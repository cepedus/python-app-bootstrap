import pathlib
import re

DOCKERFILE_COPY_REGEX = r"COPY ([\w\d]+) \.\/"
DOCKERFILE_UNSET_ENV_REGEX = r"[^(# )]ENV ([\w\d]+)=(.)*"
ENV_SAMPLE_ENV_REGEX = r"\n([\w\d]+)="
DOCKER_COMPOSE_WORKING_DIR_REGEX = r"working_dir: /([\S]+)"
DOCKER_COMPOSE_VOLUME_REGEX = r"- \.\/([\w\d]+)\/:\/WORKING_DIR\/([\w\d]+)"

TEST_FILE_PATH = pathlib.Path(__file__).parent.resolve()
DOCKERFILE_PATHS = list(TEST_FILE_PATH.glob("../**/Dockerfile*"))
DOCKER_COMPOSE_PATHS = list(TEST_FILE_PATH.glob("../**/docker-compose.yaml"))
ENV_SAMPLE_PATHS = list(TEST_FILE_PATH.glob("../**/.env.sample"))


def test_file_uniqueness() -> None:
    # File uniqueness
    if len(DOCKERFILE_PATHS) != 1:
        raise ValueError(
            f"Found more than one 'Dockerfile*': {', '.join(str(p) for p in DOCKERFILE_PATHS) }"
        )

    if len(DOCKER_COMPOSE_PATHS) != 1:
        raise ValueError(
            "Found more than one 'docker-compose.yaml':"
            f" {', '.join(str(p) for p in DOCKERFILE_PATHS) }"
        )
    if len(ENV_SAMPLE_PATHS) != 1:
        raise ValueError(
            f"Found more than one '.env.sample': {', '.join(str(p) for p in ENV_SAMPLE_PATHS) }"
        )


def test_docker_volumes() -> None:
    with open(DOCKERFILE_PATHS[0], encoding="utf-8", mode="r") as f:
        dockerfile = f.read()
    with open(DOCKER_COMPOSE_PATHS[0], encoding="utf-8", mode="r") as f:
        docker_compose = f.read()

    # Imported modules on Dockerfile
    dockerfile_folders = re.findall(DOCKERFILE_COPY_REGEX, dockerfile)
    # Working dir on docker-compose
    working_dir = re.search(DOCKER_COMPOSE_WORKING_DIR_REGEX, docker_compose)
    if working_dir is None:
        raise ValueError(f"'- working_dir: ' not specified on '{DOCKER_COMPOSE_PATHS[0]}'")
    working_dir_folder = working_dir.groups()[0].strip("/")

    volumes_search_regex = DOCKER_COMPOSE_VOLUME_REGEX.replace(
        "WORKING_DIR", working_dir_folder.replace("/", r"\/")
    )
    # Volumes on docker-compose
    docker_compose_volumes = re.findall(volumes_search_regex, docker_compose)
    if docker_compose_volumes is None:
        raise ValueError(f"No volume mounting was specified on '{DOCKER_COMPOSE_PATHS[0]}'")
    # Consistent volume mounting
    for v_local, v_mounted in docker_compose_volumes:
        if v_local != v_mounted:
            raise ValueError(
                f"Inconsistent mounting: '{v_local}' is mounted to"
                f" '{working_dir_folder}/{v_mounted}'"
            )
    mounted_volumes = [v_local for v_local, _ in docker_compose_volumes]
    # Sufficient volume mounting
    for volume_folder in dockerfile_folders:
        if volume_folder not in mounted_volumes:
            raise ValueError(
                f"Folder '{volume_folder}' was copied on Dockerfile but not mounted as a separate"
                " volume on docker-compose.yaml"
            )


def test_env_definition() -> None:
    with open(DOCKERFILE_PATHS[0], encoding="utf-8", mode="r") as f:
        dockerfile = f.read()
    app_env_text_index = dockerfile.find("# App environment")
    if app_env_text_index == -1:
        raise ValueError(
            f"'# App environment' section needs to be present on {DOCKERFILE_PATHS[0]}"
        )
    dockerfile_env_variables_part = dockerfile[app_env_text_index:]
    dockerfile_env_variables_and_values = re.findall(
        DOCKERFILE_UNSET_ENV_REGEX, dockerfile_env_variables_part
    )
    dockerfile_env_variables = [k for k, v in dockerfile_env_variables_and_values if v == ""]

    with open(ENV_SAMPLE_PATHS[0], encoding="utf-8", mode="r") as f:
        env_sample = f.read()
    env_sample_variables = re.findall(ENV_SAMPLE_ENV_REGEX, env_sample)

    for v in dockerfile_env_variables:
        if v not in env_sample_variables:
            raise ValueError(
                f"{v} declared on {DOCKERFILE_PATHS[0]} but not present on {ENV_SAMPLE_PATHS[0]}"
            )

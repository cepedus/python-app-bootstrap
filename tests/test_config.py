import pathlib
import re
from platform import python_version

CURRENT_MINOR_VERSION = ".".join(python_version().split(".")[:2])

TEST_FILE_PATH = pathlib.Path(__file__).parent.resolve()
PYPROJECT_TOML_PATH = list(TEST_FILE_PATH.glob("../pyproject.toml"))
MAKEFILE_PATH = list(TEST_FILE_PATH.glob("../Makefile"))


MAKEFILE_VERSION_REGEX = r"PYTHON_MINOR_VERSION=(\S+)"
PYPROJECT_TOML_VERSION_REGEX = r"\n((?:py(?:thon)?)(?:[_-]version)?)\s=\D+(\d+.\d+)"


def test_file_uniqueness() -> None:
    # File uniqueness
    if len(PYPROJECT_TOML_PATH) != 1:
        raise ValueError(
            "Found not only one 'pyproject.toml':"
            f" {', '.join(str(p) for p in PYPROJECT_TOML_PATH) }"
        )

    if len(MAKEFILE_PATH) != 1:
        raise ValueError(
            f"Found not only one 'Makefile': {', '.join(str(p) for p in MAKEFILE_PATH) }"
        )


def test_consistent_versioning() -> None:
    with open(PYPROJECT_TOML_PATH[0], encoding="utf-8", mode="r") as f:
        pyproject_toml = f.read()
    with open(MAKEFILE_PATH[0], encoding="utf-8", mode="r") as f:
        makefile = f.read()

    # Makefile env var for building containers
    makefile_python_version = re.findall(MAKEFILE_VERSION_REGEX, makefile)
    if makefile_python_version is None:
        raise ValueError(f"'PYTHON_MINOR_VERSION' not specified on '{MAKEFILE_PATH[0]}'")

    if makefile_python_version[0] != CURRENT_MINOR_VERSION:
        raise ValueError(
            f"Inconsistent versioning on Makefile ({makefile_python_version[0]}) and running script"
            f" ({CURRENT_MINOR_VERSION})"
        )

    # TOML configurations
    toml_versions = re.findall(PYPROJECT_TOML_VERSION_REGEX, pyproject_toml)
    for var_name, var_version in toml_versions:
        if var_version != CURRENT_MINOR_VERSION:
            raise ValueError(
                f'"{var_name}" on file pyproject.toml is not set to {CURRENT_MINOR_VERSION}'
            )

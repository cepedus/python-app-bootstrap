# Poetry-FastAPI bootstrap template
> *Author: [cepedus](https://www.github.com/cepedus)*

> *README version:* 2023-06-25

This repository contains the setup, configuration and `make` targets to develop and deploy the simplest FastAPI app, providing scalable utils to type-check, lint and test your code.

**🚦 Requirements**

*Assuming you have a Unix shell with [`make`](https://www.gnu.org/software/make/) and [`curl`](https://curl.se/)*


- This repository works by default with Python `3.11`. Details are provided on how to change this on the sections below.
- A Python 3.11 executable of your choice: install using [pyenv](https://github.com/pyenv/pyenv), [official installers](https://www.python.org/downloads/), [brew](https://brew.sh/), [conda](https://docs.conda.io/en/latest/miniconda.html), [mamba](https://mamba.readthedocs.io/en/latest/index.html), etc.


**🥾 Want to set up a Poetry-managed replicable environment?**
```bash
make init
```

**🧪 Want to test the code and configuration?**
```bash
make app-ci
```

**✨ Want to build and run the app?**
```bash
make app-run
```

---

- [Poetry-FastAPI bootstrap template](#poetry-fastapi-bootstrap-template)
  - [🪄 The magic tricks](#-the-magic-tricks)
    - [Dissecting Makefile](#dissecting-makefile)
    - [Dissecting .python-version](#dissecting-python-version)
  - [👀 What are the extra files?](#-what-are-the-extra-files)
    - [Dissecting Dockerfile](#dissecting-dockerfile)
    - [Dissecting docker-compose.yaml](#dissecting-docker-composeyaml)
    - [Dissecting pyproject.toml](#dissecting-pyprojecttoml)
  - [💡 Why I did this?](#-why-i-did-this)
    - [➡️ What's missing](#️-whats-missing)

## 🪄 The magic tricks

You're wondering what those 3 commands actually *do*. The main control over the repo is hosted under `make` targets that link commonly used utils when developing a Python app:

- Environment setup: [Poetry](https://python-poetry.org/docs/)
- Code quality: [mypy](https://mypy.readthedocs.io/en/stable/), [pylint](https://pylint.pycqa.org/en/latest/), [pytest](https://docs.pytest.org/en/latest/)
- Server framework: [FastAPI](https://fastapi.tiangolo.com/)
- Container deployment: [Docker](https://docs.docker.com/get-started/overview/)

The package-specific configurations are gathered on a single TOML file (Poetry, mypy, pylint and isort). In particular, we use:
- Pytorch's [`mypy-strict.ini`](https://github.com/pytorch/pytorch/blob/master/mypy-strict.ini) rules
- Minimal [disable](https://github.com/cepedus/poetry-bootstrap/blob/main/pyproject.toml#L419) rules for pylint (no docstring whatsoever => keep your code as clean as possible!)
- Strict `asyncio` mode for pytest.

### Dissecting [Makefile](./Makefile)

- `init` installs Poetry using the official installer (if not present on your system), creates a project-specific virtual environment and installs the dependencies of your [`.lock`](poetry.lock) file.
- `app-ci` launches pylint, mypy and pytest on your source code.
- `app-run` builds and deploys locally your app. The 2 services (app and database) are launched on the same virtual network.
- `clean` clears bytecode, poetry/pip caches and Docker cache, dangling images and volumes. Use with caution.

### Dissecting [.python-version](./.python-version)

- A single entrypoint for changing your build defining, for example, `3.11.3`. Works best algonside with `pyenv`



## 👀 What are the extra files?

### Dissecting [Dockerfile](./Dockerfile)

It consists of a standard 2-layer image. On the first one we install poetry and on the 2nd one we install our requirements and run the app, passing environment variables individually.

**Why a custom entrypoint?**

To properly propagate process signals to the container. As the spawned shell to run our app runs on Bash, we spawns a child process to run node, but signals sent to the parent process are not forwarded to the child processes (a more detailed explanation in found [here](https://www.kaggle.com/code/residentmario/best-practices-for-propagating-signals-on-docker) and [there](https://www.padok.fr/en/blog/docker-processes-container#How_it_should_happen)). 

In order to have a proper signal managmement, we trap and handle `SIGINT` and `SIGTERM`: see [server/entrypoint.sh](server/entrypoint.sh).

### Dissecting [docker-compose.yaml](./docker-compose.yaml)

We explicitly define an internal network in order for the containers of Mongo and our app to work properly.


### Dissecting [pyproject.toml](./pyproject.toml)

Here we centralise all of the relevant configuration for:
- Poetry
- Mypy
- Ruff
- isort
- Black
- Pytest

---

## 💡 Why I did this?

Setting up a replicable environment, creating your Dockerfiles and making sure everything is coherent when developing is, well, not *actual* development of new features for your app. If some of those preliminary, yet necessary steps fail it can easily take down your deployment or give place to strange dependency bugs, Docker not finding what's supposed to or even security implications in your containers.

In this repo I tried to gather all of these generic building bricks to allow focusing on what's important if you're developing: writing **code** rather than **configurations**. If the entrypoint to land on your app is simplified, you can onboard contributors much more easily and your app's "control tower" is abstracted. 

Also, with the right building blocks is easier to follow coding good practices and thus maintain your codebase away from *spaghettification*.

### ➡️ What's missing
- Repository configuration: direct commits to the main branch are forbidden, only possible to do so through PRs.
- GitHub Actions: workflows to CI check each commit to the main branch and on PRs.

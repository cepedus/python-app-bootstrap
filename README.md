# Poetry-FastAPI bootstrap template
> *Author: [cepedus](https://www.github.com/cepedus)*

> *README version:* 2022-11-26

This repository contains the setup, configuration and `make` targets to develop and deploy the simplest FastAPI app, providing scalable utils to type-check, lint and test your code.

**🚦 Requirements**

*Assuming you have an Unix shell with [`make`](https://www.gnu.org/software/make/) and [`curl`](https://curl.se/)*


- A Python 3 executable of your choice: install using the [official installers](https://www.python.org/downloads/), [brew](https://brew.sh/), [conda](https://docs.conda.io/en/latest/miniconda.html), [mamba](https://mamba.readthedocs.io/en/latest/index.html), etc.
- This repository works by default with Python `3.11`. Details are provided on how to change this on the sections below

**🥾 Want to setup a Poetry-managed replicable environment?**
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

--- 
***⚠️ Sections below are a Work in Progress***

### Dissecting [Makefile](./Makefile)

## 👀 What are the extra files?

### Dissecting [Dockerfile](./Dockerfile)


### Dissecting [docker-compose.yaml](./docker-compose.yaml)


### Dissecting [pyproject.toml](./pyproject.toml)

---

## 💡 Why I did this?

Setting up a replicable environment, creating your Dockerfiles and making sure everything is coherent when developing is, well, not *actual* development of new features for your app. If some of those preliminary, yet necessary steps fail it can easily take down your deployment or give place to strange dependency bugs, Docker not finding what's supposed to or even security implications in your containers.

In this repo I tried to gather all of these generic building bricks to allow focusing on what's important if you're developing: writing **code** rather than **configurations**. If the entrypoint to land on your app is simplified, you can onboard contributors much more easily and your app's "control tower" is abstracted. 

Also, with the right building blocks is easier to follow coding good practices and thus maintain your codebase away from *spaghettification*.

### ➡️ What's missing
- Repository configuration: direct commits to the main branch are forbidden, only possible to do so through PRs.
- Github Actions: workflows to CI check each commit to the main branch and on PRs.

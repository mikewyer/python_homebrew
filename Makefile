POETRY_VERSION=1.8
POETRY=$(shell PATH="$$HOME/bin:$$PATH" command -v poetry${POETRY_VERSION})
VER=$(shell PATH="$$HOME/bin:$$PATH" poetry${POETRY_VERSION} version -s)
CLI_VER=pybinary-${VER}

dist/${CLI_VER}.zip:
        ${POETRY} run pyinstaller src/main.py -n ${CLI_VER} \
        && cd dist \
        && ${CLI_VER}/${CLI_VER} --version \
        && mv ${CLI_VER}/${CLI_VER} ${CLI_VER}/pybinary \
        && zip -r ${CLI_VER}.zip ${CLI_VER}

cli-zip: dist/${CLI_VER}.zip


# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG OWNER=jupyter
ARG BASE_CONTAINER=$OWNER/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NB_USER="sagemaker-user"
ARG NB_UID="1000"
ARG NB_GID="100"

ENV NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    HOME=/home/$NB_USER \
    R_REPO="https://cran.rstudio.com/" \
    R_VERSION="4.3" \
    R_USER_LIB_PATH="/home/${NB_USER}/R/x86_64-pc-linux-gnu-library/${R_VERSION}"

USER root

# R pre-requisites
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-dejavu \
    unixodbc \
    unixodbc-dev \
    gfortran \
    gcc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# R packages including IRKernel which gets installed globally.
RUN mamba install --quiet --yes \
    "r-base=${R_VERSION}" \
    'r-caret' \
    'r-crayon' \
    'r-devtools' \
    'r-e1071' \
    'r-forecast' \
    'r-hexbin' \
    'r-htmltools' \
    'r-htmlwidgets' \
    'r-irkernel' \
    'r-nycflights13' \
    'r-randomforest' \
    'r-rcurl' \
    'r-reticulate' \
    'r-rmarkdown' \
    'r-rodbc' \
    'r-rsqlite' \
    'r-shiny' \
    'r-tidyverse' \
    'r-tidymodels' \
    'boto3' \
    'sagemaker' \
    'unixodbc' && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install additional R packages not available in conda
RUN R -e "install.packages(c('remotes', 'plotly', 'jsonlite', 'httr', 'data.table', 'aws.s3'), repos='${R_REPO}', dependencies=TRUE)"

# Install IRKernel to Jupyter
RUN R -e "IRkernel::installspec(user = FALSE)"

# Set CRAN repository for R
RUN echo 'options(repos = c(CRAN = "'${R_REPO}'"))' >> /usr/lib/R/etc/Rprofile.site

# Create user library folder for R
RUN mkdir -p ${R_USER_LIB_PATH} && \
    fix-permissions ${R_USER_LIB_PATH} && \
    fix-permissions /home/${NB_USER}

# Optional: Install LaTeX for R Markdown PDF rendering
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python data science packages
RUN pip install numpy pandas matplotlib seaborn

# Create sagemaker user
RUN useradd --non-unique --create-home --shell /bin/bash --gid "${NB_GID}" --uid ${NB_UID} "sagemaker-user"

WORKDIR $HOME
USER ${NB_UID}

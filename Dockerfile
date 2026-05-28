FROM ubuntu:24.04 as base
USER root

## Setting default environment variables
ENV WEB_ROOT=/web_root
# Root project folder
ENV ARCHES_ROOT=${WEB_ROOT}/arches
ENV WHEELS=/wheels
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends make software-properties-common \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

FROM base as wheelbuilder

WORKDIR ${WHEELS}

# Install packages required to build the python libs, then remove them
RUN set -ex \
    && BUILD_DEPS=" \
        build-essential \
        libxml2-dev \
        libproj-dev \
        libjson-c-dev \
        xsltproc \
        docbook-xsl \
        docbook-mathml \
        libgdal-dev \
        libpq-dev \
        python3.12 \
        python3.12-dev \
        curl \
        libldap2-dev libsasl2-dev ldap-utils \
        dos2unix \
        " \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends $BUILD_DEPS \
    && apt-get install -y --no-install-recommends python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip wheel --no-cache-dir gunicorn \
    && pip wheel --no-cache-dir django-auth-ldap

# Add Docker-related files
COPY docker/entrypoint.sh ${WHEELS}/entrypoint.sh
RUN chmod -R 700 ${WHEELS} &&\
  dos2unix ${WHEELS}/*.sh

FROM base

# Get the pre-built python wheels from the build environment
RUN mkdir ${WEB_ROOT}

COPY --from=wheelbuilder ${WHEELS} /wheels

# Install packages required to run Arches
RUN set -ex \
    && RUN_DEPS=" \
        libgdal-dev \
        python3-venv \
        postgresql-client-12 \
        python3.12 \
        python3-pip \
        python3.12-venv \
    " \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && NODE_MAJOR=20 \
    && (echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" > /etc/apt/sources.list.d/nodesource.list) \
    && curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends $RUN_DEPS \
    && apt-get install -y --no-install-recommends nodejs git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install npm components
COPY ./package.json ${ARCHES_ROOT}/package.json
WORKDIR ${ARCHES_ROOT}
RUN mkdir -p ${ARCHES_ROOT}/node_modules
RUN npm install \
    && npm cache clean --force \
    && rm -rf /root/.npm /tmp/*

## Install virtualenv
WORKDIR ${WEB_ROOT}

RUN mv ${WHEELS}/entrypoint.sh entrypoint.sh

RUN python3.12 -m venv ENV \
    && . ENV/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir wheel setuptools requests \
    && pip install --no-cache-dir rjsmin==1.2.0 MarkupSafe==2.0.0 \
    && pip install --no-cache-dir requests \
    && pip install --no-cache-dir -f ${WHEELS} django-auth-ldap \
    && pip install --no-cache-dir -f ${WHEELS} gunicorn \
    && rm -rf ${WHEELS} /root/.cache/pip

# Install the Arches application
# FIXME: ADD from github repository instead?
COPY . ${ARCHES_ROOT}

# From here, run commands from ARCHES_ROOT
WORKDIR ${ARCHES_ROOT}

RUN . ../ENV/bin/activate \
    && pip install --no-cache-dir -e . --group dev --prefer-binary \
    && rm -rf /root/.cache/pip


# Set default workdir
WORKDIR ${ARCHES_ROOT}

COPY docker/gunicorn_config.py ${ARCHES_ROOT}/gunicorn_config.py
COPY docker/settings_local.py ${ARCHES_ROOT}/arches/settings_local.py

# Strip __pycache__ and node_modules. node_modules is only needed during
# webpack builds in downstream image stages (Dockerfile.static-py reinstalls it
# transiently); at runtime, django-webpack-loader resolves via webpack-stats.json
# and media/build, so the on-disk tree is dead weight.
RUN rm -rf ${ARCHES_ROOT}/node_modules \
    && find ${WEB_ROOT} -type d -name __pycache__ -prune -exec rm -rf {} + || true

# Set entrypoint
ENTRYPOINT ["../entrypoint.sh"]
CMD ["run_arches"]

# Expose port 8000
EXPOSE 8000

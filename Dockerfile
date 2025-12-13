ARG RUNNER_VERSION=2.330.0
FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION}

USER root

# Install additional tools and locale (runner base image already contains core deps)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    unzip \
    zip \
    sudo \
    rsync \
    openssh-client \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools needed for linting and Ansible workflows
RUN pip3 install --no-cache-dir \
    ansible \
    ansible-lint \
    yamllint \
    kubernetes \
    netaddr \
    jmespath \
    dnspython

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Copy start script and keep runner user
WORKDIR /home/runner
COPY --chown=runner:runner start.sh /home/runner/start.sh
RUN chmod +x /home/runner/start.sh

USER runner

ENTRYPOINT ["/home/runner/start.sh"]

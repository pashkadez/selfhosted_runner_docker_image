FROM ubuntu:22.04

ARG RUNNER_VERSION=2.321.0
ARG TARGETARCH=amd64

# Prevents installdependencies.sh from prompting for input
ENV DEBIAN_FRONTEND=noninteractive

# Install base packages (minimal dependencies for GitHub Actions runner)
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Required for runner registration and API calls
    curl \
    ca-certificates \
    jq \
    # Essential for most workflows
    git \
    unzip \
    zip \
    sudo \
    rsync \
    openssh-client \
    # Libraries required by GitHub Actions runner
    libicu70 \
    libkrb5-3 \
    zlib1g \
    libssl3 \
    # Additional utilities
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user for the runner with sudo access
RUN useradd -m -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/runner

# Download, extract GitHub Actions runner, install deps, and cleanup in single layer
# Note: installdependencies.sh runs apt-get, so we clean up after it too
RUN RUNNER_ARCH=$(case ${TARGETARCH} in "amd64") echo "x64";; "arm64") echo "arm64";; *) echo "x64";; esac) \
    && curl -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" -o actions-runner.tar.gz \
    && tar -xzf actions-runner.tar.gz \
    && rm actions-runner.tar.gz \
    && chown -R runner:runner /home/runner \
    && ./bin/installdependencies.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy start script
COPY --chown=runner:runner start.sh /home/runner/start.sh
RUN chmod +x /home/runner/start.sh

# Switch to runner user
USER runner

# Set entrypoint
ENTRYPOINT ["/home/runner/start.sh"]

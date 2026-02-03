FROM ubuntu:22.04

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    # Runner/.NET deps (fixes libicu error)
    libicu70 \
    libkrb5-3 \
    zlib1g \
    liblttng-ust1 \
    libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (client only) so actions can run `docker ...`
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*


ENV RUNNER_HOME=/home/runner

RUN useradd -m -d ${RUNNER_HOME} runner
# Match host docker group so runner can access /var/run/docker.sock
ARG DOCKER_GID=987
RUN groupadd -g ${DOCKER_GID} docker && usermod -aG docker runner

WORKDIR ${RUNNER_HOME}

# Download and extract GitHub Actions runner
RUN curl -o actions-runner-linux-x64-2.331.0.tar.gz -L \
    https://github.com/actions/runner/releases/download/v2.331.0/actions-runner-linux-x64-2.331.0.tar.gz \
    && tar xzf ./actions-runner-linux-x64-2.331.0.tar.gz \
    && rm actions-runner-linux-x64-2.331.0.tar.gz \
    # Install any additional runner dependencies using official script
    && ./bin/installdependencies.sh \
    && chown -R runner:runner ${RUNNER_HOME}

USER runner

RUN cat > entrypoint.sh << 'EOF'
#!/bin/bash
set -e

if [ -z "$GITHUB_REPO_URL" ]; then
  echo "Error: GITHUB_REPO_URL is required"
  exit 1
fi

cd /home/runner

if [ ! -f ".runner" ]; then
  if [ -z "$RUNNER_TOKEN" ]; then
    echo "Error: RUNNER_TOKEN is required for first-time registration"
    exit 1
  fi

  ./config.sh \
    --url "$GITHUB_REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --unattended \
    --name "${RUNNER_NAME:-homelab-runner-1}" \
    --labels "${RUNNER_LABELS:-homelab,linux,docker}" \
    --work "_work"

  echo "Runner configured."
else
  echo "Runner already configured. Skipping config."
fi

exec ./run.sh
EOF

RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

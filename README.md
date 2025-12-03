# GitHub Actions Self-Hosted Runner Docker Image

A minimal Ubuntu 22.04 Docker image for GitHub Actions self-hosted runners, optimized for use with GitHub Runner Controller in Kubernetes.

## Features

- **Base**: Ubuntu 22.04 LTS
- **GitHub Actions Runner**: Latest version (v2.321.0)
- **Pre-installed Tools**:
  - Git, curl, wget, jq, rsync, openssh-client
  - Essential utilities (zip, unzip, sudo)
- **Automatic Registration**: Automatically registers with GitHub on startup
- **Ephemeral Mode**: Runs as ephemeral runner (removes itself after job completion)
- **Graceful Shutdown**: Properly deregisters from GitHub on container stop
- **Minimal Footprint**: Optimized for Kubernetes deployments
- **Automated Builds**: Docker image automatically built and published to GitHub Container Registry

## Container Image

The image is automatically built and published to GitHub Container Registry on every push to main branch and on tagged releases.

### Pull the image

```bash
docker pull ghcr.io/pashkadez/selfhosted_runner_docker_image:latest
```

### Available tags

- `latest` - Latest build from main branch
- `v*` - Semantic versioned releases (e.g., `v1.0.0`, `1.0`, `1`)
- `main` - Latest from main branch
- `<commit-sha>` - Specific commit (full 40-character SHA)

## Quick Start

### Prerequisites

- Docker installed (for local testing)
- GitHub Personal Access Token (PAT) with appropriate permissions:
  - For repository runners: `repo` scope
  - For organization runners: `admin:org` scope

### Using the Published Image

```bash
docker run -d \
  --name github-runner \
  -e GH_TOKEN=your_token \
  -e GH_OWNER=your_owner \
  -e GH_REPOSITORY=your_repo \
  ghcr.io/pashkadez/selfhosted_runner_docker_image:latest
```

### Using Docker Compose

1. Clone this repository:
   ```bash
   git clone https://github.com/pashkadez/selfhosted_runner_docker_image.git
   cd selfhosted_runner_docker_image
   ```

2. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your settings:
   ```bash
   GH_TOKEN=your_github_personal_access_token
   GH_OWNER=your_github_username_or_org
   GH_REPOSITORY=your_repository_name  # Optional: omit for org-level runner
   RUNNER_NAME=my-runner
   RUNNER_LABELS=self-hosted,Linux,x64
   ```

4. Start the runner:
   ```bash
   docker-compose up -d
   ```

5. Check the logs:
   ```bash
   docker-compose logs -f
   ```

### Building Locally

1. Build the image:
   ```bash
   docker build -t github-actions-runner:latest .
   ```

2. Run the container:
   ```bash
   docker run -d \
     --name github-runner \
     -e GH_TOKEN=your_token \
     -e GH_OWNER=your_owner \
     -e GH_REPOSITORY=your_repo \
     github-actions-runner:latest
   ```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_TOKEN` | Yes | GitHub Personal Access Token |
| `GH_OWNER` | Yes | GitHub username or organization name |
| `GH_REPOSITORY` | No | Repository name (omit for org-level runner) |
| `RUNNER_NAME` | No | Custom runner name (defaults to hostname) |
| `RUNNER_LABELS` | No | Comma-separated labels (default: `self-hosted,Linux,x64`) |
| `RUNNER_WORKDIR` | No | Work directory (default: `_work`) |
| `RUNNER_GROUP` | No | Runner group for org runners (default: `Default`) |

## Pre-installed Software

| Software | Version |
|----------|---------|
| Ubuntu | 22.04 LTS |
| GitHub Actions Runner | 2.321.0 |
| Git | Latest |
| curl, wget | Latest |
| jq | Latest |
| rsync | Latest |
| openssh-client | Latest |

## Kubernetes Deployment

This image is optimized for use with the [GitHub Actions Runner Controller](https://github.com/actions/actions-runner-controller) in Kubernetes environments.

## Customization

### Adding Additional Tools

Extend the Dockerfile to add more tools as needed for your workflows:

```dockerfile
FROM ghcr.io/pashkadez/selfhosted_runner_docker_image:latest

USER root
RUN apt-get update && apt-get install -y your-package
USER runner
```

### Changing Runner Version

Update the `RUNNER_VERSION` build argument:

```bash
docker build --build-arg RUNNER_VERSION=2.320.0 -t github-actions-runner:latest .
```

## CI/CD

This repository uses GitHub Actions to automatically build and publish the Docker image:

- **On push to main**: Builds and publishes with `latest` and commit SHA tags
- **On tag push (v*)**: Publishes with semantic version tags
- **On pull request**: Builds only (no push) for validation

## Troubleshooting

### Runner not appearing in GitHub

1. Check the container logs: `docker-compose logs github-runner`
2. Verify your PAT has the correct scopes
3. Ensure GH_OWNER and GH_REPOSITORY are correct

### Permission denied errors

If you see permission errors, ensure:
1. The runner user has appropriate permissions
2. Volume mounts have correct ownership

## License

This project is open source and available under the MIT License.
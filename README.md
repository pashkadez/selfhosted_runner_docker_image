# GitHub Actions Self-Hosted Runner Docker Image

An optimized Ubuntu 22.04 Docker image for GitHub Actions self-hosted runners with all common dependencies pre-installed.

## Features

- **Base**: Ubuntu 22.04 LTS
- **GitHub Actions Runner**: Latest version (v2.321.0)
- **Pre-installed Tools**:
  - Git, curl, wget, jq, rsync, openssh-client
  - Build essentials (gcc, g++, make, cmake)
  - Docker CLI and Docker Compose
  - Node.js 18.x with npm and Yarn
  - Python 3 with pip and venv
  - .NET SDK 8.0
  - OpenJDK 17 with Maven and Gradle
  - Go 1.22.5
- **Automatic Registration**: Automatically registers with GitHub on startup
- **Ephemeral Mode**: Runs as ephemeral runner (removes itself after job completion)
- **Graceful Shutdown**: Properly deregisters from GitHub on container stop

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- GitHub Personal Access Token (PAT) with appropriate permissions:
  - For repository runners: `repo` scope
  - For organization runners: `admin:org` scope

### Using Docker Compose (Recommended)

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
   RUNNER_LABELS=self-hosted,Linux,X64,docker
   ```

4. Start the runner:
   ```bash
   docker-compose up -d
   ```

5. Check the logs:
   ```bash
   docker-compose logs -f
   ```

### Using Docker CLI

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
     -v /var/run/docker.sock:/var/run/docker.sock \
     github-actions-runner:latest
   ```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_TOKEN` | Yes | GitHub Personal Access Token |
| `GH_OWNER` | Yes | GitHub username or organization name |
| `GH_REPOSITORY` | No | Repository name (omit for org-level runner) |
| `RUNNER_NAME` | No | Custom runner name (defaults to hostname) |
| `RUNNER_LABELS` | No | Comma-separated labels (default: `self-hosted,Linux,X64,docker`) |
| `RUNNER_WORKDIR` | No | Work directory (default: `_work`) |
| `RUNNER_GROUP` | No | Runner group for org runners (default: `Default`) |

## Pre-installed Software Versions

| Software | Version |
|----------|---------|
| Ubuntu | 22.04 LTS |
| GitHub Actions Runner | 2.321.0 |
| Docker CLI | Latest |
| Docker Compose | 2.29.7 |
| Node.js | 18.x |
| Python | 3.10.x |
| .NET SDK | 8.0 |
| OpenJDK | 17 |
| Go | 1.22.5 |
| Maven | Latest |
| Gradle | Latest |

## Docker-in-Docker Support

To enable Docker commands within your workflows, mount the Docker socket:

```yaml
# docker-compose.yml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

## Scaling Runners

To run multiple runners, use Docker Compose with scaling:

```bash
docker-compose up -d --scale github-runner=3
```

Or create multiple services with different names in `docker-compose.yml`.

## Security Considerations

1. **Never commit your `.env` file** - it contains sensitive tokens
2. **Use fine-grained PATs** when possible with minimal required permissions
3. **Mount Docker socket carefully** - it grants significant access to the host
4. **Use ephemeral runners** (default) for better security isolation

## Customization

### Adding Additional Tools

Extend the Dockerfile to add more tools:

```dockerfile
FROM github-actions-runner:latest

USER root
RUN apt-get update && apt-get install -y your-package
USER runner
```

### Changing Runner Version

Update the `RUNNER_VERSION` build argument:

```bash
docker build --build-arg RUNNER_VERSION=2.320.0 -t github-actions-runner:latest .
```

## Troubleshooting

### Runner not appearing in GitHub

1. Check the container logs: `docker-compose logs github-runner`
2. Verify your PAT has the correct scopes
3. Ensure GH_OWNER and GH_REPOSITORY are correct

### Docker commands failing in workflows

1. Ensure Docker socket is mounted
2. Verify the runner user has Docker group permissions
3. Check if the host Docker daemon is running

### Permission denied errors

If you see permission errors, ensure:
1. The runner user has appropriate permissions
2. Volume mounts have correct ownership

## License

This project is open source and available under the MIT License.
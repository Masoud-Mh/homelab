# GitHub Actions Self-Hosted Runner

This Docker container sets up a self-hosted GitHub Actions runner for the homelab repository.

## Setup Instructions

### 1. Generate a Runner Registration Token

1. Go to your repository: https://github.com/Masoud-Mh/homelab
2. Navigate to **Settings > Actions > Runners**
3. Click **New self-hosted runner**
4. Copy the registration token (starts with "GH...")

### 2. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and add:
- `RUNNER_TOKEN`: The registration token from step 1
- `GITHUB_REPO_URL`: Your repository URL (should already be filled)

### 3. Build and Start the Container

```bash
docker compose up -d
```

### 4. Verify the Runner is Connected

Check the container logs:
```bash
docker compose logs -f github-runner
```

You should see output indicating the runner is listening for jobs. Verify in your repository's Actions > Runners page that the new runner appears online.

## Stopping the Runner

```bash
docker compose down
```

## Removing the Runner (Recommended)

Use the provided script to unregister the runner from GitHub and clean up local volumes:

```bash
./remove-runner.sh
```

Before running the script, set `RUNNER_REMOVE_TOKEN` in `.env` to the **remove token** from:
**Repo Settings > Actions > Runners > New self-hosted runner (remove token)**.

Notes:
- Remove tokens expire quickly and are not stored anywhere.
- After removal, get a new registration token and update `RUNNER_TOKEN` in `.env` before starting the runner.
- This follows GitHub’s guidance exactly by explicitly running `./config.sh remove --token ...` inside the container.
- Do not try to auto-remove the runner on container shutdown without a token. That either forces long-term storage of a sensitive token (bad) or fails most of the time. Manual removal is the correct, production-style approach.

## Docker Socket Access

This configuration allows the container to access Docker on the host via `/var/run/docker.sock`. This enables GitHub Actions workflows to build and run Docker containers. Ensure your host has Docker installed and the socket is properly mounted.

## Security Considerations

- Keep your `.env` file private and never commit it to version control
- The `.env.example` file is safe to commit (it contains no secrets)
- Consider using GitHub's official encrypted secrets in your workflows when possible
- The runner token should be regenerated periodically for security

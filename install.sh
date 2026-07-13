#!/usr/bin/env bash
# NOCBox customer one-shot bootstrap (docs/distribution-client.md).
#
# Pulls the deploy bundle FROM the private registry and installs — no tarball to
# transfer. The customer needs only: a GHCR pull user+token (read:packages), the
# image tag, and a license (prompted during install).
#
#   NOCMON_IMAGE_TAG=v0.2.2 NOCBOX_PULL_USER=teamjorian-deploy \
#   NOCBOX_PULL_TOKEN=ghp_xxx bash nocbox-bootstrap.sh
#
# (Or run it bare and answer the prompts.)

set -euo pipefail

# Supported-OS check: Ubuntu Server 22.04 LTS is the only supported OS (24.04
# dropped 2026-07-13). Warn-only — never brick a re-run on an existing box.
# Subshell so /etc/os-release's generic vars (ID, NAME, …) don't leak.
if [[ -r /etc/os-release ]] && \
   ! (. /etc/os-release && [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "22.04" ]]); then
  echo "WARNING: NOCBox supports Ubuntu Server 22.04 LTS only." >&2
  echo "         Detected: $(. /etc/os-release && echo "${PRETTY_NAME:-unknown}") — continuing, but this OS is untested." >&2
fi

DEPLOY_IMAGE="ghcr.io/teamjorian/nocbox-deploy"
# Defaults so a customer normally supplies only NOCBOX_PULL_TOKEN:
#   - tag defaults to `latest` (the newest released version)
#   - pull user defaults to the fixed deploy bot
# Override NOCMON_IMAGE_TAG to pin a specific version (e.g. v0.2.3).
TAG="${NOCMON_IMAGE_TAG:-latest}"
export NOCMON_IMAGE_TAG="$TAG"

# ── 1. Docker (install if missing).
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installing Docker Engine…"
  sudo apt-get update -qq
  sudo apt-get install -y ca-certificates curl gnupg >/dev/null
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
  sudo usermod -aG docker "$USER" || true
  echo "==> Docker installed. Log OUT and back in (for the docker group), then re-run this script."
  exit 0
fi
if ! docker info >/dev/null 2>&1; then
  echo "Can't reach the Docker daemon — log out/in (docker group) and re-run." >&2
  exit 1
fi

# ── 2. Log in to GHCR with the vendor-issued pull credential.
PULL_USER="${NOCBOX_PULL_USER:-teamjorian-deploy}"
PULL_TOKEN="${NOCBOX_PULL_TOKEN:-}"
if [[ -z "$PULL_TOKEN" ]]; then read -r -s -p "License pull token: " PULL_TOKEN; echo; fi
echo "$PULL_TOKEN" | docker login ghcr.io -u "$PULL_USER" --password-stdin

# ── 3. Pull the deploy bundle image + extract it into /opt/nocbox (no source).
echo "==> Fetching deploy bundle ($DEPLOY_IMAGE:$TAG)"
sudo install -d -o "$USER" -g "$USER" /opt/nocbox
docker pull "$DEPLOY_IMAGE:$TAG"
cid="$(docker create "$DEPLOY_IMAGE:$TAG")"
docker cp "$cid:/bundle/." /opt/nocbox/
docker rm "$cid" >/dev/null

# ── 4. Run the installer (pulls the app image, prompts license, brings it up,
#       installs the host-agent from the bundled binary).
cd /opt/nocbox
# Pass creds through (so install-client skips its own login) plus any
# optionally-supplied install values, so the whole thing can run unattended:
#   NOCBOX_LICENSE, NOCBOX_HOSTNAME, NOCMON_ADMIN_EMAIL, NOCMON_ADMIN_PASSWORD.
# Only forward the ones that are actually SET — passing an empty value would
# export it into install-client's environment, and Docker Compose treats a
# set-but-empty shell var as OVERRIDING .env, breaking ${VAR:?} interpolation.
# Anything not forwarded is simply prompted by install-client.
extra=()
[[ -n "${NOCBOX_LICENSE:-}"        ]] && extra+=("NOCBOX_LICENSE=$NOCBOX_LICENSE")
[[ -n "${NOCBOX_HOSTNAME:-}"       ]] && extra+=("NOCBOX_HOSTNAME=$NOCBOX_HOSTNAME")
[[ -n "${NOCMON_ADMIN_EMAIL:-}"    ]] && extra+=("NOCMON_ADMIN_EMAIL=$NOCMON_ADMIN_EMAIL")
[[ -n "${NOCMON_ADMIN_PASSWORD:-}" ]] && extra+=("NOCMON_ADMIN_PASSWORD=$NOCMON_ADMIN_PASSWORD")
env NOCMON_IMAGE_TAG="$TAG" NOCBOX_PULL_USER="$PULL_USER" NOCBOX_PULL_TOKEN="$PULL_TOKEN" \
  ${extra[@]+"${extra[@]}"} \
  bash scripts/install-client.sh

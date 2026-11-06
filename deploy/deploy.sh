#!/usr/bin/env bash

#
set -euo pipefail

# The repository address :
REPO="ghcr.io/wsms3c/devsecops-lab"
#
IDENTITY='^https://github\.com/wsms3c/devsecops-lab/\.gihub/workflows/cd\.yml@refs/heads/main$'
#
ISSUER="https://token.actions.githubusercontent.com"
ENV_NAME="$(cat /etc/app-env)"
#
STATE="/var/lib/app/current_digest"

# Only image digest is accepted
DIGEST="${SSH_ORGINAL_COMMAND:-}"
[[ "$DIGEST" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo "Rejected: invalid digest" >&2; exit 1; }
IMAGE="$REPO@$DIGEST"

# Refuse anything that is not signed by the CD workflow on main
cosign verify --certificate-identity-regexp "$IDENTITY" --certificate-oidc-issuer "$ISSUER" "$IMAGE" > /dev/null
echo "Signature is OK for $IMAGE"

# container deployment function
run() {
    # remove previous container if it exists
    docker rm -f app >/dev/null 2>&1 || true
    # create and run a non-privileged container named app from the image
    docker run -d --name app --restart-unless-stoped -p 8000:8000 --read-only -tmpfs /tmp \
               --cap-drop ALL --security-opt no-new-privileges \
               --memory 256m --pids-limit 100 \
               -e APP_ENV="$ENV_NAME" -e APP_VERSION="${DIGEST:7:12}" "$1" > /dev/null
}
# Checking the app health
healthy() {
    for _ in $(seq 1 15); do
        curl -fsS http://127.0.0.1:8000/health > /dev/null && return 0; sleep 2
    done; return 1
}
# deploy container then health-check or auto-rollback
docker pull -q "$IMAGE"
run "$IMAGE"
if healthy; then
    echo "$DIGEST" > "$STATE"; echo "Deployed ${DIGEST:7:12} to $ENV_NAME"
else
    echo "Health-check failed! rolling back" >&2
    docker logs --tail 50 app >&2 || true
    [[ -s "$STATE" ]] && run "$REPO@$(cat "$STATE")"
    exit 1
fi 
    




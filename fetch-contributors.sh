#!/usr/bin/env bash
# Fetch contributors from every repo of a GitHub account.
# Usage: ./scripts/fetch-contributors.sh <owner> [--output <file>] [--format json|csv|table]
#
# Requires: gh (GitHub CLI), jq
# Examples:
#   ./scripts/fetch-contributors.sh nirholas
#   ./scripts/fetch-contributors.sh nirholas --format csv --output contributors.csv
#   ./scripts/fetch-contributors.sh bnb-chain --format json --output contributors.json

set -euo pipefail

# ── defaults ──────────────────────────────────────────────────────────────────
FORMAT="table"
OUTPUT=""
PER_PAGE=100

usage() {
  cat <<EOF
Usage: $(basename "$0") <owner> [OPTIONS]

Fetch contributors from every public repo of a GitHub account/org.

Options:
  --format <json|csv|table>   Output format (default: table)
  --output <file>             Write output to file instead of stdout
  --include-forks             Include forked repositories
  -h, --help                  Show this help message

Examples:
  $(basename "$0") nirholas
  $(basename "$0") bnb-chain --format csv --output contributors.csv
EOF
  exit 0
}

# ── parse args ────────────────────────────────────────────────────────────────
INCLUDE_FORKS=false

if [[ $# -lt 1 ]]; then
  usage
fi

OWNER="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)       FORMAT="$2"; shift 2 ;;
    --output)       OUTPUT="$2"; shift 2 ;;
    --include-forks) INCLUDE_FORKS=true; shift ;;
    -h|--help)      usage ;;
    *)              echo "Unknown option: $1"; usage ;;
  esac
done

# ── validate deps ─────────────────────────────────────────────────────────────
for cmd in gh jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found on PATH." >&2
    exit 1
  fi
done

# ── fetch repos ───────────────────────────────────────────────────────────────
echo "Fetching repositories for '$OWNER'..." >&2

FORK_FILTER=""
if [[ "$INCLUDE_FORKS" == "false" ]]; then
  FORK_FILTER="| map(select(.fork == false))"
fi

REPOS=$(gh api --paginate "/users/$OWNER/repos?per_page=$PER_PAGE&type=all" \
  --jq ".[]| .full_name" 2>/dev/null || \
  gh api --paginate "/orgs/$OWNER/repos?per_page=$PER_PAGE&type=all" \
  --jq ".[] | .full_name")

if [[ -z "$REPOS" ]]; then
  echo "No repositories found for '$OWNER'." >&2
  exit 1
fi

REPO_COUNT=$(echo "$REPOS" | wc -l)
echo "Found $REPO_COUNT repositories. Fetching contributors..." >&2

# ── fetch contributors per repo ───────────────────────────────────────────────
ALL_CONTRIBUTORS="[]"
CURRENT=0

while IFS= read -r repo; do
  CURRENT=$((CURRENT + 1))
  echo "  [$CURRENT/$REPO_COUNT] $repo" >&2

  # Some repos may return 204 (empty) or 403 (stats not ready); handle gracefully
  CONTRIB=$(gh api --paginate "/repos/$repo/contributors?per_page=$PER_PAGE" 2>/dev/null || echo "[]")

  # Skip if empty or error
  if [[ -z "$CONTRIB" ]] || echo "$CONTRIB" | jq -e 'type != "array"' &>/dev/null 2>&1; then
    echo "    ⚠ Skipped (empty or error)" >&2
    continue
  fi

  # Annotate each contributor with the repo name
  ANNOTATED=$(echo "$CONTRIB" | jq --arg repo "$repo" \
    '[.[] | {repo: $repo, login: .login, contributions: .contributions, avatar_url: .avatar_url, html_url: .html_url, type: .type}]')

  ALL_CONTRIBUTORS=$(echo "$ALL_CONTRIBUTORS" "$ANNOTATED" | jq -s 'add')
done <<< "$REPOS"

TOTAL=$(echo "$ALL_CONTRIBUTORS" | jq 'length')
UNIQUE=$(echo "$ALL_CONTRIBUTORS" | jq '[.[] | .login] | unique | length')
echo "Done. $TOTAL total entries, $UNIQUE unique contributors." >&2

# ── format output ─────────────────────────────────────────────────────────────
format_output() {
  case "$FORMAT" in
    json)
      echo "$ALL_CONTRIBUTORS" | jq '
        group_by(.login)
        | map({
            login: .[0].login,
            avatar_url: .[0].avatar_url,
            html_url: .[0].html_url,
            type: .[0].type,
            total_contributions: (map(.contributions) | add),
            repos: map({repo: .repo, contributions: .contributions})
              | sort_by(-.contributions)
          })
        | sort_by(-.total_contributions)'
      ;;
    csv)
      echo "login,repo,contributions,type,html_url"
      echo "$ALL_CONTRIBUTORS" | jq -r \
        'sort_by(.login, .repo) | .[] | [.login, .repo, .contributions, .type, .html_url] | @csv'
      ;;
    table)
      # Aggregate by contributor, sorted by total contributions
      echo "$ALL_CONTRIBUTORS" | jq -r '
        group_by(.login)
        | map({
            login: .[0].login,
            type: .[0].type,
            total: (map(.contributions) | add),
            repo_count: (map(.repo) | unique | length)
          })
        | sort_by(-.total)
        | .[]
        | [.login, (.total | tostring), (.repo_count | tostring), .type] | @tsv' \
      | (echo -e "CONTRIBUTOR\tCONTRIBUTIONS\tREPOS\tTYPE" && cat) \
      | column -t -s $'\t'
      ;;
    *)
      echo "Unknown format: $FORMAT" >&2
      exit 1
      ;;
  esac
}

if [[ -n "$OUTPUT" ]]; then
  format_output > "$OUTPUT"
  echo "Output written to $OUTPUT" >&2
else
  format_output
fi

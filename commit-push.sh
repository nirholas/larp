#!/usr/bin/env bash
set -euo pipefail

# ─── Your accounts ───────────────────────────────────────────
# Add your GitHub usernames here. The first letter becomes the
# shortcut key (duplicates get the first 2 letters, etc.).
#
#   "username"            → shortcut: first letter
#   "username:shortcut"   → explicit shortcut override
#
ACCOUNTS=(
  "speraxos:s"
  "nirholas:n"
  # ── add more accounts below ──
  # "myaltaccount"
  # "work-handle:w"
  # "bot-account:b"
)

# ─── Cache directory for resolved GitHub IDs ─────────────────
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/commit-push"
mkdir -p "$CACHE_DIR"

# ─── Resolve GitHub noreply email: ID+user@users.noreply.github.com
resolve_email() {
  local username="$1"
  local cache_file="$CACHE_DIR/$username.id"

  # Return cached ID if available
  if [[ -f "$cache_file" ]]; then
    local cached_id
    cached_id=$(<"$cache_file")
    echo "${cached_id}+${username}@users.noreply.github.com"
    return 0
  fi

  # Fetch from GitHub API
  echo "🔍 Looking up GitHub ID for $username..." >&2
  local response
  response=$(curl -sf "https://api.github.com/users/$username" 2>/dev/null) || {
    echo "⚠️  Could not fetch GitHub ID for $username, falling back to username-only email" >&2
    echo "${username}@users.noreply.github.com"
    return 0
  }

  local gh_id
  gh_id=$(echo "$response" | grep '"id"' | head -1 | grep -o '[0-9]\+')

  if [[ -z "$gh_id" ]]; then
    echo "⚠️  Could not parse GitHub ID for $username, falling back" >&2
    echo "${username}@users.noreply.github.com"
    return 0
  fi

  # Cache for next time
  echo "$gh_id" > "$cache_file"
  echo "✅ Resolved $username → ID $gh_id" >&2
  echo "${gh_id}+${username}@users.noreply.github.com"
}

# ─── Build lookup maps from ACCOUNTS array ───────────────────
declare -A SHORTCUT_MAP  # shortcut → username
declare -A NAME_MAP      # full-username → username (identity)

for entry in "${ACCOUNTS[@]}"; do
  # skip blank / commented lines
  [[ -z "$entry" || "$entry" == \#* ]] && continue

  if [[ "$entry" == *:* ]]; then
    username="${entry%%:*}"
    shortcut="${entry#*:}"
  else
    username="$entry"
    shortcut="${entry:0:1}"  # first letter
  fi

  SHORTCUT_MAP["$shortcut"]="$username"
  NAME_MAP["$username"]="$username"
done

# ─── Usage ───────────────────────────────────────────────────
usage() {
  echo "Usage: ./commit-push.sh <identity> [git commit args...]"
  echo ""
  echo "Registered accounts:"
  for entry in "${ACCOUNTS[@]}"; do
    [[ -z "$entry" || "$entry" == \#* ]] && continue
    if [[ "$entry" == *:* ]]; then
      username="${entry%%:*}"
      shortcut="${entry#*:}"
    else
      username="$entry"
      shortcut="${entry:0:1}"
    fi
    printf "  %-4s  %s\n" "$shortcut" "$username"
  done
  cat <<EOF

  @<username>    — any GitHub user (auto-resolves ID)

Examples:
  ./commit-push.sh s -m "✨ new feature"
  ./commit-push.sh n -m "🐛 fix bug"
  ./commit-push.sh @octocat -m "🐙 from octocat"

Flags:
  --no-push      Commit only, skip push
  --clear-cache  Clear cached GitHub IDs and exit
  --list         Show registered accounts
  -h | --help    Show this help
EOF
  exit 0
}

# ─── Parse identity ──────────────────────────────────────────
[[ $# -lt 1 ]] && usage

PUSH=true
INPUT="$1"

case "$INPUT" in
  --clear-cache)
    rm -rf "$CACHE_DIR"
    echo "🗑️  Cache cleared"
    exit 0
    ;;
  --list)
    echo "Registered accounts:"
    for entry in "${ACCOUNTS[@]}"; do
      [[ -z "$entry" || "$entry" == \#* ]] && continue
      if [[ "$entry" == *:* ]]; then
        username="${entry%%:*}"
        shortcut="${entry#*:}"
      else
        username="$entry"
        shortcut="${entry:0:1}"
      fi
      local_cache="$CACHE_DIR/$username.id"
      if [[ -f "$local_cache" ]]; then
        gh_id=$(<"$local_cache")
        printf "  %-4s  %-20s  (ID: %s)\n" "$shortcut" "$username" "$gh_id"
      else
        printf "  %-4s  %-20s  (not yet resolved)\n" "$shortcut" "$username"
      fi
    done
    exit 0
    ;;
  -h|--help)
    usage
    ;;
  @*)
    GIT_NAME="${INPUT#@}"
    GIT_EMAIL=$(resolve_email "$GIT_NAME")
    ;;
  *)
    # Try shortcut first, then full username
    if [[ -n "${SHORTCUT_MAP[$INPUT]+x}" ]]; then
      GIT_NAME="${SHORTCUT_MAP[$INPUT]}"
    elif [[ -n "${NAME_MAP[$INPUT]+x}" ]]; then
      GIT_NAME="$INPUT"
    else
      echo "❌ Unknown identity: $INPUT"
      echo "   Registered shortcuts:"
      for entry in "${ACCOUNTS[@]}"; do
        [[ -z "$entry" || "$entry" == \#* ]] && continue
        if [[ "$entry" == *:* ]]; then
          printf "     %-4s → %s\n" "${entry#*:}" "${entry%%:*}"
        else
          printf "     %-4s → %s\n" "${entry:0:1}" "$entry"
        fi
      done
      echo "   Or use @username for any GitHub user"
      exit 1
    fi
    GIT_EMAIL=$(resolve_email "$GIT_NAME")
    ;;
esac
shift

# ─── Extract --no-push flag ──────────────────────────────────
COMMIT_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--no-push" ]]; then
    PUSH=false
  else
    COMMIT_ARGS+=("$arg")
  fi
done

# ─── Validate ────────────────────────────────────────────────
if [[ ${#COMMIT_ARGS[@]} -eq 0 ]]; then
  echo "❌ No commit arguments provided. Use -m \"message\" at minimum."
  exit 1
fi

# ─── Commit ──────────────────────────────────────────────────
echo "👤 Committing as: $GIT_NAME <$GIT_EMAIL>"
GIT_AUTHOR_NAME="$GIT_NAME" \
GIT_AUTHOR_EMAIL="$GIT_EMAIL" \
GIT_COMMITTER_NAME="$GIT_NAME" \
GIT_COMMITTER_EMAIL="$GIT_EMAIL" \
git commit "${COMMIT_ARGS[@]}"

echo "✅ Committed as $GIT_NAME"

# ─── Push ────────────────────────────────────────────────────
if $PUSH; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "🚀 Pushing to origin/$BRANCH..."
  git push origin "$BRANCH"
  echo "✅ Pushed successfully"
else
  echo "⏭️  Skipped push (--no-push)"
fi

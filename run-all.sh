#!/usr/bin/env bash
set -euo pipefail

SHORTCUTS=(
  s n ap 2p al di is a2 ts a1 ta bn ch ku jz ll ac c2 tb dh se
  ma ni tc ss el na pe by fa jc la le ph ra ur vg 2c aa ag bl bo
  cl da dv eo ig jm mm nl so zy az ad aj am ba bb be bm cd cq cr
  fc ge sc jf je jo jb ju ka ks ly li ln mk mj nu pp pg qi qu rm
  ro sj sz tr vn wd yr
)

for shortcut in "${SHORTCUTS[@]}"; do
  # Create a unique change
  echo "Committed by: $shortcut — $(date -u +%Y-%m-%dT%H:%M:%S)" >> contributions.log
  git add -A
  ./commit-push.sh "$shortcut" -m "🤝 Contribution from $shortcut" || echo "⚠️  Failed for $shortcut, continuing..."
  sleep 1
done

echo "✅ All done!"

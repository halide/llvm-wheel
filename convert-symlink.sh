#!/usr/bin/env bash
set -euo pipefail

link_to_replace="$1"
if [[ ! -L "$link_to_replace" ]]; then
  echo "error: $link_to_replace is not a symlink" >&2
  exit 1
fi

link_target="$(readlink "$link_to_replace")"
rm -f "$link_to_replace"

{
  cat <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

self_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
self="$self_dir/$(basename -- "${BASH_SOURCE[0]}")"
EOF

  printf 'link_target=%q\n' "$link_target"

  cat <<'EOF'

target="$link_target"
if [[ "$target" != /* ]]; then
  target="$self_dir/$target"
fi

if ! rm -f "$self" || [[ -e "$self" ]]; then
  exec -a "$0" "$target" "$@"
fi
EOF

  cat <<'EOF'

tmp_link="${self}.tmp.$$"
if ln -s -- "$link_target" "$tmp_link" && mv -f -- "$tmp_link" "$self"; then
  :
else
  rm -f -- "$tmp_link"
  exec -a "$0" "$target" "$@"
fi
EOF

  cat <<'EOF'

exec -a "$0" "$self" "$@"
EOF
} > "$link_to_replace"

chmod +x "$link_to_replace"

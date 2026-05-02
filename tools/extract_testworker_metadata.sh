#!/usr/bin/env bash
set -euo pipefail

BIN="${1:?usage: extract_testworker_metadata.sh <testworker_group_bin>}"

ENTRY="$(nm -n "$BIN" | awk '/ verse_recovery_entry$/ {print "0x"$1; exit}')"
STACK="0x53a000"
IPC="0x53c000"

if [ -z "$ENTRY" ]; then
  echo "FAIL: verse_recovery_entry not found" >&2
  exit 1
fi

cat > generated_tcb_metadata.cmake <<EOF
add_compile_definitions(VERSE_WORKER_IPC_BUFFER_ADDR=${IPC})
add_compile_definitions(VERSE_WORKER_ENTRY_IP=${ENTRY})
add_compile_definitions(VERSE_WORKER_STACK_TOP=${STACK})
add_compile_definitions(VERSE_WORKER_PRIORITY=254)
add_compile_definitions(VERSE_WORKER_MAX_PRIORITY=254)
EOF

echo "WROTE generated_tcb_metadata.cmake"
cat generated_tcb_metadata.cmake

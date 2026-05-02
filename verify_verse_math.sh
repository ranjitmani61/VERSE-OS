#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
TLA_JAR="$ROOT/tools/tla/tla2tools.jar"
OUT="$ROOT/verification_run_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"

pass() { echo "PASS: $*" | tee -a "$OUT/summary.txt"; }
fail() { echo "FAIL: $*" | tee -a "$OUT/summary.txt"; exit 1; }
warn() { echo "WARN: $*" | tee -a "$OUT/summary.txt"; }

need_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

run_tlc_expect_pass() {
  local name="$1"
  local spec="$2"
  local cfg="$3"
  local extra="${4:-}"

  need_file "$spec"
  need_file "$cfg"

  echo "=== TLC $name ===" | tee "$OUT/${name}.log"
  if java -XX:+UseParallelGC -Xmx4g -cp "$TLA_JAR" tlc2.TLC \
      $extra \
      -workers 1 \
      -metadir "$OUT/${name}_states" \
      "$spec" \
      -config "$cfg" 2>&1 | tee -a "$OUT/${name}.log"; then
    if grep -q "Model checking completed. No error has been found." "$OUT/${name}.log"; then
      pass "TLA $name"
    else
      fail "TLA $name did not report clean success"
    fi
  else
    fail "TLA $name crashed or returned nonzero"
  fi
}

run_tlc_expect_fail() {
  local name="$1"
  local spec="$2"
  local cfg="$3"
  local extra="${4:-}"

  need_file "$spec"
  need_file "$cfg"

  echo "=== TLC EXPECT FAIL $name ===" | tee "$OUT/${name}.log"
  set +e
  java -XX:+UseParallelGC -Xmx4g -cp "$TLA_JAR" tlc2.TLC \
    $extra \
    -workers 1 \
    -metadir "$OUT/${name}_states" \
    "$spec" \
    -config "$cfg" 2>&1 | tee -a "$OUT/${name}.log"
  local rc=$?
  set -e

  if grep -Eq "Error:|Temporal properties were violated|Deadlock reached" "$OUT/${name}.log"; then
    pass "Expected failing model still fails: $name"
  else
    fail "Expected failing model unexpectedly passed or produced no failure marker: $name"
  fi
}

echo "VERSE OS strict verification run: $OUT"
echo "Root: $ROOT" | tee "$OUT/summary.txt"

need_cmd java
need_file "$TLA_JAR"

echo
echo "=== 1. TLA+ scoped model checks ==="

# These are the current scoped mathematical checks.
# If any fails, the corresponding formal claim is false.

run_tlc_expect_pass \
  "sentinel_lattice_safety" \
  "$ROOT/src/specs/Sentinel_Lattice.tla" \
  "$ROOT/src/specs/Sentinel_Lattice.cfg" \
  "-deadlock"

run_tlc_expect_pass \
  "cortexmm_capability_safety" \
  "$ROOT/src/specs/CortexMM_Capability.tla" \
  "$ROOT/src/specs/CortexMM_Capability.cfg"

run_tlc_expect_pass \
  "dharmanet_budget_monitor" \
  "$ROOT/src/specs/DharmaNet_Budget.tla" \
  "$ROOT/src/specs/DharmaNet_Budget.cfg"

# Runtime-faithful CodexFS XOR model.
# These are valid only if these cfg files exist in your current tree.
if [[ -f "$ROOT/src/specs/CodexFS_Runtime_XOR.tla" ]]; then
  run_tlc_expect_pass \
    "codexfs_runtime_xor_type" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR.tla" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR_type.cfg"

  run_tlc_expect_pass \
    "codexfs_runtime_xor_deadlock" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR.tla" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR_deadlock.cfg"

  run_tlc_expect_pass \
    "codexfs_runtime_xor_goodchain" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR.tla" \
    "$ROOT/src/specs/CodexFS_Runtime_XOR_goodchain.cfg"
else
  warn "CodexFS_Runtime_XOR.tla not found; cannot verify runtime-faithful CodexFS XOR model"
fi

# Recovery models, if present.
if [[ -f "$ROOT/src/specs/Recovery_Task_type.cfg" ]]; then
  run_tlc_expect_pass \
    "recovery_task_type" \
    "$ROOT/src/specs/Recovery_Task.tla" \
    "$ROOT/src/specs/Recovery_Task_type.cfg"
else
  warn "Recovery_Task_type.cfg not found"
fi

if [[ -f "$ROOT/src/specs/Recovery_Task_deadlock.cfg" ]]; then
  run_tlc_expect_pass \
    "recovery_task_deadlock" \
    "$ROOT/src/specs/Recovery_Task.tla" \
    "$ROOT/src/specs/Recovery_Task_deadlock.cfg"
else
  warn "Recovery_Task_deadlock.cfg not found"
fi

if [[ -f "$ROOT/src/specs/Recovery_Task_tcb_type.cfg" ]]; then
  run_tlc_expect_pass \
    "recovery_task_tcb_type" \
    "$ROOT/src/specs/Recovery_Task.tla" \
    "$ROOT/src/specs/Recovery_Task_tcb_type.cfg"
else
  warn "Recovery_Task_tcb_type.cfg not found"
fi

if [[ -f "$ROOT/src/specs/Recovery_Task_tcb_deadlock.cfg" ]]; then
  run_tlc_expect_pass \
    "recovery_task_tcb_deadlock" \
    "$ROOT/src/specs/Recovery_Task.tla" \
    "$ROOT/src/specs/Recovery_Task_tcb_deadlock.cfg"
else
  warn "Recovery_Task_tcb_deadlock.cfg not found"
fi

echo
echo "=== 2. Known-broken / non-release CodexFS v19.5 check ==="

# This should NOT be used as a passing release proof until fixed.
# The strict suite fails if v19.5 unexpectedly passes without review,
# because that means the claim table must be updated manually.
if [[ -f "$ROOT/CodexFS_Monotonic_v19_5.tla" && -f "$ROOT/CodexFS_Monotonic_v19_5.cfg" ]]; then
  run_tlc_expect_fail \
    "codexfs_v19_5_expected_broken" \
    "$ROOT/CodexFS_Monotonic_v19_5.tla" \
    "$ROOT/CodexFS_Monotonic_v19_5.cfg"
else
  warn "Top-level CodexFS v19.5 pair not found"
fi

echo
echo "=== 3. Static CAmkES capability graph audit ==="

if [[ -f "$ROOT/tools/capability_audit.py" ]]; then
  python3 "$ROOT/tools/capability_audit.py" "$ROOT/src/apps/verse_unified/verse_unified.camkes" \
    2>&1 | tee "$OUT/capability_audit.log"

  grep -Eq "CAPABILITY_AUDIT_OK|AUDIT_OK" "$OUT/capability_audit.log" \
    && pass "static CAmkES capability audit" \
    || fail "static CAmkES capability audit did not pass"
else
  warn "tools/capability_audit.py missing"
fi

if [[ -f "$ROOT/src/tools/audit_caps.py" ]]; then
  python3 "$ROOT/src/tools/audit_caps.py" "$ROOT/src/apps/verse_unified" \
    2>&1 | tee "$OUT/src_audit_caps.log"

  grep -Eq "CAPABILITY_AUDIT_OK|AUDIT_OK" "$OUT/src_audit_caps.log" \
    && pass "src/tools/audit_caps.py audit" \
    || fail "src/tools/audit_caps.py audit did not pass"
else
  warn "src/tools/audit_caps.py missing"
fi

echo
echo "=== 4. TCB handoff evidence checks ==="

# These checks do not prove runtime by themselves.
# They verify that evidence files contain the markers required for the TCB claim.

for f in \
  TCB_HANDOFF_IMAGE_BUILD_EVIDENCE.md \
  TCB_SUSPEND_RUNTIME_EVIDENCE.md \
  TCB_RECOVERY_PASS_MARKER_EVIDENCE.md \
  TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md \
  TCB_CRITIC_CLEANUP_AUDIT.md
do
  if [[ -f "$ROOT/$f" ]]; then
    pass "found $f"
  else
    warn "missing $f"
  fi
done

if [[ -f "$ROOT/TCB_HANDOFF_IMAGE_BUILD_EVIDENCE.md" ]]; then
  grep -q "TCB_HANDOFF_IMAGE_V2_BUILD_OK" "$ROOT/TCB_HANDOFF_IMAGE_BUILD_EVIDENCE.md" \
    && pass "TCB handoff image build marker" \
    || fail "missing TCB handoff image build marker"
fi

if [[ -f "$ROOT/TCB_SUSPEND_RUNTIME_EVIDENCE.md" ]]; then
  grep -q "seL4_TCB_Suspend(worker_tcb) OK" "$ROOT/TCB_SUSPEND_RUNTIME_EVIDENCE.md" \
    && pass "runtime seL4_TCB_Suspend marker" \
    || fail "missing runtime seL4_TCB_Suspend marker"
fi

if [[ -f "$ROOT/TCB_RECOVERY_PASS_MARKER_EVIDENCE.md" ]]; then
  grep -q "VERSE_RECOVERY_PASS" "$ROOT/TCB_RECOVERY_PASS_MARKER_EVIDENCE.md" \
    && pass "single TCB recovery PASS marker" \
    || fail "missing VERSE_RECOVERY_PASS marker"
fi

if [[ -f "$ROOT/TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md" ]]; then
  grep -q "VERSE_RECOVERY_PASS_1" "$ROOT/TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md"
  grep -q "VERSE_RECOVERY_PASS_2" "$ROOT/TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md"
  grep -q "VERSE_RECOVERY_PASS_3" "$ROOT/TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md"
  grep -q "ProcMan: QUARANTINE" "$ROOT/TCB_REPEATED_RECOVERY_SPARE_POOL_EVIDENCE.md"
  pass "three bounded TCB recovery markers plus quarantine"
fi

echo
echo "=== 5. Runtime smoke log checks ==="

LATEST_LOG="$(ls -1t "$ROOT"/run_logs/*.log 2>/dev/null | head -n 1 || true)"
if [[ -z "$LATEST_LOG" ]]; then
  warn "no run_logs/*.log found"
else
  echo "Checking latest runtime log: $LATEST_LOG" | tee "$OUT/runtime_log_check.log"

  for marker in \
    "Booting all finished, dropped to user space" \
    "CORTEX: ok" \
    "CODEX: ok" \
    "S: FORWARD" \
    "WRITER: done" \
    "READER: ok" \
    "WDOG: active monitoring" \
    "WDOG: heartbeat lost" \
    "ProcMan: restart attempt" \
    "WDOG: heartbeat resumed"
  do
    if grep -q "$marker" "$LATEST_LOG"; then
      pass "runtime marker: $marker"
    else
      warn "runtime marker missing from latest log: $marker"
    fi
  done
fi

echo
echo "=== 6. Source-level anti-overclaim checks ==="

# CodexFS must not be called cryptographic while runtime is XOR.
if grep -RIn "static unsigned char cs\|s\^=d\[i\]\|b->h=cs" \
  "$ROOT/src/apps/verse_unified/components/CodexFS/src/codexfs.c" \
  > "$OUT/codexfs_xor_source.log" 2>/dev/null; then
  pass "CodexFS runtime source uses XOR/checksum shape"
else
  warn "CodexFS XOR/checksum source markers not found; inspect implementation manually"
fi

if grep -RIn "SHA\|sha\|crypto\|Merkle\|TPM\|ROM" \
  "$ROOT/src/apps/verse_unified/components/CodexFS/src/codexfs.c" \
  > "$OUT/codexfs_crypto_source.log" 2>/dev/null; then
  warn "CodexFS source contains crypto-like terms; inspect whether implementation changed"
else
  pass "No runtime cryptographic implementation markers found in CodexFS source"
fi

# DharmaNet must not be called scheduler enforcement without scheduler syscalls.
if grep -RIn "seL4_SchedControl\|SchedContext\|seL4_TCB_SetSchedParams" \
  "$ROOT/src/apps/verse_unified/components/DharmaNet" \
  "$ROOT/src/apps/verse_unified/components/ProcMan" \
  > "$OUT/scheduler_enforcement_source.log" 2>/dev/null; then
  warn "scheduler-control markers found; inspect whether enforcement is real"
else
  pass "No scheduler enforcement syscall markers found; DharmaNet is monitoring-only"
fi

echo
echo "=== 7. Strong-claim lint ==="

# This does not fail automatically; it reports dangerous language.
# Any line here needs evidence binding or wording downgrade.

CLAIM_FILES=(
  "$ROOT/real-architecture.md"
  "$ROOT/architecture.md"
  "$ROOT/VERSE_OS_VERIFICATION_REPORT.md"
  "$ROOT/FORMAL_METHODS_REPORT.md"
  "$ROOT/THREAT_MODEL.md"
  "$ROOT/SUPPORT_STATUS.md"
  "$ROOT/CLAIM_AUDIT.md"
)

{
  for f in "${CLAIM_FILES[@]}"; do
    [[ -f "$f" ]] && grep -nEi \
      "formally verified|mathematically proven|proven|self-healing|cryptographic|guaranteed|impossible|production-ready|scheduler enforcement|TCB restart|secure" \
      "$f" || true
  done
} | tee "$OUT/strong_claim_lint.log"

warn "Strong-claim lint written to $OUT/strong_claim_lint.log. Manually downgrade unsupported claims."

echo
echo "=== FINAL CLASSIFICATION ==="

cat <<CLASSIFY | tee -a "$OUT/summary.txt"

SUPPORTED IF ABOVE PASSED:
- Buildable / bootable seL4-CAmkES prototype, if build/runtime logs are current.
- Scoped bounded TLA+ checks for Sentinel, CortexMM, DharmaNet.
- Runtime-faithful bounded CodexFS XOR checksum-chain model, if CodexFS_Runtime_XOR checks passed.
- Static CAmkES capability graph audit, if audit tools passed.
- Bounded runtime TCB recovery evidence, if TCB markers are present.

NOT SUPPORTED BY THIS SUITE:
- Whole-OS mathematical proof.
- TLAPS/unbounded theorem proof.
- Cryptographic CodexFS.
- Persistent storage integrity.
- Full scheduler enforcement.
- Resource leak freedom after repeated TCB respawn.
- Old TCB revoke/delete proof.
- Side-channel freedom.
- Production-ready security.
CLASSIFY

echo
echo "Verification output saved in: $OUT"

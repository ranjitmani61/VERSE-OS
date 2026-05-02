# Negative Test: Missing TCB Metadata

Date: 2026-05-02

## Verdict

The missing-metadata negative test is deterministic and passing. With
`VERSE_TCB_ENFORCED=ON` and `VERSE_NEGATIVE_MISSING_METADATA=ON`, the build
fails on the existing compile-time guard.

## Test Script

```text
tools/negative_missing_metadata.sh
```

The script saves logs under:

```text
out/negative_tests/missing_metadata/
```

## Expected Failure Marker

```text
VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top
```

## Actual Result

Result log:

```text
out/negative_tests/missing_metadata/result.log
```

Observed:

```text
PASS: missing metadata build failed on expected compile-time guard
MARKER: VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top
LOG: /home/king/verse_os/out/negative_tests/missing_metadata/build.log
```

Build log marker:

```text
371:/tmp/camkes/projects/camkes/apps/verse_unified/components/ProcMan/src/procman.c:90:2: error: #error "VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top"
372:   90 | #error "VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top"
```

## Default Normal Regression Check

The negative option defaults to `OFF`. A default normal enforced build still
boots and recovers.

Build log:

```text
out/negative_tests/missing_metadata/default_normal/build.log
```

Boot log:

```text
out/negative_tests/missing_metadata/default_normal/boot.log
```

Observed grep:

```text
71:ProcMan: restart attempt 1/3
83:VERSE_RECOVERY_PASS_1
84:WDOG: heartbeat resumed, re-armed and monitoring
85:DHARMA: OK after recovery
174:SIMULATE_EXIT:124
```

Negative grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/negative_tests/missing_metadata/default_normal/boot.log
```

Observed result: no matches.

## Not Proven

- Other negative tests are not covered by this document.
- Clean QEMU shutdown is not proven.
- RWX kernel LOAD segment status is not proven by this document.

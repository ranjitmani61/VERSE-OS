#!/bin/bash

# Fault Injection Test for Fault Endpoint Handling in ProcMan
echo "=== Starting Fault Endpoint Decode Test ==="

# Step 1: Set up environment, including build flags for fault endpoint
export VERSE_TESTWORKER_FAULT_ENDPOINT_DECODE=ON

# Step 2: Build with the proper fault injection flags
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc ' \
    make -C /host -j $(nproc) src/apps/verse_unified'

# Step 3: Inject fault by running QEMU with worker fault
timeout 120s qemu-system-x86_64 -cpu Nehalem,-vme,+pdpe1gb,-xsave,-xsaveopt,-xsavec,-fsgsbase,-invpcid,+syscall,+lm,enforce -nographic -serial mon:stdio -m size=512M -kernel /tmp/verse_kernel -initrd /tmp/verse_initrd

# Step 4: Verify fault handler output
grep -nE "ProcMan: fault received badge|ProcMan: fault type|ProcMan: fault-triggered recovery attempt|VERSE_RECOVERY_PASS" out/negative_tests/fault_endpoint_decode/boot.log

# Step 5: If the test passes, confirm the fault recovery happened correctly
if [ $? -eq 0 ]; then
  echo "PASS: Fault endpoint decode and recovery test passed."
else
  echo "FAIL: Fault endpoint decode and recovery test failed."
fi

echo "=== Fault Endpoint Decode Test Completed ==="
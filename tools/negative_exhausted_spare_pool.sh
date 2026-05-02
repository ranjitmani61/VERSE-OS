#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${repo_root}/out/negative_tests/exhausted_spare_pool"
build_log="${out_dir}/build.log"
boot_log="${out_dir}/boot.log"
result_log="${out_dir}/result.log"

mkdir -p "${out_dir}"

set -o pipefail
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
rm -rf /tmp/camkes/projects/camkes/apps/verse_unified
cp -a /host/src/apps/verse_unified /tmp/camkes/projects/camkes/apps/verse_unified
cd /tmp/camkes
rm -rf build_negative_exhausted_spare_pool
mkdir build_negative_exhausted_spare_pool
cd build_negative_exhausted_spare_pool
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON -DVERSE_TESTWORKER_REPEAT_DEADLOCK=ON
ninja
python3 /host/tools/inject_tcb_handoff.py verse_unified.cdl verse_unified_tcb_handoff.cdl
cp verse_unified_tcb_handoff.cdl verse_unified.cdl
ninja images/capdl-loader-image-x86_64-pc99
mkdir -p /host/out/negative_tests/exhausted_spare_pool
cp images/kernel-x86_64-pc99 /host/out/negative_tests/exhausted_spare_pool/kernel-x86_64-pc99
cp images/capdl-loader-image-x86_64-pc99 /host/out/negative_tests/exhausted_spare_pool/capdl-loader-image-x86_64-pc99
echo NEGATIVE_EXHAUSTED_SPARE_POOL_BUILD_OK
' >"${build_log}" 2>&1

set +e
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
cp /host/out/negative_tests/exhausted_spare_pool/kernel-x86_64-pc99 /tmp/verse_kernel
cp /host/out/negative_tests/exhausted_spare_pool/capdl-loader-image-x86_64-pc99 /tmp/verse_initrd
set +e
timeout 75s qemu-system-x86_64 -cpu Nehalem,-vme,+pdpe1gb,-xsave,-xsaveopt,-xsavec,-fsgsbase,-invpcid,+syscall,+lm,enforce -nographic -serial mon:stdio -m size=512M -kernel /tmp/verse_kernel -initrd /tmp/verse_initrd
qemu_status=$?
echo SIMULATE_EXIT:${qemu_status}
if [ "${qemu_status}" -ne 0 ] && [ "${qemu_status}" -ne 124 ]; then exit "${qemu_status}"; fi
' >"${boot_log}" 2>&1
boot_status=$?
set -e

if [ "${boot_status}" -ne 0 ]; then
    {
        echo "FAIL: exhausted spare pool boot command failed with status ${boot_status}"
        echo "LOG: ${boot_log}"
    } | tee "${result_log}"
    exit 1
fi

missing=0
for expected in \
    "VERSE_RECOVERY_PASS_1" \
    "VERSE_RECOVERY_PASS_2" \
    "VERSE_RECOVERY_PASS_3" \
    "ProcMan: QUARANTINE"
do
    if ! grep -q "${expected}" "${boot_log}"; then
        echo "MISSING: ${expected}" >>"${result_log}"
        missing=1
    fi
done

if grep -qE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" "${boot_log}"; then
    echo "FAIL: exhausted spare pool boot contained fault/error marker" >"${result_log}"
    echo "LOG: ${boot_log}" >>"${result_log}"
    exit 1
fi

if [ "${missing}" -ne 0 ]; then
    {
        echo "FAIL: exhausted spare pool boot missed expected marker"
        echo "LOG: ${boot_log}"
    } >>"${result_log}"
    exit 1
fi

{
    echo "PASS: exhausted spare pool hit three recovery passes and quarantine"
    echo "MARKER: VERSE_RECOVERY_PASS_1"
    echo "MARKER: VERSE_RECOVERY_PASS_2"
    echo "MARKER: VERSE_RECOVERY_PASS_3"
    echo "MARKER: ProcMan: QUARANTINE"
    echo "LOG: ${boot_log}"
} | tee "${result_log}"

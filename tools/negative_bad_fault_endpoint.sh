#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${repo_root}/out/negative_tests/bad_fault_endpoint"
build_log="${out_dir}/build.log"
boot_log="${out_dir}/boot.log"
result_log="${out_dir}/result.log"
expected='Caught cap fault in send phase at address 0x108'
metadata_expected='fresh metadata RIP=0x1'

mkdir -p "${out_dir}"

set -o pipefail
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
rm -rf /tmp/camkes/projects/camkes/apps/verse_unified
cp -a /host/src/apps/verse_unified /tmp/camkes/projects/camkes/apps/verse_unified
cd /tmp/camkes
rm -rf build_negative_bad_fault_endpoint
mkdir build_negative_bad_fault_endpoint
cd build_negative_bad_fault_endpoint
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON -DVERSE_NEGATIVE_BAD_FAULT_ENDPOINT=ON
ninja
python3 /host/tools/inject_tcb_handoff.py verse_unified.cdl verse_unified_tcb_handoff.cdl
cp verse_unified_tcb_handoff.cdl verse_unified.cdl
ninja images/capdl-loader-image-x86_64-pc99
mkdir -p /host/out/negative_tests/bad_fault_endpoint
cp images/kernel-x86_64-pc99 /host/out/negative_tests/bad_fault_endpoint/kernel-x86_64-pc99
cp images/capdl-loader-image-x86_64-pc99 /host/out/negative_tests/bad_fault_endpoint/capdl-loader-image-x86_64-pc99
echo NEGATIVE_BAD_FAULT_ENDPOINT_BUILD_OK
' >"${build_log}" 2>&1

set +e
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
cp /host/out/negative_tests/bad_fault_endpoint/kernel-x86_64-pc99 /tmp/verse_kernel
cp /host/out/negative_tests/bad_fault_endpoint/capdl-loader-image-x86_64-pc99 /tmp/verse_initrd
set +e
timeout 60s qemu-system-x86_64 -cpu Nehalem,-vme,+pdpe1gb,-xsave,-xsaveopt,-xsavec,-fsgsbase,-invpcid,+syscall,+lm,enforce -nographic -serial mon:stdio -m size=512M -kernel /tmp/verse_kernel -initrd /tmp/verse_initrd
qemu_status=$?
echo SIMULATE_EXIT:${qemu_status}
if [ "${qemu_status}" -ne 0 ] && [ "${qemu_status}" -ne 124 ]; then exit "${qemu_status}"; fi
' >"${boot_log}" 2>&1
boot_status=$?
set -e

if [ "${boot_status}" -ne 0 ]; then
    {
        echo "FAIL: bad fault endpoint boot command failed with status ${boot_status}"
        echo "LOG: ${boot_log}"
    } | tee "${result_log}"
    exit 1
fi

if grep -q "${expected}" "${boot_log}" && grep -q "${metadata_expected}" "${boot_log}"; then
    {
        echo "PASS: bad fault endpoint boot produced expected fault marker"
        echo "MARKER: ${expected}"
        echo "METADATA: ${metadata_expected}"
        echo "LOG: ${boot_log}"
    } | tee "${result_log}"
    exit 0
fi

{
    echo "FAIL: bad fault endpoint boot did not produce expected marker"
    echo "EXPECTED: ${expected}"
    echo "EXPECTED_METADATA: ${metadata_expected}"
    echo "LOG: ${boot_log}"
} | tee "${result_log}"
exit 1

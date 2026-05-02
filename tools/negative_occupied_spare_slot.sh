#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${repo_root}/out/negative_tests/occupied_spare_slot"
build_log="${out_dir}/build.log"
inject_log="${out_dir}/injector.log"
result_log="${out_dir}/result.log"
expected='FAIL: procman_cnode already has slot 0x104:'

mkdir -p "${out_dir}"

set -o pipefail
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
rm -rf /tmp/camkes/projects/camkes/apps/verse_unified
cp -a /host/src/apps/verse_unified /tmp/camkes/projects/camkes/apps/verse_unified
cd /tmp/camkes
rm -rf build_negative_occupied_spare_slot
mkdir build_negative_occupied_spare_slot
cd build_negative_occupied_spare_slot
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON
ninja
mkdir -p /host/out/negative_tests/occupied_spare_slot
cp verse_unified.cdl /host/out/negative_tests/occupied_spare_slot/verse_unified.cdl
echo NEGATIVE_OCCUPIED_SPARE_SLOT_BUILD_OK
' >"${build_log}" 2>&1

awk '
    /^[[:space:]]*procman_cnode[[:space:]]*\{[[:space:]]*$/ && !inserted {
        print
        print "    0x104: testworker_fault_ep (R)"
        inserted=1
        next
    }
    { print }
    END {
        if (!inserted) {
            exit 7
        }
    }
' "${out_dir}/verse_unified.cdl" >"${out_dir}/verse_unified_occupied_spare.cdl"

set +e
python3 "${repo_root}/tools/inject_tcb_handoff.py" \
    "${out_dir}/verse_unified_occupied_spare.cdl" \
    "${out_dir}/should_not_be_written.cdl" \
    >"${inject_log}" 2>&1
inject_status=$?
set -e

if [ "${inject_status}" -eq 0 ]; then
    {
        echo "FAIL: injector accepted occupied spare slot"
        echo "LOG: ${inject_log}"
    } | tee "${result_log}"
    exit 1
fi

if grep -q "${expected}" "${inject_log}"; then
    {
        echo "PASS: injector rejected occupied spare slot before boot"
        echo "MARKER: ${expected}"
        echo "LOG: ${inject_log}"
    } | tee "${result_log}"
    exit 0
fi

{
    echo "FAIL: injector did not report expected occupied slot marker"
    echo "EXPECTED: ${expected}"
    echo "LOG: ${inject_log}"
} | tee "${result_log}"
exit 1

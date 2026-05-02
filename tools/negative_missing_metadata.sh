#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${repo_root}/out/negative_tests/missing_metadata"
build_log="${out_dir}/build.log"
result_log="${out_dir}/result.log"
expected='VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top'

mkdir -p "${out_dir}"

set +e
timeout 120s docker run --rm -v "${repo_root}:/host" user_img-king bash -lc '
set -e
rm -rf /tmp/camkes/projects/camkes/apps/verse_unified
cp -a /host/src/apps/verse_unified /tmp/camkes/projects/camkes/apps/verse_unified
cd /tmp/camkes
rm -rf build_negative_missing_metadata
mkdir build_negative_missing_metadata
cd build_negative_missing_metadata
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON -DVERSE_NEGATIVE_MISSING_METADATA=ON
ninja
' >"${build_log}" 2>&1
status=$?
set -e

if [ "${status}" -eq 0 ]; then
    {
        echo "FAIL: missing metadata build unexpectedly succeeded"
        echo "LOG: ${build_log}"
    } | tee "${result_log}"
    exit 1
fi

if grep -q "${expected}" "${build_log}"; then
    {
        echo "PASS: missing metadata build failed on expected compile-time guard"
        echo "MARKER: ${expected}"
        echo "LOG: ${build_log}"
    } | tee "${result_log}"
    exit 0
fi

{
    echo "FAIL: missing metadata build failed without expected marker"
    echo "EXPECTED: ${expected}"
    echo "LOG: ${build_log}"
} | tee "${result_log}"
exit 1

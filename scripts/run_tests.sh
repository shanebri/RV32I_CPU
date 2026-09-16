#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
for bench in tb/tb_*.sv; do
    name="$(basename "$bench" .sv)"
    verilator --binary --timing -Wno-fatal --top-module "$name" \
        --Mdir "build/$name" -j 2 rtl/*.sv "$bench" >"build/$name-build.log" 2>&1
    "build/$name/V$name" >"build/$name.log" 2>&1
    if ! grep -q 'ALL .* TESTS PASSED' "build/$name.log"; then
        cat "build/$name.log"
        exit 1
    fi
    echo "$name: PASS"
done

#!/usr/bin/env bash
set -euo pipefail

EXE="./pcc/build/example/multiple_encode"
ROOT="compressed"
ERRORS=(1 2 3 5 9)
JOBS=$(nproc)

mkdir -p "${ROOT}"

run_encode() {
    local ct=$1
    local err=$2
    local r_label=$3
    local seg=$4

    local start=$(( (seg - 1) * 30 ))
    local end=$(( seg * 30 - 1 ))

    local input_files=""
    for frame in $(seq ${start} ${end}); do
        input_files+=" ./${ct}$(printf "%04d" ${frame}).ply"
    done

    if [[ $seg -eq 1 ]]; then
        out="${ROOT}/0.init.r${r_label}.bin"
    else
        out="${ROOT}/0.seg$(printf "%05d" $((seg-1))).r${r_label}.bin"
    fi

    ${EXE} "${err}" "${out}" ${input_files}
}

for ct in "$@"; do
    for idx in "${!ERRORS[@]}"; do
        err=${ERRORS[$idx]}
        r_label=$idx   # start from 0

        for seg in {1..10}; do
            run_encode "$ct" "$err" "$r_label" "$seg" &
            if [[ $(jobs -r -p | wc -l) -ge $JOBS ]]; then
                wait -n
            fi
        done
    done
done
wait

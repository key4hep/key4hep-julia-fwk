#!/bin/bash
WORKFLOW="$(dirname $0)/../data/ATLAS/q449/df.graphml"
REPEAT=2
AFFINITY=0
THREADS_SEQ="2 4"

THREADS_PER_SLOT=2
EVENTS_PER_SLOT=2

PROJECT="$(dirname $0)/.."
EXEC="$(dirname $0)/../bin/schedule.jl"

for threads in ${THREADS_SEQ}; do
    concurrent=$((threads/THREADS_PER_SLOT))
    total=$((concurrent*EVENTS_PER_SLOT))
    output_file="timing_${threads}.csv"
    echo "Starting measurements for ${threads} threads, ${total} total events," \
        "${concurrent} concurrent events"
    CMD=(
      numactl --cpunodebind="${AFFINITY}" --membind="${AFFINITY}" julia -t "${threads}"
      --project="${PROJECT}" "${EXEC}" "${WORKFLOW}" --disable-logging=warn
      --max-concurrent="${concurrent}" --event-count="${total}"
      --warmup-count="${total}" --trials="${REPEAT}" --save-timing="${output_file}"
    )
    CMD=${CMD[*]}
    echo "Running command: ${CMD}"
    $CMD
done

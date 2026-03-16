#!/bin/bash
# Usage: ./analyze.sh <metric> [optional_benchmark_name]
# Metrics: time, dump, size

METRIC=$1
SPECIFIC_BENCH=$2
BENCH_LIST="utilities/benchmark_list"

if [[ -z "$METRIC" ]]; then
    echo "Usage: $0 <metric> [benchmark_name]"
    echo "Metrics: time, dump, size"
    exit 1
fi

mkdir -p results

analyze_target() {
    local bench_exec=$1
    echo "Analyzing: $bench_exec"

    case "$METRIC" in
        time)
            echo "--- $bench_exec ---"
            for cfg in baseline asan lightsan; do
                BIN="./build_harvest/${cfg}/time/${bench_exec}"
                if [[ -f "$BIN" ]]; then
                    echo "[$cfg]:"
                    # FIX: Explicitly use bash, add ./ to BIN path, and DO NOT silence errors
                    bash ./utilities/time_benchmark.sh "$BIN"
                fi
            done
            echo "-------------------"
            ;;
        dump)
            BASE_BIN="./build_harvest/baseline/dump/${bench_exec}"
            LSAN_BIN="./build_harvest/lightsan/dump/${bench_exec}"
            
            if [[ -f "$BASE_BIN" && -f "$LSAN_BIN" ]]; then
                $BASE_BIN 2> "results/${bench_exec}_base.dump"
                $LSAN_BIN 2> "results/${bench_exec}_lightsan.dump"
                
                if diff -q "results/${bench_exec}_base.dump" "results/${bench_exec}_lightsan.dump" > /dev/null; then
                    echo "[$bench_exec] CORRECTNESS: PASS"
                else
                    echo "[$bench_exec] CORRECTNESS: FAIL (Output differs)"
                fi
                rm -f "results/${bench_exec}_base.dump" "results/${bench_exec}_lightsan.dump"
            else
                echo "Missing dump binaries for $bench_exec. Did you build them?"
            fi
            ;;
        size)
            echo "--- $bench_exec ---"
            BINS=""
            for cfg in baseline asan lightsan; do
                if [[ -f "./build_harvest/${cfg}/size/${bench_exec}" ]]; then
                    BINS="$BINS ./build_harvest/${cfg}/size/${bench_exec}"
                fi
            done
            if [[ -n "$BINS" ]]; then
                size $BINS
            fi
            echo ""
            ;;
        *)
            echo "Unknown metric."
            exit 1
            ;;
    esac
}

if [[ -n "$SPECIFIC_BENCH" ]]; then
    analyze_target "$SPECIFIC_BENCH"
else
    # Run analysis for all benchmarks in the list
    for bench_path in $(cat ${BENCH_LIST}); do
        bench_exec=$(basename $bench_path .c)
        analyze_target "$bench_exec"
    done
fi

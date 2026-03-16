#!/bin/bash
# Usage: ./build.sh <config> <mode> [optional_benchmark_name]
# Configs: baseline, asan, lightsan
# Modes: time, dump, size

CONFIG=$1
MODE=$2
SPECIFIC_BENCH=$3

# Separate compiler paths for Release and MinSize
CC_CLANG_REL="${CC_CLANG_REL:-$HOME/repos/lightsan/llvm-project/build/bin/clang}"
CC_CLANG_MINSIZE="${CC_CLANG_MINSIZE:-$HOME/repos/lightsan/llvm-project/build-minsize/bin/clang}"

LIGHTSAN_LIB_DIR="${LIGHTSAN_LIB_DIR:-$HOME/.local/lib/lightsan}"
BENCH_LIST="utilities/benchmark_list"

if [[ -z "$CONFIG" || -z "$MODE" ]]; then
    echo "Usage: $0 <config> <mode> [benchmark_name]"
    echo "Configs: baseline, asan, lightsan"
    echo "Modes: time, dump, size"
    exit 1
fi

echo "==> Setting up PolyBench build for: $CONFIG | $MODE"

# 1. Determine Flags and Compiler based on user input
OPT_FLAG="-O3"
MACRO_FLAG=""
EXTRA_CFLAGS=""
LDFLAGS=""
CURRENT_CC=""

# Mode specifics (Selects Compiler and Optimization/Macro Flags)
case "$MODE" in
    time) 
        CURRENT_CC="$CC_CLANG_REL"
        MACRO_FLAG="-DPOLYBENCH_TIME" 
        OPT_FLAG="-O3"
        ;;
    dump) 
        CURRENT_CC="$CC_CLANG_REL"
        OPT_FLAG="-O0"
        MACRO_FLAG="-DPOLYBENCH_DUMP_ARRAYS" 
        ;;
    size) 
        CURRENT_CC="$CC_CLANG_MINSIZE"
        OPT_FLAG="-Oz" 
        ;;
    *) 
        echo "Invalid mode. Use time, dump, or size."
        exit 1 
        ;;
esac

# Config specifics (Selects ASan Flags and Custom LightSan Libraries)
ASAN_BASE_FLAGS="-fsanitize=address -fsanitize-address-outline-instrumentation -fno-pie"
case "$CONFIG" in
    baseline) 
        ;;
    asan) 
        EXTRA_CFLAGS="$ASAN_BASE_FLAGS"
        LDFLAGS="-no-pie"
        ;;
    lightsan) 
        EXTRA_CFLAGS="$ASAN_BASE_FLAGS"
        if [[ "$MODE" == "size" ]]; then
            # Uses minsize library
            LDFLAGS="-fno-sanitize-link-runtime -L${LIGHTSAN_LIB_DIR} -llightsan-asan-minsize -lstdc++ -no-pie"
        else
            # Uses release library
            LDFLAGS="-fno-sanitize-link-runtime -L${LIGHTSAN_LIB_DIR} -llightsan-asan-rel -lstdc++ -no-pie"
        fi
        ;;
    *) echo "Invalid config. Use baseline, asan, or lightsan."; exit 1 ;;
esac

# 2. Write PolyBench's required config.mk
cat <<EOF > config.mk
CC = ${CURRENT_CC}
CFLAGS = ${OPT_FLAG} ${MACRO_FLAG} ${EXTRA_CFLAGS} -DLARGE_DATASET
LDFLAGS = ${LDFLAGS}
EOF

# 3. Generate the local Makefiles using PolyBench's native script
perl utilities/makefile-gen.pl .

# FIX: PolyBench's makefile generator forgets to include LDFLAGS at the end of the compile line.
# We use sed to append ${LDFLAGS} to the very end of the compilation command in all generated Makefiles.
find linear-algebra datamining stencils medley -name Makefile -exec sed -i 's/\${EXTRA_FLAGS}/\${EXTRA_FLAGS} \${LDFLAGS}/g' {} +

# 4. Build the targets and harvest them
OUT_DIR="build_harvest/${CONFIG}/${MODE}"
mkdir -p "$OUT_DIR"

build_target() {
    local bench_path=$1
    local bench_dir=$(dirname $bench_path)
    local bench_exec=$(basename $bench_path .c)
    
    echo "  -> Building $bench_exec..."
    
    if make -C "$bench_dir" "$bench_exec"; then
        cp "${bench_dir}/${bench_exec}" "${OUT_DIR}/${bench_exec}"
    else
        echo "  [!] Build failed for $bench_exec"
    fi
}

if [[ -n "$SPECIFIC_BENCH" ]]; then
    # Find and build only the specific benchmark requested
    TARGET_PATH=$(grep "/${SPECIFIC_BENCH}.c$" $BENCH_LIST)
    if [[ -n "$TARGET_PATH" ]]; then
        build_target "$TARGET_PATH"
    else
        echo "Benchmark '$SPECIFIC_BENCH' not found in $BENCH_LIST"
    fi
else
    # Build all of them
    for bench_path in $(cat ${BENCH_LIST}); do
        build_target "$bench_path"
    done
fi

# 5. Clean up PolyBench's generated Makefiles so the tree stays clean
perl utilities/clean.pl .

echo "==> Done! Binaries are in: $OUT_DIR/"

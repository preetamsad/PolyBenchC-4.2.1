## PolyBench Benchmark

### Build

```bash
# Build a specific config and mode
./build.sh <config> <mode>

# Configs: baseline, asan, lightsan
# Modes:   time (runtime), dump (correctness), size (binary size)

# Example: build all three configs for timing
./build.sh baseline time
./build.sh asan time
./build.sh lightsan time
```

Build outputs go to `build_harvest/<config>/<mode>/` (e.g. `build_harvest/asan/time/`). The benchmark list is read from `utilities/benchmark_list`. PolyBench's per-benchmark Makefiles are generated and cleaned up automatically by the script — they won't persist after the build.

Compiler defaults to `~/repos/lightsan/llvm-project/build/bin/clang` for `time`/`dump` and `build-minsize/bin/clang` for `size`. LightSan runtime defaults to `~/.local/lib/lightsan`. Override with `CC_CLANG_REL`, `CC_CLANG_MINSIZE`, and `LIGHTSAN_LIB_DIR`.

---

### Speed Benchmark

#### Run

```bash
# Build time variants first
./build.sh baseline time
./build.sh asan time
./build.sh lightsan time

# Run timing analysis across all benchmarks (output to results/time.txt)
./analyze.sh time > results/time.txt
```

#### Collect into CSV

```bash
python3 time-to-csv.py
```

Reads `results/time.txt`. Output file: `polybench_clean.csv` — columns: `Benchmark, Baseline, ASAN, LightSan`.

#### Generate Graph

```bash
pip install pandas matplotlib numpy
python3 genpolygraph.py
```

Reads `time.csv` from the current directory. Output: `polybench_asan_speed_graph.pdf`.

---

### Correctness Check

```bash
# Build dump variants
./build.sh baseline dump
./build.sh lightsan dump

# Run diff-based correctness check across all benchmarks
./analyze.sh dump
```

For each benchmark, the script runs both binaries, captures their array output to `results/<bench>_base.dump` and `results/<bench>_lightsan.dump`, diffs them, and prints `PASS` or `FAIL`. Dump files are removed after each check.

---

### Size Benchmark

```bash
# Build size variants
./build.sh baseline size
./build.sh asan size
./build.sh lightsan size

# Run size analysis
./analyze.sh size > size.log
```

Calls `size` on the three binaries per benchmark from `build_harvest/baseline/size/`, `build_harvest/asan/size/`, and `build_harvest/lightsan/size/`. Output goes to `size.log`.

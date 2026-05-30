import sys
import csv

def parse_log(filename):
    data = {}
    current_bench = None
    current_cfg = None

    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('Analyzing:'):
                    current_bench = line.split(':')[1].strip()
                    if current_bench not in data:
                        data[current_bench] = {'baseline': 0.0, 'asan': 0.0, 'lightsan': 0.0}
                elif line.startswith('[baseline]:'):
                    current_cfg = 'baseline'
                elif line.startswith('[asan]:'):
                    current_cfg = 'asan'
                elif line.startswith('[lightsan]:'):
                    current_cfg = 'lightsan'
                elif '[INFO] Normalized time:' in line:
                    time_val = float(line.split(':')[1].strip())
                    if current_bench and current_cfg:
                        data[current_bench][current_cfg] = time_val
    except FileNotFoundError:
        print(f"Error: Could not find {filename}")
        sys.exit(1)
        
    return data

def write_csv(data, output_file):
    # Sort alphabetically for consistency
    sorted_benchmarks = sorted(data.keys())
    
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Benchmark', 'Baseline', 'ASAN', 'LightSan'])
        for bench in sorted_benchmarks:
            writer.writerow([
                bench, 
                data[bench]['baseline'], 
                data[bench]['asan'], 
                data[bench]['lightsan']
            ])
    print(f"Successfully wrote {len(sorted_benchmarks)} rows to {output_file}")

if __name__ == "__main__":
    log_file = "results/time.txt" # Make sure this matches your log file name
    out_file = "polybench_clean.csv"
    parsed_data = parse_log(log_file)
    if parsed_data:
        write_csv(parsed_data, out_file)

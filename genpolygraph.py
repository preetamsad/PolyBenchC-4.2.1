import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

# --- THESIS PLOT STANDARDIZATION ---
mpl.rcParams['font.family'] = 'serif'
mpl.rcParams['font.serif'] = ['Computer Modern Roman', 'DejaVu Serif']
mpl.rcParams['mathtext.fontset'] = 'cm'
mpl.rcParams['font.size'] = 9
# -----------------------------------

df = pd.read_csv('time.csv')
df['ASAN_OH'] = df['ASAN'] / df['Baseline']
df['LightSan_OH'] = df['LightSan'] / df['Baseline']

df_sorted = df.sort_values(by='ASAN_OH').reset_index(drop=True)

# Locked figsize to LaTeX linewidth
fig, ax = plt.subplots(figsize=(6.5, 3.5))

x = np.arange(len(df_sorted))
width = 0.35

rects1 = ax.bar(x - width/2, df_sorted['ASAN_OH'], width, label='Baseline ASan', color='#B22222')
rects2 = ax.bar(x + width/2, df_sorted['LightSan_OH'], width, label='LightSan-ASan', color='#004c99')

ax.axhline(y=1.0, color='black', linestyle='-.', linewidth=1.5, label='Unsanitized (1.0x)')

ax.set_ylabel('Normalized Execution Time Overhead')
ax.set_xticks(x)
# Font size dropped to 7 here so all 30 benchmarks fit in the 6.5-inch width
ax.set_xticklabels(df_sorted['Benchmark'], rotation=45, ha='right', rotation_mode='anchor', fontsize=7)

ax.grid(axis='y', linestyle='-', alpha=0.3)
ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)
ax.legend(loc='upper left', frameon=False)

plt.tight_layout()
plt.savefig('polybench_asan_speed_graph.pdf', format='pdf', bbox_inches='tight')

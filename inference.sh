#!/bin/bash
# AMPlify inference wrapper for battleamp-snakemake
#
# Interface contract:
#   $1 = path to input FASTA file (absolute)
#   $2 = path to output TSV file (absolute)
#
# Output columns: sequence  Prediction  Probability_score

set -euo pipefail

INPUT_FASTA="$1"
OUTPUT_TSV="$2"

if [ -z "$INPUT_FASTA" ] || [ -z "$OUTPUT_TSV" ]; then
    echo "Usage: inference.sh <input.fasta> <output.tsv>" >&2
    exit 1
fi

if [ ! -f "$INPUT_FASTA" ]; then
    echo "Error: input FASTA not found: $INPUT_FASTA" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_OUTPUT="${OUTPUT_TSV}.raw"

# TensorFlow pip packages install NVIDIA libs into site-packages/nvidia/*/lib/
# These must be on LD_LIBRARY_PATH for TF to find the GPU.
NVIDIA_LIB_DIRS=$(python3 -c "
import os, nvidia
base = os.path.dirname(nvidia.__file__)
libs = [os.path.join(base, d, 'lib') for d in sorted(os.listdir(base))
        if os.path.isdir(os.path.join(base, d, 'lib'))]
print(':'.join(libs))
" 2>/dev/null || echo "")
if [ -n "$NVIDIA_LIB_DIRS" ]; then
    export LD_LIBRARY_PATH="${NVIDIA_LIB_DIRS}:${LD_LIBRARY_PATH:-}"
fi

# Step 1: Run AMPlify
echo "Running AMPlify..." >&2
python "$SCRIPT_DIR/src/AMPlify.py" -s "$INPUT_FASTA" -on "$TMP_OUTPUT"

# Step 2: Convert to standard pipeline format
# AMPlify columns: Sequence_ID, Sequence, Length, Charge, Probability_score,
#                  AMPlify_log_scaled_score, Prediction
# Invalid sequences (non-standard aa, length out of range) have "NA" values.
# Pipeline standard columns: sequence, Prediction, Probability_score
python3 - "$TMP_OUTPUT" "$OUTPUT_TSV" << 'PYEOF'
import sys
import pandas as pd

raw_path = sys.argv[1]
out_path = sys.argv[2]

df = pd.read_csv(raw_path, sep="\t")

# Drop rows where AMPlify could not make a prediction
n_total = len(df)
df = df[df["Probability_score"] != "NA"].copy()
n_valid = len(df)
if n_total != n_valid:
    print(f"Filtered {n_total - n_valid} invalid sequences "
          f"({n_valid}/{n_total} valid)", file=sys.stderr)

out = pd.DataFrame({
    "sequence": df["Sequence"],
    "Prediction": df["Prediction"],
    "Probability_score": pd.to_numeric(df["Probability_score"]),
})

out.to_csv(out_path, sep="\t", index=False)
print(f"Converted {len(out)} predictions to {out_path}", file=sys.stderr)
PYEOF

# Step 3: Clean up
rm -f "$TMP_OUTPUT"

echo "AMPlify inference complete: $(wc -l < "$OUTPUT_TSV") lines" >&2
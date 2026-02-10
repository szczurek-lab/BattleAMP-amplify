#!/bin/bash
set -euo pipefail

pip install -r requirements.txt

# TensorFlow pip packages install NVIDIA libs into site-packages/nvidia/*/lib/
# These must be on LD_LIBRARY_PATH for TF to find the GPU.
NVIDIA_LIB_DIRS=$(python3 -c "
import os, nvidia
base = os.path.dirname(nvidia.__file__)
libs = [os.path.join(base, d, 'lib') for d in sorted(os.listdir(base))
        if os.path.isdir(os.path.join(base, d, 'lib'))]
print(':'.join(libs))
")
export LD_LIBRARY_PATH="${NVIDIA_LIB_DIRS}:${LD_LIBRARY_PATH:-}"
echo "Set LD_LIBRARY_PATH for NVIDIA libs"

# Verify model weights exist
MODEL_DIR="models/balanced"
if [ ! -d "$MODEL_DIR" ]; then
    echo "ERROR: Model weights directory not found: $MODEL_DIR" >&2
    echo "Please download or copy AMPlify balanced model weights to $MODEL_DIR/" >&2
    echo "Expected files: AMPlify_balanced_model_weights_{1..5}.h5" >&2
    exit 1
fi

WEIGHTS_FOUND=$(ls "$MODEL_DIR"/AMPlify_balanced_model_weights_*.h5 2>/dev/null | wc -l)
if [ "$WEIGHTS_FOUND" -lt 5 ]; then
    echo "ERROR: Expected 5 model weight files in $MODEL_DIR/, found $WEIGHTS_FOUND" >&2
    exit 1
fi

# Verify GPU access
GPU_COUNT=$(python3 -c "
import tensorflow as tf
gpus = tf.config.list_physical_devices('GPU')
print(len(gpus))
" 2>/dev/null || echo "0")

if [ "$GPU_COUNT" -gt 0 ]; then
    echo "AMPlify setup complete: $WEIGHTS_FOUND weight files, $GPU_COUNT GPU(s) detected"
else
    echo "WARNING: No GPUs detected. AMPlify will run on CPU (very slow)." >&2
fi
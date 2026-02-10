# BattleAMP-amplify

Fork of [AMPlify](https://github.com/bcgsc/AMPlify) (Li et al., 2022) adapted for the [BattleAMP benchmark pipeline](https://github.com/szczurek-lab/battleamp-snakemake).

## What is AMPlify

AMPlify is an attentive deep learning model for antimicrobial peptide prediction. It uses an ensemble of five bidirectional LSTM networks with multi-head scaled dot-product attention and context attention layers. Input sequences are one-hot encoded (maximum length 200 residues). The final prediction is the mean probability across the five sub-models.

Original paper: Li et al. (2022). AMPlify: attentive deep learning model for discovery of novel antimicrobial peptides effective against WHO priority pathogens. *BMC Genomics*, 23(1), 77. https://doi.org/10.1186/s12859-022-04577-y

## Requirements

- NVIDIA GPU with CUDA support
- conda (for environment creation by the pipeline)
- Model weights in `models/balanced/` (5 files: `AMPlify_balanced_model_weights_{1..5}.h5`). These are not included in the repository due to size; obtain them from the original AMPlify release or contact the authors.

## Usage within the pipeline

This repository is included as a git submodule in battleamp-snakemake:

```bash
cd battleamp-snakemake
git submodule add git@github.com:szczurek-lab/BattleAMP-amplify.git models/amplify
```

The pipeline handles environment creation, batched inference (splitting large FASTA files into chunks of 100k sequences), and evaluation automatically. No manual intervention is needed after the submodule is added and weights are in place.

## Standalone usage

To run AMPlify outside the pipeline:

```bash
conda create -n amplify python=3.10
conda activate amplify
pip install -r requirements.txt

python src/AMPlify.py -s input.fasta -on output.tsv
```

Output columns: `Sequence_ID`, `Sequence`, `Length`, `Charge`, `Probability_score`, `AMPlify_log_scaled_score`, `Prediction`.

## GPU troubleshooting

TensorFlow installed via pip bundles its own NVIDIA libraries in `site-packages/nvidia/*/lib/`. If TensorFlow does not detect the GPU, these directories need to be on `LD_LIBRARY_PATH`. The `setup.sh` and `inference.sh` scripts handle this automatically. To set it manually:

```bash
export LD_LIBRARY_PATH=$(python3 -c "
import os, nvidia
base = os.path.dirname(nvidia.__file__)
libs = [os.path.join(base, d, 'lib') for d in sorted(os.listdir(base))
        if os.path.isdir(os.path.join(base, d, 'lib'))]
print(':'.join(libs))
"):$LD_LIBRARY_PATH
```

## License

Same as the original AMPlify repository (MIT).
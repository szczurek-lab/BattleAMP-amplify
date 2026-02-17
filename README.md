# AMPlify

Fork of [bcgsc/AMPlify](https://github.com/bcgsc/AMPlify), adapted for integration with
the [battleamp-snakemake](https://github.com/szczurek-lab/battleamp-snakemake) benchmarking
pipeline.

## Supported tasks

AMP classification (binary: AMP / non-AMP).

## Reference

Li, C., Sutherland, D., Hammond, S.A. et al. AMPlify: attentive deep learning model for discovery of novel antimicrobial peptides effective against WHO priority pathogens. BMC Genomics 23, 77 (2022). https://doi.org/10.1186/s12864-022-08310-4
    

## Requirements

- Python 3.10
- conda (for environment creation by the pipeline)
- NVIDIA GPU (TensorFlow will fall back to CPU but inference is very slow)

The model architecture (a 5-model ensemble of bidirectional LSTMs with attention) and
the pretrained weights are unchanged. Python was upgraded from 3.6 to 3.10 and
dependencies were updated accordingly (TensorFlow 2.x, compatible Keras, etc.)

## Installation

```bash
conda create -n amplify python=3.10
conda activate amplify
sh setup.sh
```

Test whether everything works:

```bash
sh inference.sh sample.fasta results.tsv
```

## Usage within the pipeline

This repository is included as a git submodule in battleamp-snakemake:

```bash
cd battleamp-snakemake
git submodule add git@github.com:szczurek-lab/BattleAMP-AMPlify.git models/amplify
```

The pipeline handles environment creation, inference, and evaluation automatically.
No manual intervention is needed after the submodule is added and weights are in place.

## Standalone usage

```bash
conda create -n amplify python=3.10
conda activate amplify
pip install -r requirements.txt

python src/AMPlify.py -s input.fasta -on output.tsv
```

Output columns: `Sequence_ID`, `Sequence`, `Length`, `Charge`, `Probability_score`,
`AMPlify_log_scaled_score`, `Prediction`.



## Notes

- AMPlify uses a 5-model ensemble. All weight files
  (`models/balanced/AMPlify_balanced_model_weights_{1..5}.h5`) must be present.
- The balanced model is used by default, suitable for curated candidate sets.
  The imbalanced model (for large-scale screening with many non-AMPs) is also
  available in `models/imbalanced/`.
- Results for sequences with non-standard amino acids are returned as `NA`.

## License

Same as the original AMPlify repository (MIT).
"""
convert input file and saves into output file removing old file
"""
import os

import pandas as pd
import argparse


def process_file(filepath: str, output_filename: str):
    df = pd.read_csv(filepath, delimiter="\t")
    df.rename(columns={"Sequence": "sequence"}, inplace=True)
    print(f"columns were renamed to {df.columns}")
    df.to_csv(output_filename, sep="\t", index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a TSV file for AMP classification.')
    parser.add_argument('filepath', type=str, help='Path to the input TSV file')
    parser.add_argument('output_filename', type=str, help='Path to the output TSV file')

    args = parser.parse_args()
    process_file(args.filepath, args.output_filename)

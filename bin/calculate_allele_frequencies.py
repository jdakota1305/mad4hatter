import pandas as pd
import argparse

def calculate_frequencies(input_file, output_file):
    df = pd.read_csv(input_file, sep="\t")  # Read allele_data.txt
    
    #count occurrences of each ASV per Locus
    freq_table = df.groupby(["Locus", "ASV"]).size().reset_index(name="Freq")
    
    #save output
    freq_table.to_csv(output_file, sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate allele frequencies")
    parser.add_argument("--input", required=True, help="Path to allele_data.txt")
    parser.add_argument("--output", required=True, help="Output file")
    
    args = parser.parse_args()
    calculate_frequencies(args.input, args.output)


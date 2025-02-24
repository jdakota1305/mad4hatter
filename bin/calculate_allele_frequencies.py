import pandas as pd
import argparse

def calculate_frequencies(input_file, output_file):
    df = pd.read_csv(input_file, sep="\t")  #read allele_data.txt
    
    #group by Locus and ASV and sum the Reads
    read_counts = df.groupby(["Locus", "ASV"])["Reads"].sum().reset_index()
    
    #calculate total reads per Locus
    locus_totals = read_counts.groupby("Locus")["Reads"].sum().reset_index(name="TotalReads")
    
    #merge to get totals alongside individual read counts
    merged = pd.merge(read_counts, locus_totals, on="Locus")
    
    #calculate frequencies
    merged["Frequency"] = merged["Reads"] / merged["TotalReads"]
    
    #select and rename columns for output
    result = merged[["Locus", "ASV", "Reads", "TotalReads", "Frequency"]]
    
    #save output
    result.to_csv(output_file, sep="\t", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate allele frequencies")
    parser.add_argument("--input", required=True, help="Path to allele_data.txt")
    parser.add_argument("--output", required=True, help="Output file")
    
    args = parser.parse_args()
    calculate_frequencies(args.input, args.output)
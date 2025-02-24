#!/bin/bash -euo pipefail
Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/mask_sequences.R     --masks v4_reference.fasta.2.7.7.80.10.25.3.mask refseq.homopolymer.fasta.mask     --alignments filtered.alignments.txt     --n-cores 4

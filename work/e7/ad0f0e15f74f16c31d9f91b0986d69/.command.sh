#!/bin/bash -euo pipefail
python3 /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/resistance_marker_module.py     --allele_data_path allele_data.txt     --aligned_asv_table_path masked.alignments.txt     --res_markers_info_path resistance_markers_amplicon_v4.txt     --refseq_path v4_reference.fasta     --n-cores 4

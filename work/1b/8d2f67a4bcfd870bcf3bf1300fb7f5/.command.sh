#!/bin/bash -euo pipefail
Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/align_to_reference.R     --clusters clusters.concatenated.collapsed.txt     --refseq-fasta v4_reference.fasta     --amplicon-table v4_amplicon_info.tsv     --n-cores 6

#!/bin/bash -euo pipefail
Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/dada_overlaps.R     --trimmed-path demultiplexed_fastqs1     --ampliconFILE v4_amplicon_info.tsv     --pool pseudo     --band-size 16     --omega-a 1E-120     --maxEE 3     --cores 6     --concat-non-overlaps

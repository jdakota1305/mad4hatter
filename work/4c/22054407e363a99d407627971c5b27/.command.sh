#!/bin/bash -euo pipefail
Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/create_reference_from_genomes.R     --ampliconFILE v4_amplicon_info.tsv     --genome example.fasta     --output v4_reference.fasta     --ncores 4

#!/bin/bash -euo pipefail
# Ensure only one file is provided for each coverage type
if [ $(ls -l sample_coverage.txt | wc -l) -ne 1 ] || [ $(ls -l amplicon_coverage.txt | wc -l) -ne 1 ]; then
  echo "Error: Multiple coverage files detected. Expecting only one file for each type."
  exit 1
fi

Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/asv_coverage.R     --alleledata allele_data.txt     --clusters dada2.clusters.txt     --sample-coverage sample_coverage.txt     --amplicon-coverage amplicon_coverage.txt

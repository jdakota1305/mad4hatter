#!/bin/bash -euo pipefail
# Rename input files to published versions
test -f sample_coverage.txt || mv sample_coverage_postprocessed.txt sample_coverage.txt
test -f amplicon_coverage.txt || mv amplicon_coverage_postprocessed.txt amplicon_coverage.txt

test -d quality_report || mkdir quality_report
Rscript /Users/shodanbeats/Desktop/Job_Search_2025/ucsf_exercise/exercise_data/part2/mad4hatter/bin/cutadapt_summaryplots.R amplicon_coverage.txt sample_coverage.txt v4_amplicon_info.tsv quality_report

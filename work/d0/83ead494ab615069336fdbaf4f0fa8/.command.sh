#!/bin/bash -euo pipefail
add_sample_name_column() {
  awk -v fname=$(basename "$1" | sed -e 's/.SAMPLEsummary.txt//g' -e 's/.AMPLICONsummary.txt//g') -v OFS="\t" '{print fname, $0}' "$1"
}

echo -e "SampleID\tStage\tReads" > sample_coverage.txt
echo -e "SampleID\tLocus\tReads" > amplicon_coverage.txt

for file in $(ls 7S1-10K-parasitedensity-0p25x-primerconcentration-allpools-ENV-PV4-replicate1_S1_L001.SAMPLEsummary.txt)
do
    add_sample_name_column $file >> sample_coverage.txt
done

for file in $(ls 7S1-10K-parasitedensity-0p25x-primerconcentration-allpools-ENV-PV4-replicate1_S1_L001.AMPLICONsummary.txt)
do
    add_sample_name_column $file >> amplicon_coverage.txt
done

#!/usr/bin/env bash

# This is an optional script to remove spike-in sequences from the reads.
# Currently the barcodes are hardcoded into the script - these should
# be added to the parameters.
#
# Other cutadapt parameters that should be tunable are the number of allowed
# errors in the spikein barcodes
#
# Spikein detection will be available in R{12} fastqs and json file (${SAMPLEID}.spikeins.json)

set -e

# Function to print help
usage() {
    echo "Usage: $0 -1 R1_fastq -2 R2_fastq -j json-file-output -u unknown-dir-output -s spikein-dir-output"
    exit 1
}

while getopts "1:2:j:u:s:" OPTION
do
    case $OPTION in
        1)
            R1=$OPTARG
            ;;
        2)
            R2=$OPTARG
            ;;
        j)
            JSON_FILE_OUTPUT=$OPTARG
            ;;
        u)
            UNKNOWN_DIR_OUTPUT=$OPTARG
            ;;
        s)
            SPIKEIN_DIR_OUTPUT=$OPTARG
            ;;
        h)
            usage
            ;;
        ?)
            usage
            ;;
    esac
done

# Validate inputs
if [[ -z "$R1" || -z "$R2" || -z "$JSON_FILE_OUTPUT" || -z "$UNKNOWN_DIR_OUTPUT" || -z "$SPIKEIN_DIR_OUTPUT" ]]; then
    usage
fi

# Create output directories (if needed)
test -d ${UNKNOWN_DIR_OUTPUT} || mkdir -p ${UNKNOWN_DIR_OUTPUT}
test -d ${SPIKEIN_DIR_OUTPUT} || mkdir -p ${SPIKEIN_DIR_OUTPUT}

# Extract the Sample ID from the file name
SAMPLEID=$(echo $R1 | sed -e 's/_unknown.*$//')

# Identify R1 and R2 reads containing the spikein signatature in
# sample specific files. Create fastqs containing reads with the 
# signatures. Additionally, create fastqs to hold the rest of the reads.
# A json file will be output containing distribution information
# about the spikeins. 

cutadapt \
    --action=trim \
    -g ^TCTCCTTCTTAGCTTCGTGAGAAC \
    -G ^CTTGGTCGTCTACTACATGATGTG \
    -e 0 \
    --no-indels \
    -o ${SPIKEIN_DIR_OUTPUT}/${SAMPLEID}_spikein_R1.fastq.gz \
    -p ${SPIKEIN_DIR_OUTPUT}/${SAMPLEID}_spikein_R2.fastq.gz \
    --untrimmed-output ${UNKNOWN_DIR_OUTPUT}/${SAMPLEID}_filtered_R1.fastq.gz \
    --untrimmed-paired ${UNKNOWN_DIR_OUTPUT}/${SAMPLEID}_filtered_R2.fastq.gz \
    --json ${SAMPLEID}.spikeins.json \
    ${R1} \
    ${R2} 

exit 0
process CALCULATE_ALLELE_FREQUENCIES {
    tag "Calculating allele frequencies"
    publishDir "${params.outDIR}/results", mode: 'copy'

    input:
    path alleledata

    output:
    path "allele_frequencies.tsv", emit: allele_frequencies_ch

    script:
    """
    python3 $projectDir/bin/calculate_allele_frequencies.py \
        --input $alleledata \
        --output allele_frequencies.tsv
    """
}
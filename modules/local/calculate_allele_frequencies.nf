process CALCULATE_ALLELE_FREQUENCIES {
    tag "Calculating allele frequencies"

    input:
    path alleledata from BUILD_ALLELETABLE.out.alleledata

    output:
    path "allele_frequencies.tsv" into allele_frequencies_ch

    script:
    """
    python3 bin/calculate_allele_frequencies.py \
        --input $alleledata \
        --output allele_frequencies.tsv
    """
}


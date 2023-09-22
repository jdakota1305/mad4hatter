/*
 * STEP - CUTADAPT
 * Prepare the primer files from the given amplicon_info file
 */


process CUTADAPT {

  tag "$pair_id"
  label 'process_low'

    input:
    file fwd_primers
    file rev_primers
    tuple val(pair_id), file(reads)
    val cutadapt_minlen
    val sequencer
    val allowed_errors

    output:
    path("*.SAMPLEsummary.txt"), emit: sample_summary
    path("*.AMPLICONsummary.txt"), emit: amplicon_summary
    path('demuliplexed_fastqs'), emit: demultiplexed_fastqs
    tuple val(pair_id), path("trimmed_demuxed_unknown_fastqs/${pair_id}_unknown_R1.fastq.gz"), path("trimmed_demuxed_unknown_fastqs/${pair_id}_unknown_R2.fastq.gz"), emit: unknown_fastqs

    script:
    """

    # 'trimmed_demuxed_unknown_fastqs' is hardcoded into the script
    # and contains the reads that could not be demultiplexed. 

    bash cutadapt_process.sh \
        -1 ${reads[0]} \
        -2 ${reads[1]} \
        -r ${rev_primers} \
        -f ${fwd_primers} \
        -m ${cutadapt_minlen} \
        -s ${sequencer} \
        -e ${allowed_errors} \
        -c ${task.cpus} \
        -o demuliplexed_fastqs
    """
}
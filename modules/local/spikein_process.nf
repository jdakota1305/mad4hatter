/*
 * STEP - SPIKEINS
 * Prepare the primer files from the given amplicon_info file
 *
 * NOTE: Spike adapters are currently hardocded in the script and
 *      should be changed to be read from the a file or set with parameters.
 */


process SPIKEINS {

    tag "$pair_id"
    label 'process_low'

    input:
    tuple val(pair_id), path(unknown_R1), path(unknown_R2) 

    output:
    path("${pair_id}.spikeins.json"), emit: spikein_json
    path("${pair_id}_spikeins"), emit: spikein_dir
    path("${pair_id}_unknown"), emit: unknown_dir

    script:
    """
    bash spikein_process.sh \
        -1 ${unknown_R1} \
        -2 ${unknown_R2} \
        -j "${pair_id}.spikeins.json" \
        -u "${pair_id}_unknown" \
        -s "${pair_id}_spikeins"
    """
}
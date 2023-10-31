process RETRIEVE_CRAM {
    label 'cpu_2_mem_1_time_1'
    input:
    tuple val(meta), val(cram_path)

    output:
    tuple val(meta), path("*.cram"), emit: path_channel

    script:
    """
    iget -K ${cram_path}
    """
}
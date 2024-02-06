process BMTAGGER {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_10'
    label 'time_queue_from_normal'

    container '/software/pathogen/images/bmtagger-3.101--h470a237_4.simg'

    input:
    tuple val(meta), path(first_read), path(second_read)

    output:
    tuple val(meta), path(first_read), path(second_read), emit: data_ch
    path(bmtagger_list), emit: bmtagger_list_ch

    script:
    bmtagger_list="${meta.ID}.bmtagger.list"
    """
    # make tmp folder for bmtagger
    mkdir bmtagger_tmp
    # run bmtagger
    bmtagger.sh -b ${params.bmtagger_db_abundance_estimation}/${params.bmtagger_host_abundance_estimation}.bitmask \\
     -x ${params.bmtagger_db_abundance_estimation}/${params.bmtagger_host_abundance_estimation}.srprism -T bmtagger_tmp -q1 \\
	 -1 ${first_read} -2 ${second_read} \\
	 -o ${meta.ID}.bmtagger.list
    """
}
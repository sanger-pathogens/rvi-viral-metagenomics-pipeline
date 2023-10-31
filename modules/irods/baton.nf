process BATON {
    label 'cpu_2_mem_1_time_1'
    maxForks = 10
    container "/software/hgi/containers/singularity-baton/baton.simg"
    input:
    path(json_file)

    output:
    path(lane_file), emit: path_channel

    script:
    lane_file="info.json"
    """
    baton-do --file ${json_file} --zone seq > ${lane_file}
    """
}
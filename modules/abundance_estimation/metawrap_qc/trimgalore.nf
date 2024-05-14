process TRIMGALORE {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_1'
    label 'time_queue_from_normal'

    container '/software/pathogen/images/trimgalore-v0.4.4.simg'

    input:
    tuple val(meta), path(first_read), path(second_read)

    output:
    tuple val(meta), path(trimmed_1), path(trimmed_2), emit: trimmed_fastqs

    script:
    trimmed_1="${meta.ID}_trimmed_1.fastq"
    trimmed_2="${meta.ID}_trimmed_2.fastq"
    """
    trim_galore --no_report_file --dont_gzip --paired ${first_read} ${second_read}
    # rename files
    mv ${meta.ID}_1_val_1.fq ${meta.ID}_trimmed_1.fastq
    mv ${meta.ID}_2_val_2.fq ${meta.ID}_trimmed_2.fastq
    """
}
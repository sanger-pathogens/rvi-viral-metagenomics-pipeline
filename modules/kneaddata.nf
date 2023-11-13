process KNEADDATA {
    tag "${meta.ID}"
    label 'cpu_4'
    label 'mem_4'
    label 'time_12'

    container '/software/pathogen/images/kneaddata-0.12.0.simg'

    if (params.publish_trimmed_reads) publishDir mode: 'copy', pattern: "${output_1}", path: "${params.results_dir}/${meta.ID}/trimmed_reads/"}
    if (params.publish_trimmed_reads) publishDir mode: 'copy', pattern: "${output_2}", path: "${params.results_dir}/${meta.ID}/trimmed_reads/"}


    input:
    tuple val(meta), path(R1), path(R2)

    output:
    tuple val(meta), path(output_1), path(output_2), emit: paired_channel

    script:
    output_1 = "${meta.ID}_1_kneaddata_paired_1.fastq"
    output_2 = "${meta.ID}_1_kneaddata_paired_2.fastq"
    output_unmatched_1 = "${meta.ID}_1_kneaddata_unmatched_1.fastq"
    output_unmatched_2 = "${meta.ID}_1_kneaddata_unmatched_2.fastq"
    """
    kneaddata -t ${params.kneaddata_threads} -p 2 -i1 ${R1} -i2 ${R2} -db ${params.off_target_db} --output . --sequencer-source ${params.sequencer_source} \
    --trimmomatic-options "${params.trimmomatic_options}"
    """
}  
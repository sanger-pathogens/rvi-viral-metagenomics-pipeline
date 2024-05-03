process KNEADDATA {
    tag "${meta.ID}"
    label 'mem_4'
    label 'time_12'
    cpus { task.attempt > 1 ? 1 : params.kneaddata_threads }

    container 'quay.io/biocontainers/kneaddata:0.12.0--pyhdfd78af_1'

    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_1_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"
    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_2_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"

    input:
    tuple val(meta), path(R1), path(R2)

    output:
    tuple val(meta), path(output_1), path(output_2), emit: paired_channel
    tuple val(meta), path(output_1_gz), path(output_2_gz)
    path(kd_log), emit: kd_log_ch

    script:
    output_1 = "${meta.ID}_1_kneaddata_paired_1.fastq"
    output_2 = "${meta.ID}_1_kneaddata_paired_2.fastq"
    output_1_gz = "${output_1}.gz"
    output_2_gz = "${output_2}.gz"
    output_unmatched_1 = "${meta.ID}_1_kneaddata_unmatched_1.fastq"
    output_unmatched_2 = "${meta.ID}_1_kneaddata_unmatched_2.fastq"
    kd_log = "${meta.ID}_1_kneaddata.log"
    """
    kneaddata -t ${task.cpus} -p 2 -i1 ${R1} -i2 ${R2} -db ${params.off_target_db} --output . --sequencer-source ${params.sequencer_source} \
    --trimmomatic-options "${params.trimmomatic_options}"
    gzip -c ${output_1} > ${output_1}.gz
    gzip -c ${output_2} > ${output_2}.gz
    """
}  
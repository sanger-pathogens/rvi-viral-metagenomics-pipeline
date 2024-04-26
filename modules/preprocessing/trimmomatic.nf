process TRIMMOMATIC {
    tag "${meta.ID}"
    label 'mem_1'
    label 'time_1'
    cpus params.kneaddata_threads

    container '/software/pathogen/images/trimmomatic-0.39--1.simg'

    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_1_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"
    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_2_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"

    input:
    tuple val(meta), path(extracted_R1), path(extracted_R2)

    output:
    tuple val(meta), path(output_1), path(output_2), emit: paired_channel
    tuple val(meta), path(output_1_gz), path(output_2_gz)

    script:\
    output_1="${meta.ID}_trimmed_1.fastq"
    output_2="${meta.ID}_trimmed_2.fastq"
    output_1_gz = "${output_1}.gz"
    output_2_gz = "${output_2}.gz"
    output_1_unpaired="${meta.ID}_trimmed_unpaired_1.fastq"
    output_2_unpaired="${meta.ID}_trimmed_unpaired_2.fastq"
    """
    trimmomatic PE -phred33 -threads ${params.trimmomatic_threads} ${extracted_R1} ${extracted_R2} \
    ${output_1} ${output_1_unpaired} \
    ${output_2} ${output_2_unpaired} \
    ${params.trimmomatic_options}
    gzip -c ${output_1} > ${output_1}.gz
    gzip -c ${output_2} > ${output_2}.gz
    """
}
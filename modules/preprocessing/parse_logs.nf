
process PARSE_KD_LOG {
    label 'mem_1'
    label 'time_1'

    conda 'conda-forge::python=3.10.2'
    container 'quay.io/biocontainers/python:3.10.2'

    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_1_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"
    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_2_gz}", path: "${params.outdir}/${meta.ID}/trimmed_reads/"

    input:
    tuple path(kd_logs)

    output:
    tuple val(meta), path(output_1), path(output_2), emit: paired_channel
    tuple val(meta), path(output_1_gz), path(output_2_gz)

    script:
    output_txt="${meta.ID}_kneaddata_filtered_reads_report.txt"
    """
    python3 count_reads_in_kd_log.py *_1_kneaddata.log ${output_txt}
    """
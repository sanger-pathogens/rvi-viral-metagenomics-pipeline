
process PARSE_KD_LOG {
    label 'mem_1'
    label 'time_1'

    conda 'conda-forge::python=3.10.2'
    container 'quay.io/biocontainers/python:3.10.2'

    publishDir enabled: params.publish_trimmed_reads, mode: 'copy', pattern: "${output_txt}", path: "${params.outdir}/kneaddata/"

    input:
    path(kd_logs)

    output:
    path(output_txt)

    script:
    output_txt="kneaddata_filtered_reads_report.txt"
    count_read_script = "${projectDir}/bin/count_reads_in_kd_log.py"
    """
    python3 ${count_read_script} *_1_kneaddata.log ${output_txt}
    """
}
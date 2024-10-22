process KRAKEN2 {
    tag "${meta.ID}"
    label 'cpu_4'
    label 'mem_8'
    label 'time_12'

    publishDir "${params.outdir}/${meta.ID}/kraken2", mode: 'copy', overwrite: true, pattern: "*.tsv"

    container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'

    input:
    tuple val(meta), path(reads_1), path(reads_2), path(kraken2_db)

    output:
    tuple val(meta), path(kreportout),  emit: kraken2_report
    tuple val(meta), path(ksamreportout),  emit: kraken2_sample_report

    script:
    kreportout = "${meta.ID}_kraken_report.tsv"
    ksamreportout = "${meta.ID}_kraken_sample_report.tsv"
    """
    kraken2 --db "${kraken2_db}" \
            --threads ${task.cpus} \
            --output "${kreportout}" \
            --use-names \
            --report "${ksamreportout}" \
            --report-zero-counts \
            --paired "${reads_1}" "${reads_2}" 2> kraken2.err
    status=\${?}
    if [ \${status} -gt 0 ] ; then
        # try and catch known errors from the stored stdout stream
        ## none known so far; keep this for potential future cases
        # if not caught known exception, process should not have exited yet - do it now with stored exit status
        cat kraken2.err 1>&2 && exit \${status}
    else
        # try and catch known warnings from the stored stdout stream when not causing non-zero exit code
        ## no sequence reads processed, meaning empty read input - exit 7
        grep '0 sequences (0.00 Mbp) processed' kraken2.err \
          && [ ! -s "${kreportout}" ] && cat kraken2.err 1>&2 && exit 7
        # NB: in case the *kraken_report.tsv file is missing not due to the above, nextflow will error out as expecting it as ouput file
        cat kraken2.err 1>&2
    fi
    """
}

process KRAKEN2_GET_CLASSIFIED {
    tag "${meta.ID}"
    label 'cpu_4'
    label 'mem_8'
    label 'time_12'

    publishDir "${params.outdir}/${meta.ID}/kraken2", mode: 'copy', overwrite: true, pattern: "*.tsv"
    publishDir "${params.outdir}/${meta.ID}/kraken2", mode: 'copy', overwrite: true, pattern: "classified.fastq"

    container 'quay.io/biocontainers/kraken2:2.1.3--pl5321hdcf5f25_0'

    input:
    tuple val(meta), path(reads_1), path(reads_2), path(kraken2_db)

    output:
    tuple val(meta), path("*kraken_report.tsv"),  emit: kraken2_report
    tuple val(meta), path("*kraken_sample_report.tsv"),  emit: kraken2_sample_report
    tuple val(meta), path("*_classified.fastq"),  emit: classified_reads
    tuple val(meta), path("*_unclassified.fastq"),  emit: unclassified_reads

    script:
    kraken2_id = "${meta.ID}".replaceAll('#','_')
    """
    kraken2 --db "${kraken2_db}" \
            --threads ${task.cpus} \
            --classified-out "${kraken2_id}#_classified.fastq" --unclassified-out "${kraken2_id}#_unclassified.fastq" \
            --output "${meta.ID}_kraken_report.tsv" \
            --use-names \
            --report "${meta.ID}_kraken_sample_report.tsv" \
            --report-zero-counts \
            --paired "${reads_1}" "${reads_2}"
    """
}

process COMPRESS_READS {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_1'
    label 'time_1'

    publishDir "${params.outdir}/${meta.ID}/kraken2", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(reads_1), path(reads_2)
    
    output:
    tuple val(meta), path("*_classified.fastq.gz"),  emit: classified_reads
    tuple val(meta), path("*_unclassified.fastq.gz"),  emit: unclassified_reads

    script:
    """
    gzip -fk *.fastq
    """
}

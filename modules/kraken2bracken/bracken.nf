process BRACKEN {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_1'
    label 'time_1'

    publishDir "${params.outdir}/${meta.ID}/bracken", mode: 'copy', overwrite: true

    container 'quay.io/biocontainers/bracken:2.8--py310h0dbaff4_1'

    input:
    tuple val(meta), path(kraken2_sample_report), path(kmer_distrib)

    output:
    tuple val(meta), path("*.bracken"),  emit: bracken_report
    tuple val(meta), path("*_kraken_sample_report_bracken_species.tsv"),  emit: kraken_style_bracken_report

    script:
    // biocontainer doesn't expose the script est_abundance.py on PATH :(
    """
    /usr/local/bin/src/est_abundance.py -i ${kraken2_sample_report} \
                                        -k ${kmer_distrib} \
                                        -o ${meta.ID}.bracken \
                                        -l ${params.kraken2bracken_classification_level} \
                                        -t ${params.kraken2bracken_threshold} \
                                        2> bracken.err
    status=\${?}
    if [ \${status} -gt 0 ] ; then
        # try and catch known exceptions from the stored stderr stream
        grep 'Error: no reads found. Please check your Kraken report' bracken.err && cat bracken.err 1>&2 && exit 7
        # if not caught known exception, process should not have exited yet - do it now spitting back the stored stderr and exit status
        cat bracken.err 1>&2 && exit \${status}
    else
        cat bracken.err 1>&2
    fi
    """
}

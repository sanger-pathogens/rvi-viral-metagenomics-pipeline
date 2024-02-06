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
                                        -t ${params.kraken2bracken_threshold}
    """
}

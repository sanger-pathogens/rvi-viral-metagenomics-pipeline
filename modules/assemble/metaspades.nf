process METASPADES {
    tag "${meta.ID}"
    label 'cpu_16'
    label "mem_${params.metaspades_base_mem_gb}"
    label 'time_12'

    container 'quay.io/biocontainers/spades:3.15.5--h95f258a_1'

    publishDir "${params.outdir}/${basemetaID}/metaspades/", mode: 'copy', overwrite: true, pattern: 'contigs.fasta', saveAs: { filename -> "${meta.ID}_contigs.fa" }
    publishDir "${params.outdir}/${basemetaID}/metaspades/", mode: 'copy', overwrite: true, pattern: 'scaffolds.fasta', saveAs: { filename -> "${meta.ID}_scaffolds.fa" }

    input:
    tuple val(meta), path(R1), path(R2)

    output:
    tuple val(meta), path("contigs.fasta"), path("scaffolds.fasta"), emit: contigs_channel
    path("spades.log"), emit: log_channel

    script:
    splitmeta = "${meta.ID}".split("_subsampled-")
    basemetaID = "${splitmeta[0]}"
    """
    metaspades.py -1 ${R1} -2 ${R2} -o . --tmp-dir tmp/
    """
}  
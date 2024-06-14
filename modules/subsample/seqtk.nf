process SUBSAMPLE_SEQTK {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_1' // memory use is determined when using seqtk sample with -2 flag; subsample_limit of 10M results in 222MB peak vmem
    label 'time_1'

    publishDir "${params.outdir}/${meta.ID}/subsampled_${subsample_limit}_iteration_${iteration}", mode: 'copy', overwrite: true, pattern: "*log.txt"

    container 'quay.io/biocontainers/seqtk:1.4--he4a0461_2'

    input:
    tuple val(meta), path(read_1), path(read_2)
    val(subsample_limit)
    each(iteration)

    output:
    tuple val(meta), path(subsampled_1), path(subsampled_2), val(seed), val(iteration), val(subsample_limit), emit: read_ch
    path("seqtk_log.txt")

    script:
    subsampled_1 = "${meta.ID}_subsampled_1.fastq.gz"
    subsampled_2 = "${meta.ID}_subsampled_2.fastq.gz"
    seed = iteration + params.subsample_seed - 1
    """
    seqtk sample -2 -s${seed} ${read_1} ${subsample_limit} | gzip > ${subsampled_1}
    seqtk sample -2 -s${seed} ${read_2} ${subsample_limit} | gzip > ${subsampled_2}
    echo "subsampling seed used ${seed}" > seqtk_log.txt
    """
}
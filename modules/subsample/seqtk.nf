process SUBSAMPLE_SEQTK {
    tag "${meta.ID}"
    label 'cpu_1'
    label 'mem_500M'
    label 'time_1'

    publishDir "${params.outdir}/${meta.ID}/subsampled_iteration_${iteration}", mode: 'copy', overwrite: true, pattern: "*log.txt"

    container '/software/pathogen/images/seqtk-1.3--ha92aebf_0.simg'

    input:
    tuple val(meta), path(read_1), path(read_2)
    each(seed)

    output:
    tuple val(meta), path(subsampled_1), path(subsampled_2), val(seed), val(iteration),  emit: read_ch
    path("seqtk_log.txt")

    script:
    subsampled_1 = "${meta.ID}_subsampled_1.fastq"
    subsampled_2 = "${meta.ID}_subsampled_2.fastq"
    iteration = seed - params.subsample_seed + 1
    """
    seqtk sample -s${seed} ${read_1} ${params.subsample_limit} > ${subsampled_1}
    seqtk sample -s${seed} ${read_2} ${params.subsample_limit} > ${subsampled_2}
    echo "subsampling seed used ${seed}" > seqtk_log.txt
    """
}
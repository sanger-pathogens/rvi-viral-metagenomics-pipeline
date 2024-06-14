include { SUBSAMPLE_ITER } from './subsample.nf'
include { METASPADES } from '../modules/assemble/metaspades.nf'

workflow ASSEMBLE_META {
    // run metaspades on data set with at most X reads to avoid loss of quality when too much data fed in (statistical inconsistency)
    take:
    meta_reads // tuple val(meta), path(R1), path(R2)

    main:
    metaspades_subsample_limit_ch = Channel.value( params.metaspades_subsample_limit ) 
    SUBSAMPLE_ITER(meta_reads, metaspades_subsample_limit_ch)
    | METASPADES


    emit:
    contigs_channel = METASPADES.out.contigs_channel
}
include { SUBSAMPLE_SEQTK } from '../modules/subsample/seqtk.nf'

workflow SUBSAMPLE_ITER {

    take:
    paired_channel // tuple val(meta), path(read_1), path(read_2)
    subsample_limit_ch // val(int)

    main:
    // if below limit branch into a seperate channel where no subsampling is done and instead skips the step
    // if number of reads is above subsample limit put to a channel branch into a channel for subsampling
    // and make new meta map to add _subsampledXXz-n suffix to meta.ID in subsampled channel branch only
    paired_channel.combine(subsample_limit_ch)
    .branch{ meta, read_1, read_2, subsample_limit ->
        def num_limit = subsample_limit.toString()
        shortstr_limit = num_limit.replaceFirst(/000000000$/, "G").replaceFirst(/000000$/, "M").replaceFirst(/000$/, "k")
        meta_new = [:]
        meta_new.ID = "${meta.ID}_subsampled${shortstr_limit}-${iteration}"
        def read_count = read_1.countFastq()
        needs_subsampling: read_count > subsample_limit
            return tuple ( meta_new, read_1, read_2 )
        already_below_subsample: true
            return tuple ( meta, read_1, read_2 )
    }.set{ subsampling_check }

    iterations = (1 .. params.subsample_iterations).toList()

    SUBSAMPLE_SEQTK(subsampling_check.needs_subsampling, subsample_limit_ch, iterations)

    SUBSAMPLE_SEQTK.out.read_ch
    .mix(subsampling_check.already_below_subsample)
    .set{ final_read_channel }

    emit:
    final_read_channel
}
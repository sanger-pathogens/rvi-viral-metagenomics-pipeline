include { SUBSAMPLE_SEQTK } from '../modules/subsample/seqtk.nf'
include { seed_list } from '../modules/subsample/subsample_utils.nf'

workflow SUBSAMPLE_ITER {

    take:
    // TO DO: where to get PAIRED_READ_COUNT?
    paired_channel // tuple val(meta), path(output1), path(output2), env(PAIRED_READ_COUNT)

    //reads the length of read_1 file (will be paired as output from trimmomatic) and divides by 4 to give number of reads. 
    //if number of reads is above subsample limit put to a channel branch into a channel for subsampling
    //if below limit branch into a seperate channel where no subsampling is done and instead skips the step
    TRIM_READS.out.paired_channel.branch{ meta, read_1, read_2, read_1_file_length ->
        def read_count = read_1_file_length.toInteger() / 4
        meta_new = [:]
        meta_new = meta
        meta_new.total_reads = read_count
        needs_subsampling: meta_new.total_reads > params.subsample_limit
            return tuple( meta, read_1, read_2 )
        already_below_subsample: true
            return tuple ( meta, read_1, read_2)
    }.set{ subsampling_check }

    iteration_seed = seed_list()

    SUBSAMPLE_SEQTK(subsampling_check.needs_subsampling, iteration_seed)

    //map to add _iteration_ before mix into ID so non-subsampled do not have iterations
    SUBSAMPLE_SEQTK.out.read_ch.map{meta, read_1 , read_2 , seed, iteration ->
        meta_new = [:]
        meta_new.ID = "${meta.ID}_iteration_${iteration}"
        [meta_new, read_1, read_2]
    }.mix(subsampling_check.already_below_subsample).set{ final_read_channel }

    emit:
    final_read_channel
}
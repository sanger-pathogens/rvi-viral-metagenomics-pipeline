include { SUBSAMPLE_SEQTK } from '../modules/subsample/seqtk.nf'

def fastqCount(List reads) {
    def counts = []

    /*
    Rather than throwing an error that always reports read1 at fault
    loop over the reads and error on the correct pair
    */

    for (read in reads) {
        try {
            def count = read.countFastq()
            counts << count
        } catch (EOFException eofException) {
            log.error("Fastq ${read} could not be read: ${eofException}")
            System.exit(1)
        } catch (Exception e) { 
            //fallback incase other error
            log.error("Unexpected error reading Fastq ${read}: ${e}")
            System.exit(1) or other error handling
        }
    }

    // Check if all counts are equal
    if (counts.unique().size() != 1) {
        log.error("Fastq counts are uneven: ${reads[0]}: ${counts[0]} vs ${reads[1]}: ${counts[1]}")
        System.exit(1)
    }

    return counts[0]
}

workflow SUBSAMPLE_ITER {

    take:
    paired_channel // tuple val(meta), path(read_1), path(read_2)
    subsample_limit_ch // val(int)

    main:

    paired_channel.map{ meta, read_1, read_2 -> [ meta, read_1, read_2, fastqCount([read_1, read_2])]}.set{ fastQPass_ch }

    //if number of reads is above subsample limit put to a channel branch into a channel for subsampling
    //if below limit branch into a seperate channel where no subsampling is done and instead skips the step
    fastQPass_ch.combine(subsample_limit_ch)
    .branch{ meta, read_1, read_2, read_count, subsample_limit ->
        needs_subsampling: read_count > subsample_limit
            return tuple ( meta, read_1, read_2 )
        already_below_subsample: true
            return tuple ( meta, read_1, read_2 )
    }.set{ subsampling_check }

    iterations = (1 .. params.subsample_iterations).toList()

    SUBSAMPLE_SEQTK(subsampling_check.needs_subsampling, subsample_limit_ch, iterations)

    //map to add _subsampled-$n before mix into ID so non-subsampled do not have iterations
    SUBSAMPLE_SEQTK.out.read_ch.map{ meta, read_1, read_2, seed, iteration, subsample_limit ->
        def num_limit = (subsample_limit * 2).toString()
        shortstr_limit = num_limit.replaceFirst(/000000000$/, "G").replaceFirst(/000000$/, "M").replaceFirst(/000$/, "k")
        meta_new = [:]
        meta_new.ID = "${meta.ID}_subsampled${shortstr_limit}-${iteration}"
        [meta_new, read_1, read_2]
    }.mix(subsampling_check.already_below_subsample).set{ final_read_channel }

    emit:
    final_read_channel
}
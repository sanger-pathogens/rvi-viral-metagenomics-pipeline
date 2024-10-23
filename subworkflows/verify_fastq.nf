def fastqCount(List reads) {
    def counts = []
    def errorOccurred = false

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
            errorOccurred = true
        } catch (Exception e) { 
            //fallback incase other error
            log.error("Unexpected error reading Fastq ${read}: ${e}")
            errorOccurred = true
        }
    }

    //exit before comparing the -1 found above
    if (errorOccurred) {
        return -1  // Return a special value to indicate an error
    }

    // Finally check if all counts are equal
    if (counts.unique().size() != 1) {
        log.error("Fastq counts are uneven: ${reads[0]}: ${counts[0]} vs ${reads[1]}: ${counts[1]}")
        return -1
    }

    return counts[0]
}

workflow VERIFY_FASTQ {
    take:
    paired_channel

    main:
    //first check error method is set up correctly
    def validModes = ['ignore', 'only_unreadable', 'exit_on_error']

    // Validate the fastq_error_handling_mode parameter
    if (!validModes.contains(params.fastq_error_handling_mode)) {
        throw new IllegalArgumentException("Invalid fastq_error_handling_mode: ${params.fastq_error_handling_mode}. Must be one of ${validModes}")
    }


    paired_channel.map{ meta, read_1, read_2 -> 
    def readCount = fastqCount([read_1, read_2])
    [ meta, read_1, read_2, readCount]
    }
    | branch { 
        passed:         it[3] > params.minimum_fastq_reads
        belowReadCount: it[3] >= 0 && it[3] < params.minimum_fastq_reads //filter the readCount to be above minimum
        errors:         it[3] == -1 //extract fails
    }
    | set{ fastQPass_ch }

    if (params.fastq_error_handling_mode == 'only_unreadable') {
        fastQPass_ch.belowReadCount
        | map{ it -> log.warn("Fastq counts are below limit ${params.minimum_fastq_reads} and so are excluded - ${it[0]}: ${it[3]}") }
    } else {
        fastQPass_ch.belowReadCount
        | map{ it -> log.error("Fastq counts are below limit ${params.minimum_fastq_reads} and so are excluded - ${it[0]}: ${it[3]}") }
    }
    
    def errors = (params.fastq_error_handling_mode == 'only_unreadable') ?  fastQPass_ch.errors : fastQPass_ch.belowReadCount.mix(fastQPass_ch.errors)

    if (params.fastq_error_handling_mode != 'ignore') {
        errors //add in all errors
        | count()
        | map{ it -> if (it > 0) { System.exit(1) } }
    }

    emit:
    verified_fastq_ch = fastQPass_ch.passed
}
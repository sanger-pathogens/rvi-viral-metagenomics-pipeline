include { COLLATE_CRAM; FASTQ_FROM_COLLATED_BAM } from '../modules/irods/samtools.nf'
include { BATON } from '../modules/irods/baton.nf'
include { JSON_PREP; JSON_PARSE } from '../modules/irods/jq.nf'
include { RETRIEVE_CRAM } from '../modules/irods/retrieve.nf'

workflow IRODS_EXTRACT {
    
    take:
    tuple study, runid

    main:
    JSON_PREP(input_path)
    | BATON
    | JSON_PARSE

    JSON_PARSE.out.paths.splitText().map{ cram_path ->
        def meta = [:]
        meta.ID = cram_path.split("/")[-1].split(".cram")[0]
        [ meta, cram_path ]
    }.set{ meta_cram_ch }

    Channel.fromPath("${params.outdir}/*#*/raw_fastq/*_1.fastq.gz").map{ raw_fastq_path ->
        ID = raw_fastq_path.simpleName.split("_1")[0]
    }.set{ existing_id }

    meta_cram_ch.branch{ meta, cram_path ->
        exists: meta.ID in existing_id
        return [ meta, cram_path ]
        absent: meta.ID !in existing_id
        return [ meta, cram_path ]
    }.set{ branched_meta_cram }

    RETRIEVE_CRAM(branched_meta_cram.absent)
    | COLLATE_CRAM
    | FASTQ_FROM_COLLATED_BAM

    FASTQ_FROM_COLLATED_BAM.out.remove_channel.flatten()
            .filter(Path)
            .map { it.delete() }

    emit:
    reads_ch = FASTQ_FROM_COLLATED_BAM.out.fastq_channel
}
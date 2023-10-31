include { COLLATE_CRAM; FASTQ_FROM_CBAM } from '../modules/irods/samtools.nf'
include { BATON } from '../modules/irods/baton.nf'
include { JSON_PREP; JSON_PARSE } from '../modules/irods/jq.nf'
include { RETRIEVE_CRAM } from '../modules/irods/retrieve.nf'

workflow IRODS_EXTRACT {
    
    take:
    input_path //assumes for ease of development it is a study name

    main:
    JSON_PREP(input_path)
    | BATON
    | JSON_PARSE

    JSON_PARSE.out.splitText().map{ cram_path ->
        def meta = [:]
        meta.ID = file(cram_path).simpleName
        [ meta, cram_path ]
    }.set{ meta_cram_ch }

    existing_files = Channel.fromPath("${params.results_dir}/*#*/raw_fastq/*_1.fastq.gz")

    existing_files.map{ assembly_path ->
        ID = assembly_path.simpleName.split("_1")[0]
    }.set{ existing_id }

    meta_cram_ch.branch{ meta, cram_path ->
        exists: meta.ID in existing_id
        return [ meta, cram_path ]
        absent: meta.ID !in existing_id
        return [ meta, cram_path ]
    }.set{ branched_meta_cram }

    RETRIEVE_CRAM(branched_meta_cram.absent)
    | COLLATE_CRAM
    | FASTQ_FROM_CBAM

    RETRIEVE_CRAM.out.path_channel.join(COLLATE_CRAM.out.bam_channel).join(FASTQ_FROM_CBAM.out.ready_channel).set{ waste_channel }

    waste_channel.flatten()
            .filter(Path)
            .view()
            .map { it.delete() }

    emit:
    reads_ch = FASTQ_FROM_CBAM.out.fastq_channel
}
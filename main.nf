#!/usr/bin/env nextflow

// GROOVY HELPERS
include { validate_parameters         } from './modules/validate_params.nf'

//
// SUBWORKFLOWS
//
include { COMBINE_IRODS ; 
          COMBINE_READS        } from "./assorted-sub-workflows/combined_input/subworkflows/combined_input.nf"
include { IRODS_EXTRACTOR      } from "./assorted-sub-workflows/irods_extractor/subworkflows/irods.nf"
include { SUBSAMPLE_ITER       } from "./subworkflows/subsample.nf"
include { PREPROCESSING        } from "./subworkflows/preprocessing.nf"
include { ASSEMBLE_META        } from "./subworkflows/assemble.nf"
include { KRAKEN2BRACKEN       } from './subworkflows/kraken2bracken.nf'
include { ABUNDANCE_ESTIMATION } from './subworkflows/abundance_estimation.nf'

def logo = NextflowTool.logo(workflow, params.monochrome_logs)

log.info logo

def printHelp() {
    NextflowTool.help_message("${workflow.ProjectDir}/schema.json", 
                              ["${workflow.ProjectDir}/assorted-sub-workflows/combined_input/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/irods_extractor/schema.json",
                               "${workflow.ProjectDir}/modules/preprocessing/schema.json",
                               "${workflow.ProjectDir}/modules/subsample/schema.json",
                               "${workflow.ProjectDir}/modules/assemble/schema.json",
                               "${workflow.ProjectDir}/modules/kraken2bracken/schema.json",
                               "${workflow.ProjectDir}/modules/abundance_estimation/schema.json"],
    params.monochrome_logs, log)
}

workflow {
    if (params.help) {
        printHelp()
        exit 0
    }
    if (params.help_all) {
        printHelpAll()
        exit 0
    }

    validate_parameters()

    COMBINE_IRODS
    | IRODS_EXTRACTOR
    | COMBINE_READS

    initial_subsample_limit_ch = Channel.of( params.initial_subsample_limit ) 
    SUBSAMPLE_ITER(COMBINE_READS.out.all_reads_ready_to_map_ch, initial_subsample_limit_ch)

    SUBSAMPLE_ITER.out.final_read_channel
    .set{ capped_reads_ch }

    if (params.skip_preprocessing){
        capped_reads_ch = ready_reads_ch
    } else {
        PREPROCESSING(capped_reads_ch)

        PREPROCESSING.out.paired_channel
        .set{ ready_reads_ch }
    }

    ASSEMBLE_META(ready_reads_ch)

    ABUNDANCE_ESTIMATION(ready_reads_ch)

    KRAKEN2BRACKEN(ready_reads_ch)
}

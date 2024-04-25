#!/usr/bin/env nextflow

// GROOVY HELPERS
include { validate_parameters         } from './modules/validate_params.nf'

//
// SUBWORKFLOWS
//
include { COMBINE_IRODS ; 
          COMBINE_READS               } from './assorted-sub-workflows/combined_input/subworkflows/combined_input.nf'
include { IRODS_EXTRACTOR             } from './assorted-sub-workflows/irods_extractor/subworkflows/irods.nf'
include { PREPROCESSING               } from "./subworkflows/preprocessing.nf"
include { ASSEMBLE_META               } from "./subworkflows/assemble.nf"
include { ABUNDANCE_ESTIMATION        } from './subworkflows/abundance_estimation.nf'
include { KRAKEN2BRACKEN              } from './subworkflows/kraken2bracken.nf'

def logo = NextflowTool.logo(workflow, params.monochrome_logs)

log.info logo

def printHelp() {
    NextflowTool.help_message("${workflow.ProjectDir}/schema.json", 
                              ["${workflow.ProjectDir}/assorted-sub-workflows/combined_input/schema.json",
                               "${workflow.ProjectDir}/assorted-sub-workflows/irods_extractor/schema.json"],
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
    | PREPROCESSING
    
    ASSEMBLE_META(PREPROCESSING.out.paired_channel)

    ABUNDANCE_ESTIMATION(PREPROCESSING.out.paired_channel)

    KRAKEN2BRACKEN(PREPROCESSING.out.paired_channel)
}

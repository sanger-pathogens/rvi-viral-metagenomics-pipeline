#!/usr/bin/env nextflow

//
// MODULES
//

include { VALIDATE_PARAMETERS                                                                                                                           } from './modules/validate_params.nf'

//
// SUBWORKFLOWS
//
include { INPUT_CHECK    } from './subworkflows/input_check'


def printHelp() {
    log.info """
    Usage:
    nextflow run . --manifest <path to manifest> --reference <path to reference>

    Options:
      --manifest                   Manifest containing paths to fastq files (mandatory)
      --help                       print this help message (optional)
    """.stripIndent()
}

workflow {
    if (params.help) {
        printHelp()
        exit 0
    }

    //perform precheck
    VALIDATE_PARAMETERS()
    
    manifest = file(params.manifest)

    INPUT_CHECK(manifest)
}
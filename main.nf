#!/usr/bin/env nextflow

//
// MODULES
//

include { VALIDATE_PARAMETERS  } from './modules/validate_params.nf'
include { KNEADDATA            } from "./modules/kneaddata.nf"


//
// SUBWORKFLOWS
//
include { INPUT_CHECK    } from './subworkflows/input_check.nf'
include { ABUNDANCE_ESTIMATION   } from './subworkflows/abundance_estimation.nf'


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
    | KNEADDATA


    KNEADDATA.out.paired_channel.map{ meta, R1 , R2 -> 
        sample_id = meta.ID
        [sample_id, R1, R2 ]
    }.set{ meta_removed_channel }

    ABUNDANCE_ESTIMATION(meta_removed_channel)

}
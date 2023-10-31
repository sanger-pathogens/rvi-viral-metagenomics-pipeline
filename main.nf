#!/usr/bin/env nextflow

//
// MODULES
//

include { VALIDATE_PARAMETERS  } from './modules/validate_params.nf'
include { KNEADDATA            } from "./modules/kneaddata.nf"
include { METASPADES           } from "./modules/metaspades.nf"


//
// SUBWORKFLOWS
//
include { INPUT_CHECK    } from './subworkflows/input_check.nf'
include { ABUNDANCE_ESTIMATION   } from './subworkflows/abundance_estimation.nf'
include { KRAKEN2BRACKEN         } from './subworkflows/kraken2bracken.nf'
include { IRODS_EXTRACT    } from './subworkflows/irods.nf'


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

    IRODS_EXTRACT("${params.input_name}")
    | KNEADDATA
    | METASPADES


    KNEADDATA.out.paired_channel.map{ meta, R1 , R2 -> 
        sample_id = meta.ID
        [sample_id, R1, R2 ]
    }.set{ meta_removed_channel }

    ABUNDANCE_ESTIMATION(meta_removed_channel)

    KNEADDATA.out.paired_channel.map{ meta, R1 , R2 -> 
        meta_new = [:]
        meta_new.id = meta.ID
        reads = tuple(R1, R2)
        [meta_new, reads ]
    }.set{ combined_reads_channel }


    KRAKEN2BRACKEN(combined_reads_channel)
}
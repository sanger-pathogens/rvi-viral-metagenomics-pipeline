#!/usr/bin/env nextflow

// GROOVY HELPERS
include { validate_parameters } from './modules/validate_params.nf'

//
// MODULES
//
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
    nextflow run main.nf

    Options:
      --study                      Name or ID of sequencing study including read data to use as pipeline input (mandatory)
      --runid                      ID of sequencing run including read data to use as pipeline input (mandatory)
      --outdir                     Specify output directory [default: ./results] (optional)
      --help                       Print this help message (optional)
    """.stripIndent()
}

workflow {
    if (params.help) {
        printHelp()
        exit 0
    }

    validate_parameters()

    Channel.of([params.study, params.runid]).set{ input_irods_ch } 

    IRODS_EXTRACT(input_irods_ch)
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

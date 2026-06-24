#!/usr/bin/env nextflow

// GROOVY HELPERS
include { validate_parameters         } from './modules/validate_params.nf'

//
// SUBWORKFLOWS
//
include { MIXED_INPUT         } from './rvi_toolbox/subworkflows/mixed_input.nf'
include { VERIFY_FASTQ         } from "./rvi_toolbox/subworkflows/verify_fastq.nf"
include { SUBSAMPLE_ITER       } from "./rvi_toolbox/subworkflows/subsample.nf"
include { PREPROCESSING        } from "./rvi_toolbox/subworkflows/preprocessing.nf"
include { ASSEMBLE_META        } from "./rvi_toolbox/subworkflows/assemble.nf"
include { KRAKEN2BRACKEN       } from './rvi_toolbox/subworkflows/kraken2bracken.nf'
include { ABUNDANCE_ESTIMATION } from './rvi_toolbox/subworkflows/abundance_estimation.nf'
include { GENOMAD_CLASSIFY     } from './rvi_toolbox/subworkflows/genomad.nf'
include { VRHYME_BIN           } from './rvi_toolbox/subworkflows/vrhyme.nf'
include { VIRAL_MSWEEP         } from './rvi_toolbox/subworkflows/msweep.nf'

def logo = NextflowTool.logo(workflow, params.monochrome_logs)

log.info logo

def printHelp() {
    NextflowTool.help_message("${workflow.ProjectDir}/schema.json", 
                              ["${workflow.ProjectDir}/rvi_toolbox/subworkflows/irods.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/mixed_input.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/preprocessing.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/subsample.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/assemble.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/kraken2bracken.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/abundance_estimation.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/genomad.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/vrhyme.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/msweep.json"],
    params.monochrome_logs, log)
}

workflow {
    if (params.help) {
        printHelp()
        exit 0
    }

    validate_parameters()

    
    MIXED_INPUT
    | VERIFY_FASTQ

    initial_subsample_limit_ch = Channel.value( params.initial_subsample_limit )
    SUBSAMPLE_ITER(VERIFY_FASTQ.out.verified_fastq_ch, initial_subsample_limit_ch)

    SUBSAMPLE_ITER.out.final_read_channel
    .set{ capped_reads_ch }

    if (params.skip_preprocessing){
        ready_reads_ch = capped_reads_ch
    } else {
        PREPROCESSING(capped_reads_ch)

        PREPROCESSING.out.out_ch
        .set{ ready_reads_ch }
    }

    ASSEMBLE_META(ready_reads_ch)

    GENOMAD_CLASSIFY(ASSEMBLE_META.out.contigs_channel)

    VRHYME_BIN(
        GENOMAD_CLASSIFY.out.virus_fna,
        GENOMAD_CLASSIFY.out.virus_summary,
        ready_reads_ch
    )

    ABUNDANCE_ESTIMATION(ready_reads_ch)

    KRAKEN2BRACKEN(ready_reads_ch)
    
    VIRAL_MSWEEP(ready_reads_ch)
}

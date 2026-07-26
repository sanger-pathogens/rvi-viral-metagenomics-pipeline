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
include { ASSEMBLE_META as ASSEMBLE_TARGETED } from "./rvi_toolbox/subworkflows/assemble.nf"
include { KRAKEN2BRACKEN       } from './rvi_toolbox/subworkflows/kraken2bracken.nf'
include { ABUNDANCE_ESTIMATION } from './rvi_toolbox/subworkflows/abundance_estimation.nf'
include { GENOMAD_CLASSIFY     } from './rvi_toolbox/subworkflows/genomad.nf'
include { VRHYME_BIN           } from './rvi_toolbox/subworkflows/vrhyme.nf'
include { TAXON_FILTER         } from './rvi_toolbox/subworkflows/taxon_filter.nf'
include { SCAFFOLD_ASSEMBLY    } from './rvi_toolbox/subworkflows/scaffold.nf'
include { REFBASED_REFINE      } from './rvi_toolbox/subworkflows/refbased_refine.nf'

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
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/taxon_filter.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/scaffold.json",
                               "${workflow.ProjectDir}/rvi_toolbox/subworkflows/refbased_refine.json"],
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

    // Shared by both branches below: reused as-is for the default metagenomic-discovery
    // flow's own abundance estimation, and (in assisted mode) as the source of each
    // sample's auto-selected reference genome - see SCAFFOLD_ASSEMBLY / ASSISTED_ASSEMBLY.md.
    ABUNDANCE_ESTIMATION(ready_reads_ch)

    if (params.assisted_denovo_assembly) {
        // Assisted de novo viral genome assembly mode: optional pre-assembly taxonomic
        // read filtering + a dedicated targeted assembly, reference-assisted scaffolding,
        // and align-call-refine consensus polishing - replacing the metagenomic-discovery
        // flow below entirely. See rvi_toolbox/subworkflows/ASSISTED_ASSEMBLY.md for full
        // details and every intentional divergence from Broad's WDL workflow.
        TAXON_FILTER(ready_reads_ch)

        ASSEMBLE_TARGETED(TAXON_FILTER.out.filtered_reads)

        SCAFFOLD_ASSEMBLY(ASSEMBLE_TARGETED.out.contigs_channel, ABUNDANCE_ESTIMATION.out.genome_info_file)

        REFBASED_REFINE(TAXON_FILTER.out.filtered_reads, SCAFFOLD_ASSEMBLY.out.scaffold_fasta)
    } else {
        ASSEMBLE_META(ready_reads_ch)

        GENOMAD_CLASSIFY(ASSEMBLE_META.out.contigs_channel)

        VRHYME_BIN(
            GENOMAD_CLASSIFY.out.virus_fna,
            GENOMAD_CLASSIFY.out.virus_summary,
            ready_reads_ch
        )

        KRAKEN2BRACKEN(ready_reads_ch)
    }
}

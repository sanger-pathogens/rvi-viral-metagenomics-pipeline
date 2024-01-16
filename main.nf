#!/usr/bin/env nextflow

// GROOVY HELPERS
include { validate_parameters         } from './modules/validate_params.nf'

//
// MODULES
//
include { KNEADDATA                   } from "./modules/kneaddata.nf"
include { METASPADES                  } from "./modules/metaspades.nf"


//
// SUBWORKFLOWS
//
include { INPUT_CHECK                 } from './subworkflows/input_check.nf'
include { ABUNDANCE_ESTIMATION        } from './subworkflows/abundance_estimation.nf'
include { KRAKEN2BRACKEN              } from './subworkflows/kraken2bracken.nf'
include { CHECK_EXISTS_IRODS_EXTRACT  } from './subworkflows/check_exists_irods_extract.nf'
include { COMBINE_IRODS               } from './subworkflows/combined_input.nf'

def printHelp() {
    log.info """
    Usage:
    nextflow run main.nf

    Options:
      --studyid                    ID of sequencing study including read data to use as pipeline input (mandatory)
      --runid                      ID of sequencing run including read data to use as pipeline input (mandatory)
      --laneid                     ID of sequencing lane (as in a lane within of a flow cell) including read data to use as pipeline input (mandatory)
      --plexid                     ID of sequencing lane multiplex tag index including read data to use as pipeline input (mandatory)

      NB: the real lane id is different from the the so-called \"lane\" id, a term commonly used in Sanger referring to this sequencing run output unit, usually labelled with this syntax: 48106_1#83.
      In this, the run id is 48106, the (real) lane id is 1 and the plex id is 83.

    Output parameters
      --outdir                     Specify output directory [default: ./results] (optional)
      --publish_raw_reads          Should raw .fastq files (freshly converted from iRODS-downloaded .cram files) be saved? [default: false] (optional)
      --publish_trimmed_reads      Should Kneaddata-filtered .fastq files be saved? [default: true] (optional)

    General options:
      --help                       Print summary of main parameters and options (optional)
      --help_all                   Print extensive list of parameters and options (optional)
    """.stripIndent()
}

def printHelpAll() {
    printHelp()
    log.info """

    Procesing options:
     iRODS extractor options:
      --cleanup_intermediate_files_irods_extractor = false
     Kraken2/Bracken options:
      --off_target_db = "/data/pam/software/RVI_DB/homo_sapiens"
     Kneaddata options:
      --sequencer_source = "NexteraPE"
      --trimmomatic_options = "ILLUMINACLIP:/data/pam/software/trimmomatic/adapter_fasta/solexa-with-nextseqPR-adapters.fasta:2:10:7:1 CROP:151 SLIDINGWINDOW:4:20 MINLEN:100"
      --kneaddata_threads = 4
     MetaSPAdes options:
      --metaspades_base_mem_gb = 16
     Abundance estimation (inStrain) options:
      --skip_qc_abundance_estimation = true
      --genome_dir_abundance_estimation = "/data/pam/team162/shared/gtdb_genomes_reps_r207/gtdb_genomes_reps_r207_genome_dir"
      --sourmash_db_abundance_estimation = "/data/pam/team162/shared/sourmash_db/gtdb-rs207.genomic-reps.dna.k31.zip"
      --bowtie2_samtools_threads_abundance_estimation = 4
      --instrain_threads_abundance_estimation = 4
      --instrain_full_output_abundance_estimation = false
      --instrain_quick_profile_abundance_estimation = false
      --cleanup_intermediate_files_abundance_estimation = true
      --instrain_quick_profile_abundance_estimation = false
      --bowtie2_samtools_only_abundance_estimation = false
      --bmtagger_db_abundance_estimation = "/data/pam/software/BMTAGGER_INDEX"
      --bmtagger_host_abundance_estimation = "T2T-CHM13v2.0"
      --publish_host_reads_abundance_estimation = false
                                   Should host reads detected by metaWRAP QC (as a prior step to Abundance estimation/inStrain subworkflow) be saved? [default: false] (optional)
                                   NB: there shouldn't be much or any such reads due to prior filtering with Kneaddata.
    """.stripIndent()
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

    COMBINE_IRODS()
  
    CHECK_EXISTS_IRODS_EXTRACT(COMBINE_IRODS.out.input_irods_ch)
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

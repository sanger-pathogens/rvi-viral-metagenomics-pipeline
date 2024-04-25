include { KNEADDATA                   } from "../modules/preprocessing/kneaddata.nf"
include { TRIMMOMATIC                 } from "../modules/preprocessing/trimmomatic.nf"

workflow PREPROCESSING {

    take:
    paired_reads_channel 

    main:
    if (params.human_read_removal){
        KNEADDATA(paired_reads_channel)
        KNEADDATA.out.set{paired_channel}
    } else{
        TRIMMOMATIC(paired_reads_channel)
        TRIMMOMATIC.out.set{paired_channel}
    }

    emit:
    paired_channel
}
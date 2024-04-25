include { KNEADDATA                   } from "./modules/preprocessing/kneaddata.nf"
include { TRIMMOMATIC                 } from "./modules/preprocessing/trimmomatic.nf"

workflow PREPROCESSING {

    take:
    paired_channel 

    if (params.human_read_removal){
        KNEADDATA(paired_channel)
        KNEADDATA.out.set{final_read_channel}
    } else{
        TRIMMOMATIC(paired_channel)
        TRIMMOMATIC.out.set{final_read_channel}
    }

    emit:
    final_read_channel
}
include { KNEADDATA                   } from "../modules/preprocessing/kneaddata.nf"
include { TRIMMOMATIC                 } from "../modules/preprocessing/trimmomatic.nf"
include { PARSE_KD_LOG                 } from "../modules/preprocessing/parse_logs.nf"

workflow PREPROCESSING {

    take:
    paired_reads_channel 

    main:
    if (params.human_read_removal){
        KNEADDATA(paired_reads_channel)
        KNEADDATA.out.paired_channel.set{ paired_channel }

        KNEADDATA.out.kd_log_ch
        .collect()
        .dump(tag: 'ch_kd_logs')
        .set { ch_kd_logs }

        PARSE_KD_LOG(ch_kd_logs)
    } else{
        TRIMMOMATIC(paired_reads_channel)
        TRIMMOMATIC.out.paired_channel.set{ paired_channel }
    }

    emit:
    paired_channel
}
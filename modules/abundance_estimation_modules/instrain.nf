process INSTRAIN {
    tag "${meta.ID}"
    label 'mem_4'
    label 'time_queue_from_normal'

    container '/software/pathogen/images/instrain-1.6.4-c2.simg'

    if (params.instrain_full_output_abundance_estimation) { publishDir path: "${params.outdir}/${meta.ID}/instrain/", mode: 'copy', overwrite: true, pattern: "*_instrain_output" }
    if (params.instrain_quick_profile_abundance_estimation) { publishDir path: "${params.outdir}/${meta.ID}/instrain/", mode: 'copy', overwrite: true, pattern: "*_instrain_quick_profile_output" }
    publishDir "${params.outdir}/${meta.ID}/instrain/", mode: 'copy', overwrite: true, pattern: '*.tsv'
    
    input:
    tuple val(meta), path(sorted_bam), path(stb_file), path(genome_file)

    output:
    path("${meta.ID}_instrain_output"), optional: true
    path("${meta.ID}_instrain_quick_profile_output"), optional: true
    path("${genome_info_file}"), optional: true
    path(sorted_bam), emit: sorted_bam
    tuple val(meta), path("${workdir}"), emit: meta_workdir

    script:
    genome_info_file="${meta.ID}_genome_info.tsv"
    workdir="workdir.txt"
    """
    pwd > workdir.txt
    if ${params.instrain_quick_profile_abundance_estimation}
    then
        inStrain quick_profile ${sorted_bam} ${genome_file} -o ${meta.ID}_instrain_quick_profile_output -p ${task.cpus} -s ${stb_file}
    else
        inStrain profile ${sorted_bam} ${genome_file} -o ${meta.ID}_instrain_output -p ${task.cpus} -s ${stb_file} --skip_plot_generation ${params.instrain_profile_options}
    fi
    if ! ${params.instrain_full_output_abundance_estimation} && ! ${params.instrain_quick_profile_abundance_estimation}
    then
        mv ${meta.ID}_instrain_output/output/${meta.ID}"_instrain_output_genome_info.tsv" ./${meta.ID}"_genome_info.tsv"
    fi
    """
}

process GENERATE_STB {
    label 'cpu_1'
    label 'mem_1'
    label 'time_queue_from_normal'

    input:
    tuple val(meta), path(sourmash_genomes)

    output:
    tuple val(meta), path("*.stb"), emit: stb_ch

    script:
    """
    sed 's|\$|_genomic.fna.gz|g' $sourmash_genomes > genomes.txt
    grep -w -f genomes.txt ${params.stb_file_abundance_estimation} > ${meta.ID}_gtdb_subset.stb
    """
}

process FIX_OUTPUT {
    label 'cpu_1'
    label 'mem_1'
    label 'time_1'

    publishDir "${params.outdir}/${meta.ID}/instrain/", mode: 'copy', overwrite: true

    input:
    tuple val(meta), path(genome_info_file)

    output:
    tuple val(meta), path("*_genome_info_fixed.tsv"),  emit: fixed_output

    script:
    """
    ./fix_output.sh ${params.taxonomy_lookup}
    """
}

process GENERATE_INSTRAIN_SUMMARY {
    label 'cpu_1'
    label 'mem_1'
    label 'time_1'

    publishDir "${params.outdir}/abundance_summary", mode: 'copy', overwrite: true

    input:
    path(fixed_outputs)

    output:
    path("instrain_summary.tsv"),  emit: instrain_summary

    script:
    """
    ./combine_fixed_output.sh
    """
}

# RVI-pipeline

This bioinformatic pipeline is designed to automate the analysis of data from the production sequencing pipeline of the [RVI project](https://www.sanger.ac.uk/group/respiratory-virus-and-microbiome-initiative/), specifically dealing with short-read sequencing data generated from the bait-capture protocol for enrichment of viral DNA.

It is composed of several subworkflows:

- extraction of "raw" data and processing to ouptput high-quality data
    - "raw" i.e. NPG-processed short reads are downloaded from the iRODS storage platform based on their study, run, lane and plex identifier
    - this is followed by quality control and read filtering (including human read removal) using Kneaddata, which output is published i.e. written to the output folder
- Kraken2/Bracken (k-mer-based) taxonomic assignment and abundance estimation - by default searching a database covering all viral genomes in NCBI RefSeq + the human genome
- inStrain (reference read mapping-based) taxonomic assignment and abundance estimation - by default searching a database covering all viral genomes in RefSeq
- metaSPAdes de novo assembly into metagenomic genome bins i.e. metagenome-assembled genomes (MAGs); default behaviour is to subsample reads to a maximum of 1 million ahead of assembly.

## Input

The input is curretly specified as command-line parameters pointing to the sequencing "lanes" produced by the Sanger sequencing pipeline and stored on the iRODS server. This is generally achieved by specifying their study, run, lane and plex identifier. with this approach, only the first level (study) of input specification is mandataory, leading to downloading all data from this study. Queries to pick data/lanes from iRODS can be further tailored using various metadata fields, using a "manifest of lanes" CSV file to describe the queries. Another appraoch is to provide reads already present on disk through a "manifest of reads" CSV file. All these input appraoches are described in the Usage section via the pipeline help message.

We will soon introduce support for using a manifest as input, allowing batch and more flexible input specification.

It is important to note that although the pipeline input is specified as whole studies (or more refined searches based on run ID etc.), only data that does not already exist in the results directory is downloaded. This is checked at the time of starting the pipeline based on presence/absence of the trimmed_reads folder in the results directory (as specified by --outdir  parameter). Therefore it is important to re-use the same results directory to avoid redownloading and reanalysis of the same data. 

## Output

This pipeline will have a wide variety of results, which will be written in the output directory specified by the `--outdir` parameter (default name `result`/`), each with a directory sub-structure similar to the below:

```
results/
├── metadata_irods_queried_2024-05-03T16:05:12.235708+01:00.csv
├── 48843_1#1
│   ├── bracken
│   │   ├── 48843_1#1.bracken
│   │   ├── 48843_1#1_kraken_sample_report_bracken_species.tsv
│   │   └── 48843_1#1_report_bracken_species.mpa.txt
│   ├── instrain
│   │   └── 48843_1#1_genome_info.tsv
│   ├── kraken2
│   │   ├── 48843_1#1_kraken_report.tsv
│   │   └── 48843_1#1_kraken_sample_report.tsv
│   ├── metaspades
│   │   ├── 48843_1#1_contigs.fa
│   │   └── 48843_1#1_scaffolds.fa
│   └── trimmed_reads
│       ├── 48843_1#1_1_kneaddata_paired_1.fastq.gz
│       └── 48843_1#1_1_kneaddata_paired_2.fastq.gz
...
├── abundance_summary
│   ├── instrain_summary_tidynames.tsv
│   ├── instrain_summary.tsv
│   └── bracken_summary_report.tsv
├── mapping_rates
│   └── 2024-05-03T16:05:12.235708+01:00_mapping_rates.csv
└── pipeline_info
    ├── execution_report_2024-05-03_16-05-10.html
    ├── execution_timeline_2024-05-03_16-05-10.html
    ├── execution_trace_2024-05-03_16-05-10.txt
    └── pipeline_dag_2024-05-03_16-05-10.svg
```

Nextflow trace and other files describing the execution of the pipeline per sample and per process will be written in the `results/pipeline_info/` directory by default. 

The exit codes returned by the processes as reported in the trace file can help understand what may have caused some process failures. In particular, this pipeline catches errors from Kraken2, Bracken, metaSPAdes and inStrain that are due to no reads or too few reads being present in the input reads files; in these cases, the process will fail but exit with an error code 7.

Custom error codes:
- 7: no reads or too few reads in input
- 3: known segmentation fault error in metaSPAdes

A metadata file describing the data downloaded from IRODS will be written under the output folder. This metadata includes a path to the data on iRODS for later targeted retrieval as well as basic information such as read count in the CRAM file, reference used for CRAM compression, as well as sample name, ENA run/sample accession etc.

In the output folder you should also find one folder per Lane_ID, which will feature a folder for each of the analyses undertaken:

- `raw_fastq` contains the reads as directly unpacked from the CRAM file stored on IRODS; this output is optional as raw fastq files are not saved as output by default.
- `trimmed_reads` contains the human read-removed and adapter-trimmed reads output as ouput by Kneaddata, which are then used in the downstream processes.
- `instrain` contains the abundance estimation and population genomics profiling output from inStrain, a file ending with `*_genome_info.tsv` .
- `metaspades` contains metagenomic assembly scaffolds and contigs files
- `kraken2` contains a taxonomic profiling table reporting read counts assigned to varied taxa represented in the reference Kraken database
- `bracken` contains a relative abundance estimation profile derived from the Kraken results, in various formats including the MataPhlan-style `.mpa.txt` format

Finally, the `work/` folder contains all temporary files from the piepline run, which has a potentially very large footprint on disk. This is required while the pipeline is runnig, and is worth keeping as cache data to enable the `-resume` mode of Nextflow to pick up the piepline execution where it was left after a server crash or interuption due to a bug (the piepline can be resume after a bug fix and will reuse most intermediary processing results as cached). It is recommended to delete this folder, alongside the `.nexflow.log*` files and `.nextflow` folder once satisfied with the output.

An example of a pipeline run can be found here: `/data/pam/rvidata/scratch/bait_capture/rvi_prod_5-2024_05_02-48843_1` 

## Data-Storage and permissions

This pipeline directly copies the CRAM files from iRODS and unpacks them into the .fastq files to be used; please allow for plenty of available disk space quota to allow for this decompression.  

Due to this iRODS download step, in order to run this pipeline your Sanger farm account must be iRODS enabled; Please contact servicedesk@sanger.ac.uk or arrange with PaM informatics via the [PAM Operations Desk General Informatics Support page](https://jira.sanger.ac.uk/servicedesk/customer/portal/16/create/246) to request the necessary permissions to log in and download data from this storage platform.

## Usage

### Help message and configuration info
All pipeline options are documented in the help message, which can be printed using this command:
```sh
nextflow run rvi-pipeline/main.nf --help
```

Default configuration of the pipeline can be printed out using this command:
```sh
nextflow config rvi-pipeline/
```
This will print out all parameters defaults, including details of all reference databases and files used in the pipeline analyses.  

This default configuration can be altered using a combination of custom config files provided via the `-c` argument or though CLI options e.g. `--save_fastqs true` will override the default value of `false` for the `save_fastqs` parameter.


## Running the pipeline

When running this pipeline, you will need to use the `bsub` command, or its shorthand `bsub.py` (available to PaM users using `module load bsub.py`) to run the the `nextflow` command to avoid overloading the farm head nodes the Nextflow master process, and to avoid interuption of the run (which can take up to several days) when logging off. It is recommended to submit this job to the `oversubscribed` queue.


Below are example of ways the pipeline can be set to run:

With a combination of CLI options to specify a sequencing run from iRODS as input:
```sh
bsub.py -q oversubscribed -o rvi-pipeline.log -e rvi-pipeline.log 4 rvi-pipeline \
    nextflow run rvi-pipeline/main.nf \
	--studyid 7289 --runid 48843 --laneid 2 --outdir results
```

With a more complex set of paraemeters to request data from iRODS, using a manifest of lanes:
```sh
bsub.py -q oversubscribed -o rvi-pipeline.log -e rvi-pipeline.log 4 rvi-pipeline \
    nextflow run rvi-pipeline/main.nf \
	--manifest_of_lanes irods_manifest.csv --outdir results
```

With short read datasets already present on disk, usin ga manifest of reads:
```sh
bsub.py -q oversubscribed -o rvi-pipeline.log -e rvi-pipeline.log 4 rvi-pipeline \
    nextflow run rvi-pipeline/main.nf \
	--manifest_of_reads reads_manifest.csv --outdir results
```

... or any combination of the above!

Adding `-resume` to any of these commands should allow resuming the piepline after interuption, for instance if the piepline run has exceeded the runtime limit of the job queue through which it was submitted.
## Error handling
three levels of how to handle fastq errors which can occur due to problems with input data:
    
    exit_on_error: exit if there are any samples unreadable or below the limit
    
    only_unreadable: Only exit if there are samples that are unreadable
    
    ignore: entirely ignore samples that have errors and continue the pipeline

These can be controlled with the flag --fastq_error_handling_mode

## Dependencies

This pipeline relies on the following software modules when used on the Sanger farm:

```
nextflow/23.10.1-5891
ISG/singularity/3.6.4
```

All other software dependencies are handled by Nextflow through pulling of docker containers from publicly hosted repositories; these can be listed  using the following command:
```
grep '    container ' rvi-pipeline/assorted-sub-workflows/*/modules/*.nf rvi-pipeline/modules/*/*.nf | sort -u
```

## Authors and acknowledgment
This pipeline was develoed by the PaM Informatics team at the Wellcome Sanger Institute, Parasites and Microbes Programme.

## License
This software is licensed under the MIT license.

## Project status
If you have run out of energy or time for your project, put a note at the top of the README saying that development has slowed down or stopped completely. Someone may choose to fork your project or volunteer to step in as a maintainer or owner, allowing your project to keep going. You can also make an explicit request for maintainers.

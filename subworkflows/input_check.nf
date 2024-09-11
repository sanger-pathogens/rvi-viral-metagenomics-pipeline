//
// Check input manifest and get read channels
//

workflow INPUT_CHECK {
    take:
    manifest // file: /path/to/manifest.csv

    main:
    Channel
        .fromPath( manifest )
        .ifEmpty {exit 1, log.info "Cannot find path file ${manifest}"}
        .splitCsv ( header:true, sep:',' )
        .map { create_read_channels(it) }
        .filter{ meta, R1 , R2 -> R1 != 'NA' }
        .set { paired_reads }

    emit:
    paired_reads
}

def create_read_channels(LinkedHashMap row) {
    def meta = [:]
    meta.ID = row.ID

    def read_array = []
    // check R1
    if ( !(row.R1 == 'NA') ) {
        if ( !file(row.R1).exists() ) {
            exit 1, "ERROR: Please check input manifest -> Read 1 file does not exist!\n${row.R1}"
        }
        R1 = file(row.R1)
    } else { R1 = 'NA' }

    // check R2
    if ( !(row.R2 == 'NA') ) {
        if ( !file(row.R2).exists() ) {
            exit 1, "ERROR: Please check input manifest -> Long FastQ file does not exist!\n${row.R2}"
        }
        R2 = file(row.R2)
    } else { R2 = 'NA' }

    read_array = [ meta, R1 , R2 ]
    return read_array
}
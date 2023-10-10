def VALIDATE_PARAMETERS() {
    // Parameter checking function
    def errors = 0

    if (params.manifest) {
        manifest=file(params.manifest)
        if (!manifest.exists()) {
            log.error("The manifest file specified does not exist.")
            errors += 1
        }
    }
    else {
        log.error("No manifest file specified. Please specify one using the --manifest option.")
        errors += 1
    }

    if (params.reference) {
        reference=file(params.reference)
        if (!reference.exists()) {
            log.error("The reference file specified does not exist.")
            errors += 1
        }
    }
    else {
        log.error("No reference file specified. Please specify one using the --reference option.")
        errors += 1
    }

    if (params.samtools_threads) {
        if (!params.samtools_threads.toString().isInteger()) {
        log.error("Please ensure the --samtools_threads parameter is a number or leave as default")
        errors += 1
        }
    }
    else {
        log.error("Please specify the number of threads for samtools using the --samtools_threads option")
        errors += 1
    }

    if (params.minimap2_threads) {
        if (!params.minimap2_threads.toString().isInteger()) {
        log.error("Please ensure the --minimap2_threads parameter is a number or leave as default")
        errors += 1
        }
    }
    else {
        log.error("Please specify the number of threads for samtools using the --minimap2_threads option")
        errors += 1
    }

    if (params.results_dir) {
        results_dir_path=file(params.results_dir)
        if (!results_dir_path.getParent().exists()) {
            log.error("The results directory path specified does not exist.")
            errors += 1
        }
    }
    else {
        log.error("No results directory has been specified, please ensure you provide a value or a default.")
        errors += 1
    }

    if (errors > 0) {
            log.error(String.format("%d errors detected", errors))
            exit 1
        }
}
def VALIDATE_PARAMETERS() {
    // Parameter checking function
    def errors = 0
    
    if (params.outdir) {
        outdir_path=file(params.outdir)
        if (!outdir_path.getParent().exists()) {
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
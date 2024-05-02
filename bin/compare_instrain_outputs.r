#!/usr/bin/env Rscript

instrainout.tag <- "_genome_info.tsv"

subset.tags <- c("", "_human", "_total")
subset.types <- c("target", "human", "total")
method.tags <- c("kneaddata_bowtie2_T2T", "bowtie2_kraken2_T2T", "metawrap_qc_hg38")

# read data
instrainout.paths <- list.files("results", pattern = instrainouttag,
                              recursive = TRUE, full.names = TRUE)
instrainout.paths <- instrainout.paths[!endsWith(instrainout.paths, paste0("#0", instrainout.tag))]
instrainout.list <- lapply(instrainout.paths, read.delim)
names(instrainout.list) <- sub(instrainout.tag, "", basename(instrainout.paths), fixed = TRUE)

# group data by subset type
instrainout.method.types <- as.data.frame(t(sapply(strsplit(names(instrainout.list), split = "_"), function(split_id){
    whole_id <- paste(split_id, collapse = "_")
    base_id <- paste(split_id[1:2], collapse = "_")
    method <- paste(split_id[3:5], collapse = "_")
    base_method_id <- paste(split_id[1:5], collapse = "_")
    id_type <- subset.types[subset.tags == sub(base_method_id, "", whole_id)]
    return(c(base_id, method, id_type))
})))
colnames(instrainout.method.types) <- c("ID", "method", "type")

instrainout.bytype <- lapply(subset.types, function(x){
    instrainout.list[instrainout.method.types[,"type"] == x]
})
names(instrainout.bytype) <- subset.types

instrainout.bymethod <- lapply(method.tags, function(x){
    instrainout.list[instrainout.method.types[,"method"] == x]
})
names(instrainout.bymethod) <- method.tags

instrainout.bytype.bymethod <- lapply(subset.types, function(x){
    instrainout.bymethod <- lapply(method.tags, function(y){
        filter <- (instrainout.method.types[,"type"] == x) & (instrainout.method.types[,"method"] == y)
        table_sublist <- instrainout.list[filter]
        names(table_sublist) <- instrainout.method.types[filter,"ID"]
        return(table_sublist)
    })
    names(instrainout.bymethod) <- method.tags
})
names(instrainout.bytype.bymethod) <- subset.types

# functions to extract properties per category

### need to also filter per read removal method
### then make plot metric differences per sample id (instead of just comparing distributions)

countTaxaByTypeMinValue <- function(instrainout.bytype, filter.field, min.val = 0){
    lapply(instrainout.bytype, function(genome.infos){
        sapply(genome.infos, function(genome.info){
            length(which(genome.info[,filter.field] >= min.val))
        })
    })
}
extractValuesByType <- function(instrainout.bytype, field,
                                filter.field = NULL, min.val = 0,
                                FUN = median) {
    if (!is.null(filter.field)){
        filter <- genome.info[,filter.field] >= min.val
    }else{
        filter <- TRUE
    }
    lapply(instrainout.bytype, function(genome.infos){
        sapply(genome.infos, function(genome.info){
            FUN(genome.info[filter,field])
        })
    })
}

pdf("detected_taxa_count_by_minimum_breadth.pdf", )
for (min.breadth in c(0, 0.5, 0.8)){
    boxplot(countTaxaByTypeMinValue(instrainout.bytype, "breadth", min.breadth),
            ylab = sprintf("# genomes with breadth >= %.1f", min.breadth))
    boxplot(countTaxaByTypeMinValue(instrainout.bytype, "nucl_diversity",
                                    "breadth", min.breadth, mean),
            ylab = sprintf("Average nucl diversity (genomes with breadth >= %.1f)", min.breadth))
}
dev.off()
pdf("detected_taxa_by_minimum_breadth.pdf", )
for (min.breadth in c(0, 0.5, 0.8)){
    boxplot(countTaxaByTypeMinValue(instrainout.bytype, "nucl_diversity", filter.field = "breadth", min.breadth))
}
dev.off()
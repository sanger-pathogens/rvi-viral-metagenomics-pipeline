#!/usr/bin/env Rscript

instrainout_tag <- "_genome_info.tsv"

subset_tags <- c("", "_human", "_total")
subset_types <- c("target", "human", "total")
method_tags <- c("kneaddata_bowtie2_T2T", "bowtie2_kraken2_T2T", "metawrap_qc_hg38")

# save parsed data
data_dump_name <- "collated_genome_info_tsvs.RData"
if (!file.exists(data_dump_name)){
    # read data
    instrainout_paths <- list.files("results", pattern = instrainout_tag,
                                recursive = TRUE, full.names = TRUE)
    instrainout_paths <- instrainout_paths[!endsWith(instrainout_paths, paste0("#0", instrainout_tag))]
    instrainout_list <- lapply(instrainout_paths, read.delim)
    names(instrainout_list) <- sub(instrainout_tag, "", basename(instrainout_paths), fixed = TRUE)
    save(instrainout_list, file = data_dump_name)
}else{
    load(data_dump_name)
}

# group data by subset type
instrainout_id_method_types <- as.data.frame(t(sapply(strsplit(names(instrainout_list), split = "_"), function(split_id){
    whole_id <- paste(split_id, collapse = "_")
    base_id <- paste(split_id[1:2], collapse = "_")
    method <- paste(split_id[3:5], collapse = "_")
    base_method_id <- paste(split_id[1:5], collapse = "_")
    id_type <- subset_types[subset_tags == sub(base_method_id, "", whole_id)]
    return(c(base_id, method, id_type))
})))
colnames(instrainout_id_method_types) <- c("ID", "method", "type")

unique_lane_ids <- unique(instrainout_id_method_types[["ID"]])

instrainout_byid_bymethod_bytype <- lapply(unique_lane_ids, function(x){
    instrainout_bymethod <- lapply(method_tags, function(y){
        instrainout_bytype <- lapply(subset_types, function(z){
            filter <- (instrainout_id_method_types[,"type"] == z) & (instrainout_id_method_types[,"method"] == y) & (instrainout_id_method_types[,"ID"] == x)
            if (length(which(filter))==1){
                table_sublist <- instrainout_list[filter]
                return(table_sublist[[1]])
            }else{
                return(NULL)
            }
        })
        names(instrainout_bytype) <- subset_types
        return(instrainout_bytype)
    })
    names(instrainout_bymethod) <- method_tags
    return(instrainout_bymethod)
})
names(instrainout_byid_bymethod_bytype) <- unique_lane_ids


instrainout_bymethod_bytype_byid <- lapply(method_tags, function(y){
    instrainout_bytype <- lapply(subset_types, function(z){
        instrainout_byid <- lapply(unique_lane_ids, function(x){
            filter <- (instrainout_id_method_types[,"type"] == z) & (instrainout_id_method_types[,"method"] == y) & (instrainout_id_method_types[,"ID"] == x)
            if (length(which(filter))==1){
                table_sublist <- instrainout_list[filter]
                return(table_sublist[[1]])
            }else{
                return(NULL)
            }
        })
        names(instrainout_byid) <- unique_lane_ids
        return(instrainout_byid)
    })
    names(instrainout_bytype) <- subset_types
    return(instrainout_bytype)
})
names(instrainout_bymethod_bytype_byid) <- method_tags

instrainout_bytype_bymethod_byid <- lapply(subset_types, function(z){
    instrainout_bymethod <- lapply(method_tags, function(y){
        instrainout_byid <- lapply(unique_lane_ids, function(x){
            filter <- (instrainout_id_method_types[,"type"] == z) & (instrainout_id_method_types[,"method"] == y) & (instrainout_id_method_types[,"ID"] == x)
            if (length(which(filter))==1){
                table_sublist <- instrainout_list[filter]
                return(table_sublist[[1]])
            }else{
                return(NULL)
            }
        })
        names(instrainout_byid) <- unique_lane_ids
        return(instrainout_byid)
    })
    names(instrainout_bymethod) <- method_tags
    return(instrainout_bymethod)
})
names(instrainout_bytype_bymethod_byid) <- subset_types

# functions to extract properties per category

### need to also filter per read removal method
### then make plot metric differences per sample id (instead of just comparing distributions)

countTaxaByTypeMinValue <- function(instrainout.by.method.type.id, filter.field, min.val = 0){
    lapply(instrainout.by.method.type.id, function(gis.by.method){
        sapply(gis.by.method, function(gis.by.type){
            sapply(gis.by.type, function(genome.info){
                if (is.null(genome.info)) return(NA)
                else return(length(which(genome.info[,filter.field] >= min.val)))
            })
        })
    })
}
extractValuesByType <- function(instrainout.by.method.type.id, field,
                                filter.field = NULL, min.val = 0,
                                FUN = median, ...) {
    lapply(instrainout.by.method.type.id, function(gis.by.method){
        sapply(gis.by.method, function(gis.by.type){
            sapply(gis.by.type, function(genome.info){
                if (is.null(genome.info)) return(NA)
                if (!is.null(filter.field)){
                    filter <- genome.info[,filter.field] >= min.val
                }else{
                    filter <- rep(TRUE, nrow(genome.info))
                }
                return(FUN(genome.info[filter,field], ...))
            })
        })
    })
}

method_cols <- c("peachpuff", "darkorange", "tomato")
pdf("detected_taxa_count_by_minimum_breadth.pdf", width=12, height=7)
for (min_breadth in c(0, 0.5, 0.8)){
    layout(matrix(1:6, 3, 2, byrow = TRUE))
    taxacounts <- countTaxaByTypeMinValue(instrainout_bytype_bymethod_byid, "breadth", min_breadth)
    nucdiv <- extractValuesByType(instrainout_bytype_bymethod_byid, "nucl_diversity",
                                "breadth", min_breadth, mean, na.rm = TRUE)
    for (subset_type in subset_types){
        par(mar=c(5,12,4,2))
        boxplot(taxacounts[[subset_type]],
                xlab = sprintf("%s reads: # genomes with breadth >= %.1f", subset_type, min_breadth), las = 1, horizontal = TRUE, col=method_cols)
        # legend("topright", legend = method_tags, fill = method_cols)

        boxplot(nucdiv[[subset_type]],
                xlab = sprintf("%s reads: Average nucl diversity (genomes with breadth >= %.1f)", subset_type, min_breadth), las = 1, horizontal = TRUE, col=method_cols)
    }
}
dev.off()

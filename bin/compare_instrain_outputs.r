#!/usr/bin/env Rscript

instrainout_tag <- "_genome_info.tsv"

subset_tags <- c("", "_human", "_total")
subset_types <- c("target", "human", "total")
method_tags <- c("kneaddata_bowtie2_T2T", "bowtie2_kraken2_T2T", "metawrap_qc_hg38")

# read data
instrainout_paths <- list.files("results", pattern = instrainout_tag,
                              recursive = TRUE, full.names = TRUE)
instrainout_paths <- instrainout_paths[!endsWith(instrainout_paths, paste0("#0", instrainout_tag))]
instrainout_list <- lapply(instrainout_paths, read.delim)
names(instrainout_list) <- sub(instrainout_tag, "", basename(instrainout_paths), fixed = TRUE)
# save parsed data
data_dump_name <- "collated_genome_info_tsvs.RData"
if (!file.exists(data_dump_name)){
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

# instrainout_bytype <- lapply(subset_types, function(x){
#     instrainout_list[instrainout_id_method_types[,"type"] == x]
# })
# names(instrainout_bytype) <- subset_types

# instrainout_bymethod <- lapply(method_tags, function(x){
#     instrainout_list[instrainout_id_method_types[,"method"] == x]
# })
# names(instrainout_bymethod) <- method_tags

# instrainout_bytype_bymethod <- lapply(subset_types, function(x){
#     instrainout_bymethod <- lapply(method_tags, function(y){
#         filter <- (instrainout_id_method_types[,"type"] == x) & (instrainout_id_method_types[,"method"] == y)
#         table_sublist <- instrainout_list[filter]
#         names(table_sublist) <- instrainout_id_method_types[filter,"ID"]
#         return(table_sublist)
#     })
#     names(instrainout_bymethod) <- method_tags
# })
# names(instrainout_bytype_bymethod) <- subset_types


instrainout_byid_bymethod_bytype <- lapply(unique_lane_ids, function(x){
    instrainout_bymethod <- lapply(method_tags, function(y){
        instrainout_bytype <- lapply(subset_types, function(z){
            filter <- (instrainout_id_method_types[,"type"] == z) & (instrainout_id_method_types[,"method"] == y) & (instrainout_id_method_types[,"ID"] == x)
            table_sublist <- instrainout_list[filter]
            if (length(table_sublist)==1){
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

# functions to extract properties per category

### need to also filter per read removal method
### then make plot metric differences per sample id (instead of just comparing distributions)

countTaxaByTypeMinValue <- function(instrainout.by.id.method.type, filter.field, min.val = 0){
    lapply(instrainout.by.id.method.type, function(gis.by.id){
        sapply(gis.by.id, function(gis.by.method){
            sapply(gis.by.method, function(genome.info){
                length(which(genome.info[,filter.field] >= min.val))
            })
        })
    })
}
extractValuesByType <- function(instrainout.by.id.method.type, field,
                                filter.field = NULL, min.val = 0,
                                FUN = median) {
    lapply(instrainout.by.id.method.type, function(gis.by.id){
        sapply(gis.by.id, function(gis.by.method){
            sapply(gis.by.method, function(genome.info){
                if (!is.null(filter.field)){
                    filter <- genome.info[,filter.field] >= min.val
                }else{
                    filter <- TRUE
                }
                return(FUN(genome.info[filter,field]))
            })
        })
    })
}

pdf("detected_taxa_count_by_minimum_breadth.pdf", width=20, height=20)
for (min_breadth in c(0, 0.5, 0.8)){
    boxplot(extractValuesByType(instrainout_byid_bymethod_bytype, "breadth", min_breadth),
            ylab = sprintf("# genomes with breadth >= %.1f", min_breadth))
    boxplot(countTaxaByTypeMinValue(instrainout_bytype, "nucl_diversity",
                                    "breadth", min_breadth, mean),
            ylab = sprintf("Average nucl diversity (genomes with breadth >= %.1f)", min_breadth))
}
dev.off()
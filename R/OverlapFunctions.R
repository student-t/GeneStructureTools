#' Convert DEXSeq ids to gene ids
#'
#' @param dexseq_ids vector of DEXSeq group or exon ids
#' @param removeVersion remove the version (.xx) of the gene?
#' @return vector of unique gene ids
#' @export
#' @import stringr
#' @examples
#' # multiple genes in name
#' dex_id <- "ENSMUSG00000027618.17+ENSMUSG00000098950.7+ENSMUSG00000089824.10+ENSMUSG00000074643.12"
#' DEXSeqIdsToGeneIds(dex_id)
#'
#' # exonic part number in id
#' DEXSeqIdsToGeneIds("ENSMUSG00000001017.15:E013", removeVersion=TRUE)
#' @author Beth Signal
DEXSeqIdsToGeneIds <- function(dexseq_ids, removeVersion=FALSE){
    contains_exon <- grep(":E", dexseq_ids)

    if(length(contains_exon) >0 ){
        dexseq_ids[contains_exon] <- unlist(lapply(stringr::str_split(dexseq_ids[contains_exon], ":E"), "[[",1))
    }

    gene_ids <- unique(unlist(stringr::str_split(dexseq_ids, "[+]")))

    if(removeVersion==TRUE){
        gene_ids <- removeVersion(gene_ids)
    }

    return(gene_ids)
}

#' Remove version number from ensembl gene/transcript ids
#'
#' @param ids vector of ensembl ids
#' @return vector of ensembl ids without the version number
#' @export
#' @examples
#' removeVersion("ENSMUSG00000001017.15")
#' @author Beth Signal
removeVersion <- function(ids){
    return(unlist(lapply(str_split(ids, "[.]"), "[[",1)))
}

#' Find a DEXSeq exons' biotype
#'
#' @param DEX_exon_id vector of DEXSeq exon ids
#' @param dex_gtf GRanges object of the DEXSeq formatted gtf
#' @param gtf GRanges object of the GTF annotated with exon biotypes - i.e. exon, CDS, UTR
#' @param set which overlapping set of exon biotypes to return - to, from, and/or overlap
#' @return overlaping types
#' @export
#' @import GenomicRanges
#' @examples
#' gtf_file <- system.file("extdata","gencode.vM14.annotation.small.gtf",
#' package = "GeneStructureTools")
#' dex_gtf_file <- system.file("extdata","gencode.vM14.annotation.dexseq.small.gtf",
#' package = "GeneStructureTools")
#'
#' gtf <- rtracklayer::import(gtf_file)
#' gtf <- UTR2UTR53(gtf)
#' dex_gtf <- rtracklayer::import(dex_gtf_file)
#'
#' findDEXexonType("ENSMUSG00000032366.15:E028", dex_gtf, gtf)
#'
#' dex_results_file <- system.file("extdata","dexseq_results.small.txt",
#' package = "GeneStructureTools")
#' dex_results <- read.table(dex_results_file, sep="\t")
#'
#' findDEXexonType(rownames(dex_results), dex_gtf, gtf)
#'
#' @author Beth Signal
findDEXexonType <- function(DEX_exon_id, dex_gtf, gtf,set="overlap"){
    dex_gtf$id <- paste0(dex_gtf$gene_id,":E", dex_gtf$exonic_part_number)
    dex_gtf.query <- dex_gtf[match(DEX_exon_id,dex_gtf$id)]
    overlap_types <- overlapTypes(dex_gtf.query, gtf, set = set)[,2]
    return(overlap_types)
}

#' Summarise exon biotypes to broader categories
#' @param types vector of exon biotypes
#' @return vector of broader exon biotypes
#' @export
#' @examples
#' gtf_file <- system.file("extdata","gencode.vM14.annotation.small.gtf",
#' package = "GeneStructureTools")
#' dex_gtf_file <- system.file("extdata","gencode.vM14.annotation.dexseq.small.gtf",
#' package = "GeneStructureTools")
#'
#' gtf <- rtracklayer::import(gtf_file)
#' gtf <- UTR2UTR53(gtf)
#' dex_gtf <- rtracklayer::import(dex_gtf_file)
#'
#' dex_results_file <- system.file("extdata","dexseq_results.small.txt",
#' package = "GeneStructureTools")
#' dex_results <- read.table(dex_results_file, sep="\t")
#'
#' types <- findDEXexonType(rownames(dex_results), dex_gtf, gtf)
#' summarised_types <- summariseExonTypes(types)
#' table(types, sumamrised_types)
#' @author Beth Signal
summariseExonTypes <- function(types){

    types <- gsub("protein_coding-CDS:protein_coding-UTR3:protein_coding-UTR5", "protein_coding-CDS", types)
    types <- gsub("protein_coding-CDS:protein_coding-UTR5", "protein_coding-start_codon", types)
    types <- gsub("protein_coding-CDS:protein_coding-UTR3", "protein_coding-stop_codon", types)

    types2 <- types
    types2[grep("protein_coding-start_codon", types2)] <- "start_codon"
    types2[grep("protein_coding-stop_codon", types2)] <- "stop_codon"
    types2[grep("protein_coding-UTR5", types2)] <- "UTR5"
    types2[grep("protein_coding-UTR3", types2)] <- "UTR3"
    types2[grep("protein_coding-CDS", types2)] <- "CDS"
    types2[!(types2 %in% c("start_codon", "stop_codon","UTR5","UTR3","CDS"))] <- "noncoding_exon"

    return(types2)
}


#' Annotate introns and exonic parts by overlaping exon biotype
#'
#' Annotate introns and exonic parts by overlaping exon biotype
#' @param query_ranges GRanges object of the query regions
#' @param gtf GRanges object of the GTF annotated with exon biotypes - i.e. exon, CDS, UTR
#' @param set which overlapping set of exon biotypes to return - to, from, and/or overlap
#' @return overlaping types in a data.frame
#' @export
#' @import GenomicRanges
#' @examples
#' @author Beth Signal
overlapTypes <- function(query_ranges, gtf, set=c("from", "to", "overlap")){
    overlaps <- GenomicRanges::findOverlaps(query_ranges, gtf)
    gtf_overlap <- gtf[overlaps@to]
    gtf_overlap@elementMetadata$index <- overlaps@from
    gtf_overlap <- gtf_overlap[(gtf_overlap@elementMetadata$type %in%
                                    c("exon", "CDS","UTR","UTR3","UTR5"))]

    gtf_overlap <- filterGtfOverlap(gtf_overlap)
    gtf_overlap <- addBroadTypes(gtf_overlap)

    gtf_from <- NULL
    gtf_to <- NULL

    if(any(set=="from")){
        gtf_from <- gtf_overlap[end(gtf_overlap) ==
                                    start(query_ranges[gtf_overlap@elementMetadata$index])]
    }
    if(any(set=="to")){
        gtf_to <- gtf_overlap[start(gtf_overlap) ==
                                  end(query_ranges[gtf_overlap@elementMetadata$index])]
    }
    #keep only hits with a exon-intron-exon pair
    if(any(set=="to") & any(set=="from")){
        tid_index_from <- paste0(gtf_from@elementMetadata$transcript_id, "_",
                                 gtf_from@elementMetadata$index)
        tid_index_to <- paste0(gtf_to@elementMetadata$transcript_id, "_",
                               gtf_to@elementMetadata$index)
        tid_indexes_both <- tid_index_from[tid_index_from %in% tid_index_to]
        gtf_from <- gtf_from[tid_index_from %in% tid_index_to]
        gtf_to <- gtf_to[tid_index_to %in% tid_index_from]
    }

    if(any(set=="from") & length(gtf_from) > 0){
        gtf_from@elementMetadata$typetype <- paste0(gtf_from@elementMetadata$transcript_type_broad,
                                                    "-",gtf_from@elementMetadata$type)
        #remove nmd/retained introns -- these tend to be isoexons of protein coding exons
        rm <- which(gtf_from@elementMetadata$typetype == "retained_intron|exon" |
                        gtf_from@elementMetadata$transcript_type_broad == "nmd")

        #not used currently
        from_types <- aggregate(type ~ index, gtf_from@elementMetadata,
                                function(x) paste0(sort(unique(x)),collapse=":"))
        #not used currently
        from_transcript_types <- aggregate(transcript_type_broad ~ index,
                                           gtf_from@elementMetadata,
                                           function(x) paste0(sort(unique(x)),collapse=":"))
        from_typetypes <- aggregate(typetype ~ index,
                                    gtf_from@elementMetadata[-rm,],
                                    function(x) paste0(sort(unique(x)),collapse=":"))
    }
    if(any(set=="to") & length(gtf_to) > 0){
        gtf_to@elementMetadata$typetype <- paste0(gtf_to@elementMetadata$transcript_type_broad,
                                                  "-",gtf_to@elementMetadata$type)
        #remove nmd/retained introns -- these tend to be isoexons of protein coding exons
        rm <- which(gtf_to@elementMetadata$typetype == "retained_intron|exon" |
                        gtf_to@elementMetadata$transcript_type_broad == "nmd")

        to_types <- aggregate(type ~ index, gtf_to@elementMetadata,
                              function(x) paste0(sort(unique(x)),collapse=":"))
        to_transcript_types <- aggregate(transcript_type_broad ~ index,
                                         gtf_to@elementMetadata,
                                         function(x) paste0(sort(unique(x)),collapse=":"))
        to_typetypes <- aggregate(typetype ~ index,
                                  gtf_to@elementMetadata[-rm,],
                                  function(x) paste0(sort(unique(x)),collapse=":"))
    }
    if(any(set=="overlap")){
        gtf_overlap@elementMetadata$typetype <- paste0(gtf_overlap@elementMetadata$transcript_type_broad,
                                                       "-",gtf_overlap@elementMetadata$type)
        #remove nmd/retained introns -- these tend to be isoexons of protein coding exons
        rm <- which(gtf_overlap@elementMetadata$typetype == "retained_intron|exon" |
                        gtf_overlap@elementMetadata$transcript_type_broad == "nmd")

        ol_types <- aggregate(type ~ index, gtf_overlap@elementMetadata,
                              function(x) paste0(sort(unique(x)),collapse=":"))
        ol_transcript_types <- aggregate(transcript_type_broad ~ index,
                                         gtf_overlap@elementMetadata,
                                         function(x) paste0(sort(unique(x)),collapse=":"))
        ol_typetypes <- aggregate(typetype ~ index,
                                  gtf_overlap@elementMetadata[-rm,],
                                  function(x) paste0(sort(unique(x)),collapse=":"))
    }

    type_types <- data.frame(index=1:length(start(ranges(query_ranges))))
    if(any(set=="from") & length(gtf_from) > 0){
        type_types$from <- from_typetypes$typetype[match(type_types$index,
                                                         from_typetypes$index)]
    }
    if(any(set=="to") & length(gtf_to) > 0){
        type_types$to <- to_typetypes$typetype[match(type_types$index,
                                                     to_typetypes$index)]
    }
    if(any(set=="overlap")){
        type_types$overlap <- ol_typetypes$typetype[match(type_types$index,
                                                          ol_typetypes$index)]
    }

    return(type_types)
}

#' Change transcript biotypes to a broader set
#'
#' Change transcript biotypes to a broader set in a GRanges GTF object
#' @param gtf GRanges object of the GTF
#' @return GRanges object of the GTF with new transcript types
#' @export
#' @import GenomicRanges
#' @examples
#' @author Beth Signal
addBroadTypes <- function(gtf){
    transcript_types_new <- gtf@elementMetadata$transcript_type
    transcript_types_new[which(transcript_types_new %in% c("3prime_overlapping_ncrna",
                                                           "3prime_overlapping_ncRNA",
                                                           "antisense",
                                                           "bidirectional_promoter_lncRNA",
                                                           "macro_lncRNA",
                                                           "known_ncrna",
                                                           "lincRNA",
                                                           "non_coding",
                                                           "processed_transcript",
                                                           "sense_intronic",
                                                           "sense_overlapping"))] <- "lncRNA"
    transcript_types_new[which(transcript_types_new %in% c("IG_C_gene","IG_C_pseudogene",
                                                           "IG_D_gene","IG_J_gene",
                                                           "IG_J_pseudogene","IG_V_gene",
                                                           "IG_D_pseudogene", "IG_LV_gene",
                                                           "IG_pseudogene",
                                                           "ribozyme",
                                                           "IG_V_pseudogene","miRNA",
                                                           "misc_RNA","Mt_rRNA","Mt_tRNA",
                                                           "rRNA","snoRNA","snRNA","TEC",
                                                           "scaRNA","scRNA","sRNA",
                                                           "TR_C_gene","TR_D_gene",
                                                           "TR_J_gene","TR_J_pseudogene" ,
                                                           "TR_V_gene","TR_V_pseudogene"))] <- "short_ncRNA"
    transcript_types_new[which(transcript_types_new %in% c("processed_pseudogene"," pseudogene","transcribed_processed_pseudogene",
                                                           "transcribed_unitary_pseudogene",
                                                           "transcribed_unprocessed_pseudogene",
                                                           "translated_processed_pseudogene",
                                                           "translated_unprocessed_pseudogene",
                                                           "polymorphic_pseudogene",
                                                           "unitary_pseudogene",
                                                           "unprocessed_pseudogene"))] <- "pseudogene"

    transcript_types_new[which(transcript_types_new %in% c("nonsense_mediated_decay","non_stop_decay"))] <- "nmd"


    gtf@elementMetadata$transcript_type_broad <- transcript_types_new
    return(gtf)
}

#' Filter a GTF overlap to remove exons when exon is annotated as a CDS/UTR
#'
#' Filter a GTF overlap to remove exons when exon is annotated as a CDS/UTR
#' @param gtf_from GRanges object of the GTF produced from an overlap
#' @return GRanges object of the GTF with redundant exons removed
#' @export
#' @import GenomicRanges
#' @examples
#' @author Beth Signal
filterGtfOverlap <- function(gtf_from){
    gtf_from_df <- gtf_from@elementMetadata
    gtf_from_df$exon_number <- as.numeric(gtf_from_df$exon_number)
    gtf_from_df$start_ids <- paste0(start(ranges(gtf_from)),
                                    gtf_from@elementMetadata$transcript_id)
    gtf_from_df$end_ids <- paste0(end(ranges(gtf_from)),
                                  gtf_from@elementMetadata$transcript_id)

    rm_s <- which(gtf_from_df$type == "exon" &
                      gtf_from_df$start_ids %in% gtf_from_df$start_ids[gtf_from_df$type %in% c("CDS","UTR","UTR3","UTR5")])
    rm_e <- which(gtf_from_df$type == "exon" &
                      gtf_from_df$end_ids %in% gtf_from_df$end_ids[gtf_from_df$type %in% c("CDS","UTR","UTR3","UTR5")])
    rm <- unique(c(rm_e, rm_s))
    gtf_from <- gtf_from[-rm]
    return(gtf_from)
}

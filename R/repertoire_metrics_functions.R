#' calculate_repertoire_metrics
#'
#' @param named_species_vector a named vector
#' @return a named vector
#' @export
#'
calculate_repertoire_metrics <- function(named_species_vector) {

    # Calculate the repertoire metrics from a named species vector

    stopifnot(!duplicated(names(named_species_vector)))

    # How does the named_species_vector look like?
    # named_species_vector <- c(10, 6, 3)
    # names(named_species_vector) <- c("apple", "pear", "banana")

    species_vector <- named_species_vector

    frequency_vector <- species_vector/sum(species_vector)
    shannon_entropy <- -sum(frequency_vector * log(frequency_vector), na.rm = TRUE)
    richness_count <- length(species_vector)
    pielou_evenness <- shannon_entropy/log(richness_count)
    clonality_score <- 1 - pielou_evenness

    # The variable name in the output_vector is more scientific to reveal the underlying formula

    output_vector <- c(shannon_entropy, clonality_score, richness_count, pielou_evenness)
    names(output_vector) <- c("diversity", "clonality", "richness", "evenness")

    output_vector
}


#' summarize_repertoire_metrics
#'
#' @param one_sample_dataframe a dataframe of clonotype in immunarch format
#' @return a named vector
#' @export
#'
summarize_repertoire_metrics <- function(one_sample_dataframe) {

    # one_sample_dataframe can be a table of immunarch clone format of one sample

    if (nrow(one_sample_dataframe) <= 1) {
        metrics_vector <- rep(NA, times = 4)
        names(metrics_vector) <- c("diversity", "clonality", "richness", "evenness")
    } else {
        species_name_column <- "CDR3.aa"
        species_count_column <- "Clones"
        one_sample_named_species_vector <- one_sample_dataframe[, species_count_column, drop = T]
        names(one_sample_named_species_vector) <- one_sample_dataframe[, species_name_column, drop = T]

        metrics_vector <- calculate_repertoire_metrics(one_sample_named_species_vector)
    }

    metrics_vector
}


#' compute_repertoire_metrics_by_chain_name
#'
#' @param input_dataframe a clonotype dataframe with chain name information
#'
#' @return repertoire metrics by chain name.
#' @export
#'
compute_repertoire_metrics_by_chain_name <- function(input_dataframe) {

    # There is no need to correct proportion based on clones for each chain name,
    # because repertoire metrics calculation only needs the CDR3.aa and Clones columns.
    summarized_metrics_list <- by(
        input_dataframe,
        list(input_dataframe$chain_name),
        summarize_repertoire_metrics
    )

    summarized_metrics_matrix <- do.call(rbind, summarized_metrics_list)
    summarized_metrics_dataframe <- as.data.frame(summarized_metrics_matrix)

    summarized_metrics_dataframe
}


#' combine_all_sample_repertoire_metrics
#'
#' @param input_dataframe_list a list of dataframes with repertoire metrics by chain name
#'
#' @return a wide table with all samples' all chains' all repertoire metrics
#' @export
#'
combine_all_sample_repertoire_metrics <- function(input_dataframe_list) {

    output_dataframe_list <- list()

    for (sample_name in names(input_dataframe_list)) {
        current_input_dataframe <- input_dataframe_list[[sample_name]]

        chain_name <- rownames(current_input_dataframe)
        current_output_dataframe <- cbind(sample_name, chain_name, current_input_dataframe)

        output_dataframe_list[[sample_name]] <- current_output_dataframe
    }

    output_combined_dataframe <- do.call(rbind, output_dataframe_list)
    rownames(output_combined_dataframe) <- NULL

    output_combined_dataframe

    # Tidyverse style code, abandoned.
    # output_combined_dataframe <- input_dataframe_list %>%
    #     purrr::map(., ~ tibble::rownames_to_column(.x, var = "chain_name")) %>%
    #     purrr::imap(., ~ tibble::add_column(.x, sample_name = .y, .before = 1)) %>%
    #     dplyr::bind_rows(.)
    # output_combined_dataframe
}



#' calculate_all_sample_chain_repertoire_metrics
#'
#' @param input_dataframe_list a clonotype dataframe with chain name information
#'
#' @return a wide table with all samples' all chains' all repertoire metrics
#' @export
#'
calculate_all_sample_chain_repertoire_metrics <- function(input_dataframe_list) {

    repertoire_metrics_by_chain_dataframe_list <- lapply(
        input_dataframe_list,
        compute_repertoire_metrics_by_chain_name
    )

    all_sample_all_chain_all_metrics_wide_dataframe <-
        combine_all_sample_repertoire_metrics(repertoire_metrics_by_chain_dataframe_list)

    all_sample_all_chain_all_metrics_wide_dataframe
}

#' get_chain_name_x_sample_name_for_each_metric
#'
#' @param input_dataframe a dataframe with repertoire metrics calculated for each chain name
#' @importFrom tidyr pivot_wider
#' @importFrom tidyselect all_of
#' @return a list of dataframes that is one single repertoire metric for all chains in all samples
#' @export
#'
get_chain_name_x_sample_name_for_each_metric <- function(input_dataframe) {

    # input_dataframe <- all_sample_all_chain_all_metrics_wide_dataframe

    metrics_names <- colnames(input_dataframe)[3:length(colnames(input_dataframe))]

    accumulation_list <- list()

    for (current_metric in metrics_names) {
        current_metric_dataframe <- input_dataframe[, c(c("chain_name", "sample_name"), current_metric)]

        # long to wide so that column names are mainly sample names.
        current_new_metric_dataframe <- tidyr::pivot_wider(
            current_metric_dataframe,
            names_from = "sample_name",
            values_from = tidyselect::all_of(current_metric)
        )

        # Set row names to chain name
        current_new_metric_dataframe <- as.data.frame(current_new_metric_dataframe)
        rownames(current_new_metric_dataframe) <- current_new_metric_dataframe$chain_name
        current_new_metric_dataframe$chain_name <- NULL

        accumulation_list[[current_metric]] <- current_new_metric_dataframe

    }
    accumulation_list
}

# Diversity and Clonality definition

## mathematical definition, demonstration, and source code

# http://traits-dgs.nceas.ucsb.edu/workspace/r/r-tutorial-for-measuring-species-diversity/Measuring%20Diversity%20in%20R.pdf/attachment_download/file

# https://cran.r-project.org/web/packages/vegan/vignettes/diversity-vegan.pdf

# https://rdrr.io/bioc/LymphoSeq/src/R/clonality.R (source code of formula)

## Formula explicitly described in the papers

# https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6124515/ (ln based, best described formula, also talk about different of the studied tumor from melanoma)

# formula:
# https://www.pnas.org/content/113/42/11919 (ln based)
# https://cancerimmunolres.aacrjournals.org/content/8/1/146 (ln based)

# https://www.tandfonline.com/doi/full/10.1080/2162402X.2019.1652538 (log2 based)
# https://www.frontiersin.org/articles/10.3389/fimmu.2019.02985/full (log2 based) (has source code)

# T-cell repertoire analysis and metrics of diversity and clonality
# https://www.sciencedirect.com/science/article/abs/pii/S0958166920301051?dgcid=rss_sd_all (can not download)

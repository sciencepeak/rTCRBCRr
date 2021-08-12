#' completely_tidy_up_clonotype
#'
#' @param input_dataframe an original clonotype dataframe
#' @param adopted_clonotyping_tool a string to denote the clonotypeing tool. Default is trust
#'
#' @return a clean dataframe
#' @export
#'
completely_tidy_up_clonotype <- function(input_dataframe, adopted_clonotyping_tool = "trust") {
    output_dataframe <- input_dataframe %>%
        format_clonotype_to_immunarch_style(., clonotyping_tool = adopted_clonotyping_tool) %>%
        remove_nonproductive_CDR3aa %>%
        annotate_chain_name_and_cell_type %>%
        merge_convergent_clonotype

    output_dataframe
}

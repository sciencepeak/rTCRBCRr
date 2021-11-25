#' summarize_convergence_function
#'
#' @param a_dataframe a dataframe
#' @return a dataframe
#' @import magrittr
#'
summarize_convergence_function <- function(a_dataframe) {
    # A CDR3.aa might have different CDR3.nt, V.name, D.name, or J.name.
    # Select the most frequent elements.
    processed_vector <- with(
        a_dataframe, {
            c(
                Clones = Clones %>% sum %>% as.character,
                Proportion = Proportion %>% sum %>% as.character,
                CDR3.nt = CDR3.nt %>% table %>% which.max %>% names,
                CDR3.aa = CDR3.aa %>% unique,
                V.name = V.name %>% table %>% which.max %>% names,
                D.name = D.name %>% table %>% which.max %>% names,
                J.name = J.name %>% table %>% which.max %>% names,
                V.end = NA,
                D.start = NA,
                D.end = NA,
                J.start = NA,
                VJ.ins = NA,
                VD.ins = NA,
                DJ.ins = NA,
                Sequence = NA,
                chain_name = chain_name %>% unique,
                cell_type = cell_type %>% unique
            )
        }
    )
    # stopifnot(nrow(processed_dataframe) == 1)
    processed_vector
}

#' Merge convergent clonotype
#'
#' @param input_dataframe A dataframe of clonotype of immunarch format
#' @return A dataframe of clonotype of immunarch format
#' merge_convergent_clonotype_function(an_immunarch_format_clonotype_dataframe)
#' @import magrittr
#' @export
#' @examples
#' merge_convergent_clonotype(chain_separated_dataframe)
#'
merge_convergent_clonotype <- function(input_dataframe) {

    if (nrow(input_dataframe) == 0) {
        ouput_dataframe <- input_dataframe
    } else {
        summarized_convergence_list <- by(
            input_dataframe,
            list(input_dataframe$CDR3.aa, input_dataframe$chain_name),
            summarize_convergence_function
        )

        summarized_convergence_dataframe <- do.call(rbind, summarized_convergence_list) %>%
            as.data.frame %>%
            inset(., "Clones", value = as.numeric(.$Clones)) %>%
            inset(., "Proportion", value = as.numeric(.$Proportion))

        output_dataframe <- summarized_convergence_dataframe %>%
            calibrate_proportion_by_clones %>%
            magrittr::set_rownames(., value = NULL)
    }

    output_dataframe
}

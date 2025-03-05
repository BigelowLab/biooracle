#' List the layers available - requires biooracle
#' 
#' @export
#' @return tibble with the available layer information
list_layers = function(){
  if (!requireNamespace("biooracler")) {
    stop("please install biooracler package first")
  }
  x = biooracler::list_layers()
  
  ss = gregexpr("_",x$dataset_id, fixed = TRUE)
  ix = lengths(ss) == 4
  ss = strsplit(x$dataset_id[!ix], "_", fixed = TRUE)
  
  oddballs = x |>
    dplyr::filter(!ix) |> 
    dplyr::rowwise() |>
    dplyr::group_map(
      function(tbl, key){
        s = strsplit(tbl$dataset_id, "_", fixed = TRUE)[[1]]
        switch(as.character(length(s)),
               "2" = {
                 dplyr::tibble(
                   var = tbl$dataset_id, 
                   scenario = NA_character_, 
                   start = NA_character_, 
                   stop = NA_character_, 
                   z = NA_character_)
                },
               "6" = {
                 dplyr::tibble(
                   var = paste(s[1:2], collapse = "_"), 
                   scenario = s[3], 
                   start = s[4], 
                   stop = s[5], 
                   z = s[6])
               }
              ) |> dplyr::bind_cols(tbl)
      }
    ) |>
    dplyr::bind_rows()
  
  x |>
    dplyr::filter(ix) |>
    tidyr::separate_wider_delim(dplyr::all_of("dataset_id"), "_",
                                names = c("var", "scenario", "start", "stop", "z"),
                                too_few = "error",
                                too_many = "error",
                                cols_remove = FALSE) |>
    dplyr::bind_rows(oddballs) |>
    dplyr::mutate(longname = strsplit(.data$title, " ", fixed = TRUE) |>
                               sapply(`[[`,2),
                  .before = 1)
  
  
}
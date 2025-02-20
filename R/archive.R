
#' Archive a downloaded Bio-Oracle netcdf file (see [fetch_biooracle]).
#' 
#' Archiving involves writing each layer to (date, depth and variable slice) to a 
#' regional subfolder.  Files are organized into decadal subdirectories.  Metadata 
#' to help navigate the archive are organized into the `database` file.  See 
#' [read_database] for details.
#' 
#' @export
#' @param x stars or chr a stars object or the name of the file to archive 
#' @param dataset_id chr, only required if `x` is a stars object
#' @param path chr the output path
#' @param append_db logical, if TRUE add the newly archived data to the existing
#'   database (if any, otherwise start a new one.)
#' @param cleanup logical, if TRUE then remove the source file **if** the 
#'   input `x` is a filename.
#' @return a small database (table) of metadata
archive_biooracle = function(x, path = ".", dataset_id = NULL,
                             append_db = TRUE,
                             cleanup = TRUE){
  
  if (!inherits(x, "stars")) {
    is_filename = TRUE
    filename = x
    dataset_id = sub(".nc", "", basename(x), fixed = TRUE)
    x = stars::read_stars(x, quiet = TRUE)
  } else {
    is_filename = FALSE
    if (is.null(dataset_id)) stop("if x is a stars object then dataset_id is required")
  }
  
  years = format(stars::st_get_dimension_values(x, "time"), "%Y")
  db = compose_database(x, dataset_id) |>
    dplyr::mutate(var = paste(.data$param, .data$trt, sep = "_"),
                  year = as.character(year),
                  fname = compose_filename(.data, path = path)) |>
    dplyr::group_by(var) |>
    dplyr::group_map(
      function(tbl, key, x = NULL, path = NULL, years = NULL){
        tbl |> 
          dplyr::rowwise() |>
          dplyr::group_map(
            function(row, k){
              i = which(years == row$year)
              ok = make_path(dirname(row$fname))
              x[key$var[1]] |>
                dplyr::slice("time", i) |>
                stars::write_stars(row$fname)
              row
            }) |> 
          dplyr::bind_rows()
      }, x = x, path = path, years = years) |>
    dplyr::bind_rows()
  DB = append_database(db, path)
  
  if (cleanup && is_filename) ok = file.remove(filename)
  dplyr::select(db, dplyr::all_of(c("scenario", "year", "z", "param", "trt")))
}
#' Compose a filename from a database
#' 
#' @export
#' @param x a table database
#' @param path chr, the directory
#' @param ext chr, the extension
#' @return character filename(s)
compose_filename = function(x, path = NULL, ext = ".tif"){
  
  fname = sprintf("%s_%i_%s_%s_%s%s", 
                  x$scenario,
                  as.numeric(x$year),
                  x$z,
                  x$param,
                  x$trt,
                  ext)
  if (!is.null(path)) fname = file.path(path[1], x$scenario, x$year, fname)
  fname
}


#' Decompose a filename into a table database
#' 
#' @export
#' @param x chr one or more filenames
#' @param ext chr, the extension to strip
#' @return tabular database
decompose_filename = function(x, ext = ".tif"){
  
  x = sub(ext, "", basename(x), fixed = TRUE) |>
    strsplit("_", fixed = TRUE)
  
  dplyr::tibble(
    scenario = sapply(x, `[[`, 1),
    year = sapply(x, `[[`, 2),
    z = sapply(x, `[[`, 3),
    param = sapply(x, `[[`, 4),
    trt = sapply(x, `[[`, 5))
}

#' Given a stars object and an dataset_id, compose a small database
#' of the files that might be generated.
#' 
#' @export
#' @param x stars object
#' @param id chr, a dataset_id like "thetao_ssp119_2020_2100_depthmin"
#' @return a tabular database with scenario, year, z, param and trt
compose_database = function(x, id){
  year = stars::st_get_dimension_values(x, "time") |>
    format("%Y")
  ss = strsplit(id[1], "_", fixed = TRUE)[[1]]
  len = length(ss)
  scenario = switch(as.character(len),
                    "5" = ss[len-3],
                    "6" = ss[len-3],
                    stop("id not known: ", id))
  z = ss[len]
  tidyr::expand_grid(
    scenario,
    year,
    z,
    param = names(x)) |>
    tidyr::separate_wider_delim(dplyr::all_of("param"),
                                delim = "_",
                                names = c("param", "trt"))
}


#' Read a file-list database
#'
#' @export
#' @param path character the directory with the database
#' @param filename character, the name of the database file
#' @return a tibble
read_database <- function(path = ".", filename = "database"){
  if (!dir.exists(path[1])) stop("path not found:", path[1])
  filename <- file.path(path,filename[1])
  stopifnot(file.exists(filename))
  readr::read_csv(filename,  
                  col_types = readr::cols(.default = readr::col_character(),
                                          year = readr::col_character() ))
}

#' Select just the db columns
#' 
#' @export
#' @param x database table
#' @param cols chr, the column names to keep
#' @return a database table
select_database = function(x, cols = c("scenario", "year", "z", "param", "trt")){
  dplyr::select(x, dplyr::all_of(c("scenario", "year", "z", "param", "trt")))
}

#' Write the file-list database
#'
#' @export
#' @param x the tibble or data.frame database
#' @param path character the directory to where the database should reside
#' @param filename character, the name of the database file
#' @param append logical, if TRUE try to append to the existing database
#' @return a tibble
write_database <- function(x, path, filename = "database", append = FALSE){
  if (!dir.exists(path[1])) stop("path not found:", path[1])
  
  if (append){
    return(append_database(x, path, filename = filename))
  }
  
  
  filename <- file.path(path,filename[1])
  select_database(x) |>
    readr::write_csv(filename)
}

#' Given a directory, build a database
#'
#' @export
#' @param path a path to files
#' @param save_db logical, if TRUE then write the database
#' @param pattern regular expression of the file pattern to search for
#' @param ... arguments passed to write_database **if** `save_db` is `TRUE`.
#' @return tibble or NULL
build_database <- function(
    path = ".",
    pattern = "^.*\\.tif$",
    save_db = FALSE, 
    ...){
  
  if (!dir.exists(path[1])) stop("path not found", path[1])
  ff <- list.files(path[1], pattern = pattern,
                   recursive = TRUE, full.names = TRUE)
  
  if (length(ff) > 0){
    x <- decompose_filename(ff)
    if (save_db) x <- write_database(x, path, ...)
  } else {
    warning("no files found to buid database")
    x <- NULL
  }
  
  x
}


#' Append to the file-list database
#'
#' @export
#' @param x the tibble or data.frame database
#' @param path character the directory to where the database should reside
#' @param filename character, the name of the database file
#' @return a tibble with appended data
append_database <- function(x, path, filename = "database"){
  x = select_database(x)
  if (!dir.exists(path[1])) stop("path not found:", path[1])
  origfilename <- file.path(path,filename[1])
  if(!file.exists(origfilename)){
    return(write_database(x, path, filename = filename))
  }
  orig = read_database(path, filename = filename)
  orig_info = colnames(orig)
  x_info = colnames(x)
  ident = identical(orig_info, x_info)
  if (!isTRUE(ident)){
    print(ident)
    stop("input database doesn't match one stored on disk")
  }
  dplyr::bind_rows(orig, x) |>
    dplyr::distinct() |>
    write_database(path, filename = filename)
}
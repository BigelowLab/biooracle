#' Generate constrints query gicen the dataset_id, variables, time and bounding box
#'
#' @param dataset_id char, the dataset identifier
#' @param vars NULL or chr, list of variable names (defaults to all)
#' @param time NULL, POSIXct or Date min and max, (defaults to all)
#' @param bb bounding box (or object from which [sf::st_bbox] can be derived)
#'   (defaults to max spatial range)
#' @return the complete query string 
generate_constraints = function(dataset_id = "thetao_ssp119_2020_2100_depthmin",
                               vars = NULL, 
                               time = NULL,
                               bb = NULL){
  
  x = biooracler::info_layer(dataset_id)
  allvars = x$variables$variable_name
  if (is.null(vars)) {
    vars = x$variables$variable_name
  } else {
    if (!all(vars) %in% allvars){
      stop("requested vars must match one or more of these:", allvars)
    }
  }
   
  epoch = x$alldata$time |>
    dplyr::filter(.data$attribute_name == "time_origin") |>
    dplyr::pull(dplyr::all_of("value")) |>
    as.POSIXct(format = "%d-%B-%Y %H:%M:%S", tz = "UTC")
  alltime = x$alldata$time |>
    dplyr::filter(.data$attribute_name == "actual_range") |>
    dplyr::pull(dplyr::all_of("value")) |>
    strsplit(",", fixed = TRUE) |>
    getElement(1) |>
    as.numeric() |>
    as.POSIXct(tz = "UTC", origin =  epoch)
  if (is.null(time)) time = alltime
  fmt = "%Y-%m-%dT%H:%M:%SZ"
  times = sprintf("[(%s):1:(%s)]", format(alltime[1],fmt), format(alltime[2], fmt))
  
  bb = if (is.null(bb)){
    lat = x$alldata$latitude |>
      dplyr::filter(.data$attribute_name == "actual_range") |>
      dplyr::pull(dplyr::all_of("value")) |>
      strsplit(",", fixed = TRUE) |>
      getElement(1) |>
      as.numeric()
    lon = x$alldata$longitude |>
      dplyr::filter(.data$attribute_name == "actual_range") |>
      dplyr::pull(dplyr::all_of("value")) |>
      strsplit(",", fixed = TRUE) |>
      getElement(1) |>
      as.numeric()
    c(xmin = lon[1], ymin = lat[1], xmax = lon[2], ymax = lat[2])
  } else {
    sf::st_bbox(bb)
  }
  loc = sprintf("[(%0.3f):1:(%0.3f)][(%0.3f):1:(%0.3f)]",
                bb[['ymin']], bb[['ymax']],
                bb[['xmin']], bb[['xmax']])
  sapply(vars,
         function(v){
           paste0(v, times, loc)
         }, simplify = FALSE) |>
    paste(collapse = ",")
  
}


#' Fetch a Bio-Oracle file.
#' 
#' This is a convenience wrapper around [download_biooralce].
#' 
#' @export
#' @param dataset_id chr, see [biooracler::download_layers]
#' @param vars NULL or chr, list of variable names (defaults to all)
#' @param time NULL, POSIXct or Date min and max, (defaults to all)
#' @param bb bounding box (or object from which [sf::st_bbox] can be derived)
#'   (defaults to max spatial range)
#' @param ... other arguments for download_biooracle
#' @return the name of the file retrieved
fetch_biooracle = function(dataset_id = "thetao_ssp119_2020_2100_depthmin",
                           vars = NULL, 
                           time = NULL,
                           bb = NULL,
                           ...){
  
  constraints = generate_constraints(dataset_id, 
                                    vars = vars,
                                    time = time,
                                    bb = bb)

  download_biooracle(dataset_id, constraints = constraints, ...)
}

#' Downloads a file using [biooracler::download_layers]
#'
#' @export
#' @param dataset_id chr, see [biooracler::download_layers]
#' @param constraints chr, a formatted constraints string
#' @param temp_path chr, the temporary data path
#' @param base_url chr the serbvert URL for griddap 
#' @return the fully qualified downloaded file name
download_biooracle = function(dataset_id = "thetao_ssp119_2020_2100_depthmin",
                              constraints = NULL, 
                              base_url = "https://erddap.bio-oracle.org/erddap/griddap",
                              temp_path = biooracle_path("temp")){
  
  if (!dir.exists(temp_path)) ok = make_path(temp_path)

  url = if (!is.null(constraints)){
    paste0(file.path(base_url, paste0(dataset_id,".nc?")), constraints)
  } else {
    file.path(base_url, paste0(dataset_id,".nc"))
  }
  
  newfile = file.path(temp_path, paste0(dataset_id, ".nc"))
  ok = download.file(url, newfile, mode = "wb", quiet = TRUE)
  if (ok != 0) stop("error downloading: ", url)
  newfile
}


#' Given a stars object and an dataset_id, compose a small database
#' of the files that might be generated.
#' 
#' @export
#' @param x stars object
#' @param id chr, a dataset_id like "thetao_ssp119_2020_2100_depthmin"
#' @return a tabular database with scenario, year, z, param and trt
compose_db = function(x, id){
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
#' @return a small database (table) of metadata
archive_biooracle = function(x, path = ".", dataset_id = NULL){
  
  if (!inherits(x, "stars")) {
    dataset_id = substring(x, sub(".nc", "", basename(x), fixed = TRUE))
    x = stars::read_stars(x)
  } else {
    if (is.null(dataset_id)) stop("if x is a stars object then dataset_id is required")
  }
  
  
  db = compose_db(x, dataset_id) 
  
  
  
  
  
  
  
  
}
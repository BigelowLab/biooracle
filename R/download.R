#' Retrieve the current Bio-Oracle URL for griddap
#' 
#' @export
#' @return character URL
biooracle_url = function(){
  "https://erddap.bio-oracle.org/erddap/griddap"
}

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
#' @param data_dir NULL or a character data path.  Not to be confused with `temp_path`
#'   argument for `download_biooracle` that may be passed via `...`
#' @param archive logical, if TRUE and `data_dir` is not NULL, then archive the
#'   result.
#' @param ... other arguments for download_biooracle
#' @return the name of the file retrieved
fetch_biooracle = function(dataset_id = "thetao_ssp119_2020_2100_depthmin",
                           vars = NULL, 
                           time = NULL,
                           bb = NULL,
                           data_dir = NULL,
                           archive = !is.null(data_dir),
                           ...){
  
  constraints = generate_constraints(dataset_id, 
                                    vars = vars,
                                    time = time,
                                    bb = bb)

  newfile = download_biooracle(dataset_id, constraints = constraints, ...)
  if (archive && !is.null(data_dir)){
    ok = make_path(data_dir)
    db = archive_biooracle(newfile, path = data_path)
  }
  newfile
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
                              base_url = biooracle_url(),
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




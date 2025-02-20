#' Given a database, guess which type of \code{along} might be most appropriate
#' 
#' If the database has only one type of param, then along is a list of times to indicate
#' laters for one attribute, otherwise along is \code{NA} to indicate multiple attributes.
#' @export
#' @param x database (a tibble)
#' @return either a list or NA_integer_
guess_along <- function(x){
  x = dplyr::mutate(x,
                    var = paste(.data$param, .data$trt, sep = "_"))
  if (length(unique(x$var)) == 1){ 
    along = list(time = as.numeric(x$year))
  } else {
    along = NA_integer_
  }
  along
}

#' Read raster formatted Bio-Oriacle file(s).
#'
#' @export
#' @param x  biooracle database
#' @param path character path
#' @param along see [stars::read_stars] and [guess_along]
#' @param tolerance num, for binding to allow for some slop
#' @return stars object
read_biooracle <- function(x, 
                      path = NULL, 
                      along = guess_along(x),
                      tolerance = sqrt(.Machine$double.eps),
                      time_fmt = c("year", "Date")[1]){
  
  x = dplyr::mutate(x,
                    var = paste(.data$param, .data$trt, sep = "_"),
                    time = switch(tolower(time_fmt[1]),
                                  "year" = as.numeric(.data$year),
                                  "date" = as.Date(paste0(.data$year, "-01-01"))))
  
  if (is.null(path)) stop("path must be provided")
  filename <- compose_filename(x, path)
  if (!all(file.exists(filename))) {
    stop("one or more files not found:", paste(filename, collapse = ", "))
  }
  x <- dplyr::mutate(x,
                     fname = filename)
  if (is.na(along)){
    # we hope the user provides the same number of dates for each param
    S <- dplyr::group_by(x, .data$var) |>
      dplyr::group_map(
        function(tbl, key){
          read_biooracle(tbl, path = path) |>
            rlang::set_names(tbl$var[1])
        }, .keep = TRUE
      ) 
    S <- do.call(c, append(S, list(along = NA_integer_, tolerance = tolerance)))
  } else {
    S <- stars::read_stars(filename, along = along, tolerance = tolerance)
    names(S) <- x$param[1]
  }
  
  S
}
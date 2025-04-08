#' Read one of more terrain rasters
#' 
#' @export
#' @param what chr one or more terrain layers
#' @param path the path to the regional dataset
#' @param point NA or logical to alter the `point` dimension attribute
#' @param crs st_crs or numeric or char, the CRS desired
#' @return stars object
read_terrain = function(what = c("area", "aspect", "bathymetry_max", "bathymetry_mean", "bathymetry_min", 
                                 "coastline", "landmass", "slope", "terrain_ruggedness_index", 
                                 "topographic_position_index"),
                        path = biooracle_path("nwa"),
                        point = NA,
                        crs = 4326){
  
  ff = file.path(path, "terrain", paste0(what, ".tif"))
  stars::read_stars(ff, along = NA_integer_) |>
    sf::st_set_crs(crs) |>
    set_point_attr(point) |>
    rlang::set_names(what)
}


#' Fetch terrain data and possibly archive 
#' 
#' @export
#' @param archive logical, if TRUE save into a `terrain` subdirectory of `path`
#' @param data_dir chr, the output path
#' @param bb a 4 element bounding box
#' @return stars object
fetch_terrain = function(archive = TRUE, 
                         data_dir = biooracle_path("nwa"),
                         bb = c(xmin = -77, xmax = -51.5, ymin = 37.9, ymax = 56.7)){
  
  dataset_id = "terrain_characteristics"
  newfile = fetch_biooracle(dataset_id,
                            archive = FALSE,
                            bb = bb)
  x = stars::read_stars(newfile) |>
    dplyr::slice("time", 1)
  if (archive){
    path = file.path(data_dir, "terrain") |> make_path()
    for (nm in names(x)){
      ofile = file.path(path, paste0(nm, ".tif"))
      s = stars::write_stars(x[nm], ofile)
    }
  }
  x
}
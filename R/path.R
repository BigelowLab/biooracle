#' Get, set and build biooracle paths
#' 
#' 
#' @param root chr the root biooracle data path
#' @param filename chr the filename where we store the path
#' @param ... file path segments passed to [file.path]
#' @return a file or directory path description
#' @name biooracle_path
NULL

#' @export
#' @rdname biooracle_path
set_biooracle_root = function(root = ".", filename = "~/.biooracle"){
  cat(root,"\n", sep = "", file = filename)
}

#' @export
#' @rdname biooracle_path
get_biooracle_root = function(filename = "~/.biooracle"){
  readLines(filename)
}

#' @export
#' @rdname biooracle_path
biooracle_path = function(..., root = get_biooracle_root()){
  file.path(root, ...)
}

#' @export
#' @rdname biooracle_path
make_path = function(path){
  ok = dir.exists(path[1])
  if (!ok) ok = dir.create(path, recursive = TRUE)
  path
}
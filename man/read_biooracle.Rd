% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/io.R
\name{read_biooracle}
\alias{read_biooracle}
\title{Read raster formatted Bio-Oriacle file(s).}
\usage{
read_biooracle(
  x,
  path = NULL,
  along = guess_along(x),
  tolerance = sqrt(.Machine$double.eps),
  time_fmt = c("year", "Date")[1]
)
}
\arguments{
\item{x}{biooracle database}

\item{path}{character path}

\item{along}{see \link[stars:read_stars]{stars::read_stars} and \link{guess_along}}

\item{tolerance}{num, for binding to allow for some slop}
}
\value{
stars object
}
\description{
Read raster formatted Bio-Oriacle file(s).
}

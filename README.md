biooracle
================

Extra R-language tools to supplement [biooracler R
package](https://github.com/bio-oracle/biooracler). This package serves
up R scripts to create a local data repository.

# Requirements for package

From CRAN

- [R v4.1+](https://www.r-project.org/)
- [rlang](https://CRAN.R-project.org/package=rlang)
- [stars](https://CRAN.R-project.org/package=stars)
- [sf](https://CRAN.R-project.org/package=sf)
- [dplyr](https://CRAN.R-project.org/package=dplyr)
- [tidyr](https://CRAN.R-project.org/package=tidyr)

# Installation

    # install.packages(remotes)
    remotes::install_github("BigelowLab/biooracle")

# Set up a data directory

You can store the path to your chosen data directory. It will persist
between R sessions so you don’t have to do it each time.

``` r
library(biooracle)
set_biooracle_root("~/Library/CloudStorage/Dropbox/data/biooracle")
```

We’ll be creating a new local dataset for the Northwest Atlantic (nwa)
which has the bounding box
`{r} bb = c(xmin = -77, xmax = -42.5, ymin = 36.5, ymax = 56.7)`.

``` r
nwa_path = biooracle_path("nwa") |> make_path()
biooracle_path() |> dir(full.names = TRUE)
```

    ## [1] "/Users/ben/Library/CloudStorage/Dropbox/data/biooracle/nwa" 
    ## [2] "/Users/ben/Library/CloudStorage/Dropbox/data/biooracle/temp"

# Fecth some data to a temporary directory

We’ll set that aside for right now and fetch some data for that region,
but note that this downloaded as a NetCDF file in a temporary directory.

``` r
dataset_id = "thetao_ssp119_2020_2100_depthmin"
newfile = fetch_biooracle(dataset_id, 
                          bb = c(xmin = -77, xmax = -42.5, ymin = 36.5, ymax = 56.7))
```

Now we can read the file.

``` r
x = stars::read_stars(newfile, quiet = TRUE)
x
```

    ## stars object with 3 dimensions and 7 attributes
    ## attribute(s), summary of first 1e+05 cells:
    ##                          Min.    1st Qu.    Median      Mean   3rd Qu.
    ## thetao_ltmax [°C] -0.36475005 1.96057870 2.3428427 2.9704422 3.3483083
    ## thetao_ltmin [°C] -1.90398343 1.57293375 1.8961157 1.7156003 2.3728029
    ## thetao_max [°C]    0.21924963 2.17144280 2.7790994 3.7453738 4.5603769
    ## thetao_mean [°C]  -0.72299476 1.80542342 2.0918568 2.2443568 2.7558258
    ## thetao_min [°C]   -2.00000000 0.91433330 1.6623332 1.1105045 2.0303362
    ## thetao_range [°C]  0.22811718 0.47419300 0.7938143 2.6947997 4.0197336
    ## thetao_sd [°C]     0.03341453 0.09708313 0.1335515 0.2456717 0.4161988
    ##                         Max.  NA's
    ## thetao_ltmax [°C] 17.8440917 53161
    ## thetao_ltmin [°C]  6.0058540 53161
    ## thetao_max [°C]   21.4847577 53161
    ## thetao_mean [°C]   6.8363208 53161
    ## thetao_min [°C]    4.7977722 53161
    ## thetao_range [°C] 23.8074380 53161
    ## thetao_sd [°C]     0.7385261 53161
    ## dimension(s):
    ##      from  to offset delta  refsys                    values x/y
    ## x       1 691    -77  0.05      NA                      NULL [x]
    ## y       1 405  56.75 -0.05      NA                      NULL [y]
    ## time    1   8     NA    NA POSIXct 2020-01-01,...,2090-01-01

# Archiving in a local database

We often save the data in a directory structure aong with a simple table
that catalogs the contents of the directory. The `archive_biooracle()`
function will split up the fecthed data and save in a logical data
structure. We provide the data path, in this case for the Northwest
Atlantic (nwa).

``` r
archive_biooracle(newfile, path = nwa_path)
```

    ## # A tibble: 56 × 5
    ##    scenario year  z        param  trt  
    ##    <chr>    <chr> <chr>    <chr>  <chr>
    ##  1 ssp119   2020  depthmin thetao ltmax
    ##  2 ssp119   2030  depthmin thetao ltmax
    ##  3 ssp119   2040  depthmin thetao ltmax
    ##  4 ssp119   2050  depthmin thetao ltmax
    ##  5 ssp119   2060  depthmin thetao ltmax
    ##  6 ssp119   2070  depthmin thetao ltmax
    ##  7 ssp119   2080  depthmin thetao ltmax
    ##  8 ssp119   2090  depthmin thetao ltmax
    ##  9 ssp119   2020  depthmin thetao ltmin
    ## 10 ssp119   2030  depthmin thetao ltmin
    ## # ℹ 46 more rows

# Read the database catalog

Once you have established a database of files, your can read the
database catalog.

``` r
db = read_database(nwa_path) |>
  print()
```

    ## # A tibble: 56 × 5
    ##    scenario year  z        param  trt  
    ##    <chr>    <chr> <chr>    <chr>  <chr>
    ##  1 ssp119   2020  depthmin thetao ltmax
    ##  2 ssp119   2030  depthmin thetao ltmax
    ##  3 ssp119   2040  depthmin thetao ltmax
    ##  4 ssp119   2050  depthmin thetao ltmax
    ##  5 ssp119   2060  depthmin thetao ltmax
    ##  6 ssp119   2070  depthmin thetao ltmax
    ##  7 ssp119   2080  depthmin thetao ltmax
    ##  8 ssp119   2090  depthmin thetao ltmax
    ##  9 ssp119   2020  depthmin thetao ltmin
    ## 10 ssp119   2030  depthmin thetao ltmin
    ## # ℹ 46 more rows

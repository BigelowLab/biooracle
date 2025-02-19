biooracle
================

Extra R-language tools to supplement [biooracler R
package](https://github.com/bio-oracle/biooracler). This package serves
up R scripts to create a local data repository, or to update a local
data repository on a regular basis.

# Requirements for package

From CRAN

- [R v4.1+](https://www.r-project.org/)
- [rlang](https://CRAN.R-project.org/package=rlang)
- [stars](https://CRAN.R-project.org/package=stars)
- [sf](https://CRAN.R-project.org/package=sf)
- [dplyr](https://CRAN.R-project.org/package=dplyr)

From github

- [biooracler](https://github.com/bio-oracle/biooracler)

# Installation

    # install.packages(remotes)
    remotes::install_github("bio-oracle/biooracler")
    remotes::install_github("BigelowLab/biooracle")

# Set up a data directory

You can store the path to your chosen data directory. It will persist
between R sessions.

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

``` r
dataset_id = "thetao_ssp119_2020_2100_depthmin"
newfile = fetch_biooracle(dataset_id, 
                          bb = c(xmin = -77, xmax = -42.5, ymin = 36.5, ymax = 56.7))
```

``` r
x = stars::read_stars(newfile)
```

    ## thetao_ltmax, thetao_ltmin, thetao_max, thetao_mean, thetao_min, thetao_range, thetao_sd,

``` r
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

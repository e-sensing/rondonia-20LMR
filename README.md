Data sets for testing ML algorithms for deforestation mapping in Brazilian Amazonia.
================

<img src="sits_sticker.png" alt="SITS icon" align="right" height="150" width="150"/>

This project contains data sets for testing machine learning algorithms for deforestation mapping and monitoring in Brazilian Amazonia. These data sets consists of image time series of one Sentinel-2 tile (20LMR) for year 2022, as well R scripts used to perform land use classification together with training data sets. 

## Access to large data sets using `git lfs` 

The data set is a regular series of images covering MGRS tile 20LMR, with 23 time instances for the period 2022-01-05 to 2022-12-23. Each time instances contains 10 bands (B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12). Image names folow the standard `SENTINEL-2_MSI_20LMR_<band>_<year-month-date>.tif`. The data set is 10 GB in size.

Since the data set is large, you need to use `git lfs` (support for large file sizes using git). Install `git lfs` according to the instructions at [git lfs site](https://github.com/git-lfs/git-lfs).

## How to get the data set

To get the data, you will need to clone the rondonia20LMR package from e-sensing github repository to a local directory (`/data_dir` in what follows). Open a local terminal and run the commands below:

```sh
% cd /data_dir
% git-lfs clone https://github.com/e-sensing/rondonia20LMR.git
```

Please replace `data_dir` with your preferred choice in all guidelines below.

## Image data cube for Sentinel-2 tile 20LMR for year 2022

The directory 
```sh
`data_dir/rondonia20LMR/inst/extdata/images` 
```
contains a regular series of images covering MGRS tile 20LMR, with 23 time instances for the period 2022-01-05 to 2022-12-23. Each time instances contains 10 bands (B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12). Image names folow the standard
`SENTINEL-2_MSI_20LMR_<band>_<year-month-date>.tif`. 

## Training samples for deforestation mapping

The directory `data_dir/rondonia20LMR/inst/extdata/samples`  contains time series of SENTINEL-2 data to be used for classification with machine learning methods which are available when the package is loaded. All satellite image time series have the following columns: 

- longitude (East-west coordinate of the time series sample in WGS 84).
- latitude (North-south coordinate of the time series sample in WGS 84).
- start_date (initial date of the time series).
- end_date (final date of the time series).
- label (the class label associated to the sample).
- cube (the name of the image data cube associated with the data).
- time_series (list  with the values of the time series).

## Using the data in R and RStudio

Before running the code in R, please install the `sits` package from CRAN. If there are problems with the installation, please follow the instructions in the [`sits` book](https://e-sensing.github.io/sitsbook/setup.html).

After installing `sits` and downloading the data set, please open the file
```sh
/data_dir/rondonia20LMR/sits_classification.R
```
This file contains a script that shows the use of `sits` package for mapping land use and land cover in the image data cube associated with the `rondonia20LMR` tile for year 2022. 

For description of how these scripts work, please see chapter ["Introduction"](https://e-sensing.github.io/sitsbook/introduction.html) in the `sits` [reference book](https://e-sensing.github.io/sitsbook/index.html).

## Using the data in Python

Python users will find the images in directory 

```sh
data_dir/rondonia20LMR/inst/extdata/images
```

A version of the training data for Python users is available as a CSV file in
```sh
data_dir/rondonia20LMR/inst/extdata/samples/samples_rondonia.csv. 
```

## Reproducible code for paper on Bayesian smoothing

This repository contains data and code to reproduce the paper ["Bayesian Inference for Post-Processing of Remote-Sensing Image Classification"](https://www.mdpi.com/2072-4292/16/23/4572). The code to reproduce the results presented in the paper is available at the following address
```sh
data_dir/rondonia20LMR/R/bayes_paper_code.R
```

## Viewing the data in QGIS 

To visualise the images in QGIS, we provide a project file in 

```sh
data_dir/rondonia20LMR/inst/extdata/qgis/bayes_paper.qgz
```

License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).






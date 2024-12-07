Data sets for testing ML algorithms for deforestation mapping in Brazilian Amazonia.
================

<img src="sits_sticker.png" alt="SITS icon" align="right" height="150" width="150"/>

This project contains data sets for testing machine learning algorithms for deforestation mapping and monitoring in Brazilian Amazonia. These data sets consists of image time series of one Sentinel-2 tile (20LMR) for year 2022, as well R scripts used to perform land use classification together with training data sets. 

## How to use the data set and the scripts 

### Using the data in R and RStudio

To install the data sets (images and training data) and the scripts, run:
`devtools::install_github("e-sensing/rondonia20LMR")`
`library(rondonia20LMR)`

Then you can experiment with the scripts using the command line
`rondonia20LMR::demo_pixel_classification()``

You can also download the `demo_pixel_classification.R` script and make your own changes.

### Using the data in Python

To obtain the data sets, clone the github repository with
`git clone https://github.com/e-sensing/rondonia20LMR.git`. 


## Image data cube for Sentinel-2 tile 20LMR for year 2022

The directory `/images` contains a regular series of images covering MGRS tile 20LMR, with 23 time instances for the period 2022-01-05 to 2022-12-23. Each time instances contains 10 bands (B02, B03, B04, B05, B06, B07, B08, B8A, B11, B12). Image names folow the standard `SENTINEL-2_MSI_20LMR_<band>_<year-month-date>.tif`. 

## Training samples for deforestation mapping

The directory `/samples`  contains time series of SENTINEL-2 data to be used for classification with machine learning methods which are available when the package is loaded. All satellite image time series have the following columns: 

- longitude (East-west coordinate of the time series sample in WGS 84).
- latitude (North-south coordinate of the time series sample in WGS 84).
- start_date (initial date of the time series).
- end_date (final date of the time series).
- label (the class label associated to the sample).
- cube (the name of the image data cube associated with the data).
- time_series (list  with the values of the time series).

License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).

## Scripts to produce deforestation maps

The directory `/R` contains R scripts that use the `sits` package for mapping deforested area in the image data cube.  For description of how these scripts work, please see chapter ["Introduction"](https://e-sensing.github.io/sitsbook/introduction.html) in the `sits` [reference book](https://e-sensing.github.io/sitsbook/index.html).

To run these scripts, you need to install the `sits` package. Please see the instructions in Chapter ["Setup"](https://e-sensing.github.io/sitsbook/setup.html) of the on-line book.

The script `sits_classification.R` shows how to use the data cube and the training samples provided in the repository to do a satellite image time series classification.

## Reproducible code for paper on Bayesian smoothing

This repository contains data and code to reproduce the paper ["Bayesian Inference for Post-Processing of Remote-Sensing Image Classification"](https://www.mdpi.com/2072-4292/16/23/4572). The code to reproduce the results presented in the paper is available in directory `/scripts` and is called `bayes_paper_code.R`. 


License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).






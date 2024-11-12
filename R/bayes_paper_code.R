# Code to reproduce the results of paper 
# "Bayesian Inference for Post-processing of Remote Sensing Image Classification"
# 
# Before running the code, please do the following steps:
# 
# 1. Install the sits package from CRAN 
# If there are problems with the installation, please follow the instructions in:
# <https://e-sensing.github.io/sitsbook/setup.html>.
# 
if (!requireNamespace("sits", quietly = TRUE)) {
        stop("Please install package sits\n",
             "Please call install.packages('sits')",
             call. = FALSE
        )
}
#
# 2. Install the bayesEO package from CRAN 
# 
if (!requireNamespace("bayesEO", quietly = TRUE)) {
        stop("Please install package bayesEO\n",
             "Please call install.packages('bayesEO')",
             call. = FALSE
        )
}
#
# 3. Install the git lfs (large file storage support)
#
# Follow the instructions at https://github.com/git-lfs/git-lfs

#
# 4. Clone the rondonia20LMR package from e-sensing github repository
# to a local directory ($HOME in what follows)
# In a terminal, run 
# % cd /mydir
# % git-lfs clone https://github.com/e-sensing/rondonia20LMR.git
# 
# 5. Set the base directory to where you have installed the "rondonia20LMR"
# repository ($HOME/rondonia20LMR in what follows)
base_dir <- paste0(Sys.getenv("HOME"), "/rondonia20LMR")

# load the required packages 
library(sits)
# retrieve the data cube
cube_20LMR <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = paste0(base_dir,"/inst/extdata/images")
)
# retrieve the training samples 
samples <- readRDS(
        paste0(base_dir, 
               "/inst/extdata/samples/deforestation_samples_v18.rds"))
# remove rare classes which do not exist in the tile
samples <- dplyr::filter(samples, label != "Mountainside_Forest")
# tune tempCNN 
tuning_cnn <- sits_tuning(
     samples,
     params = sits_tuning_hparams(
          opt_hparams = list(
               lr = loguniform(10^-2, 10^-4)
          )
     ),
     trials = 20,
     multicores = 6,
     progress = TRUE
)
# build tempCNN model
tcnn_model <- sits_train(
     samples,
     ml_method = sits_tempcnn(
          opt_hparams = list(lr = 0.00246)   
     )
)
# build the probabilities
probs_cube <- sits_classify(
     data = cube_20LMR,
     ml_model = tcnn_model,
     multicores = 2,
     memsize = 4,
     output_dir = paste0(base_dir,"/inst/extdata/probs"),
     progress = TRUE
)
# generate a unsmoothed map
map_no_smooth <- sits_label_classification(
     cube = probs_cube,
     multicores = 4,
     memsize = 12,
     output_dir = paste0(base_dir,"/inst/extdata/class-orig"),
     version = "orig"
)
# calculate variances
var_cube <- sits_variance(
     cube = probs_cube,
     window_size = 9,
     neigh_fraction = 0.5,
     multicores = 4,
     memsize = 12,
     output_dir = paste0(base_dir,"/inst/extdata/variance")
)
# print variance values
variances <- summary(var_cube)
# save variances
saveRDS(variances, paste0(base_dir,"/inst/extdata/results/variances.rds"))
# bayesian smoothing
bayes_cube <- sits_smooth(
     cube = probs_cube,
     window_size = 9,
     smoothness = c(
          "Clear_Cut_Bare_Soil" = 50,
          "Clear_Cut_Burned_Area" = 35,
          "Clear_Cut_Vegetation" = 40,
          "Forest" = 14,
          "Riparian_Forest" = 56,
          "Seasonally_Flooded" = 40,
          "Water" = 4,
          "Wetland" = 54
     ),
     multicores = 4,
     memsize = 16,
     output_dir = paste0(base_dir,"/inst/extdata/bayes")
)
# bayes classification 
bayes_class <- sits_label_classification(
     cube = bayes_cube,
     multicores = 4,
     memsize = 16,
     output_dir = paste0(base_dir,"/inst/extdata/class-bayes"),
     version = "bayes"
)
# smooth using gaussian methods
library(bayesEO)
# Probs filename
probs_filename <- "SENTINEL-2_MSI_20LMR_2022-01-05_2022-12-23_probs_v1.tif"
probs_file <- paste0(base_dir,"/inst/extdata/probs/", probs_filename)

# Probs labels
labels <- sits_labels(samples)
names(labels) <- c(1:length(labels))
# define output directory
output_dir <- paste0(base_dir,"/inst/extdata/gaussian/")

# read probs file
probs_data <- bayesEO::bayes_read_probs(
     probs_file = probs_file,
     labels     = labels
)
# smooth probs using gaussian filter
probs_gaussian <- bayesEO::gaussian_smooth(
     x              = probs_data,
     window_size    = 7,
     sigma          = 5
)

# define output directory
gauss_filename <- "SENTINEL-2_MSI_20LMR_2022-01-05_2022-12-23_probs_gauss.tif"
gauss_file <- paste0(base_dir,"/inst/extdata/gaussian/", gauss_filename)
# save data
terra::writeRaster(
     x        = probs_gaussian,
     filename = gauss_file,
     wopt     = list(
          filetype = "GTiff",
          datatype = "INT2U",
          gdal = c(
               "COMPRESS=LZW",
               "PREDICTOR=2",
               "BIGTIFF=YES",
               "TILED=YES",
               "BLOCKXSIZE=512",
               "BLOCKYSIZE=512"
          )
     ),
     NAflag = 1
)
# recover the cube as a sits structure
gauss_probs_cube <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir =  paste0(base_dir,"/inst/extdata/gaussian/"),
     bands = "probs",
     labels = labels,
     version = "gauss"
)
# generate a map for gaussian smoothing
gauss_map <- sits_label_classification(
     cube = gauss_probs_cube,
     memsize = 16,
     multicores = 4,
     output_dir = paste0(base_dir,"/inst/extdata/class-gaussian/"),
     version = "gauss"
)
# smooth bilateral
probs_bilateral <- bayesEO::bilateral_smooth(
     x              = probs_data,
     window_size    = 7,
     sigma          = 5,
     tau = 2.0
)

# define output directory
bilat_filename <- "SENTINEL-2_MSI_20LMR_2022-01-05_2022-12-23_probs_bilat.tif"
bilat_file <- paste0(base_dir, "./inst/extdata/bilateral/", bilat_filename)
# save data
terra::writeRaster(
     x        = probs_bilateral,
     filename = bilat_file,
     wopt     = list(
          filetype = "GTiff",
          datatype = "INT2U",
          gdal = c(
               "COMPRESS=LZW",
               "PREDICTOR=2",
               "BIGTIFF=YES",
               "TILED=YES",
               "BLOCKXSIZE=512",
               "BLOCKYSIZE=512"
          )
     ),
     NAflag = 1
)
# recover the cube as a sits structure
bilat_probs_cube <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = paste0(base_dir,"/inst/extdata/bilateral/"),
     bands = "probs",
     labels = labels,
     version = "bilat"
)
# generate a map for bilateral smoothing
bilat_map <- sits_label_classification(
     cube = bilat_probs_cube,
     memsize = 64,
     multicores = 16,
     output_dir = paste0(base_dir,"/inst/extdata/class-bilat/"),
     version = "bilat"
)
# generate uncertainty cube
uncert_cube <- sits_uncertainty(
     cube = probs_cube,
     type = "entropy",
     memsize = 16,
     multicores = 4,
     output_dir = paste0(base_dir,"/inst/extdata/uncert/")
)
# generate data points with high uncertainty
uncert_samples <- sits_uncertainty_sampling(
     uncert_cube = uncert_cube,
     n = 100000,
     min_uncert = 0.0,
     sampling_window = 10,
     multicores = 16,
     memsize = 64
)
# get classes for map_no_smooth for uncert samples
classes_no_smooth <- sits_get_class(map_no_smooth, uncert_samples)
# get classes for map bayes for uncert samples
classes_bayes <- sits_get_class(bayes_class, uncert_samples)
# get classes for map gauss for uncert samples
classes_gauss <- sits_get_class(gauss_map, uncert_samples)
# get classes for map bilat for uncert samples
classes_bilat <- sits_get_class(bilat_map, uncert_samples)
# join classes from maps
classes_maps <- tibble::tibble(
     id        = 1:nrow(classes_no_smooth),
     longitude = classes_no_smooth[["longitude"]],
     latitude = classes_no_smooth[["latitude"]],
     label = "NoClass",
     no_smooth = classes_no_smooth[["label"]],
     bayes     = classes_bayes[["label"]],
     gauss     = classes_gauss[["label"]],
     bilat     = classes_bilat[["label"]]
)
classes_maps_diff <- dplyr::filter(
     classes_maps,
     .data[["no_smooth"]] != .data[["bayes"]]
)
classes_maps_diff2 <- dplyr::filter(
     classes_maps_diff,
     .data[["gauss"]] != .data[["bayes"]]
)
# sample 600 points
classes_maps_diff_600 <- dplyr::sample_n(classes_maps_diff2, size = 600)
# save 600 points
save(classes_maps_diff_600, file = paste0(base_dir, "/inst/extdata/results/classes_maps_diff_600.rds"))

# retrieve labelled samples with conflicting points
# 
labelled_samples <- paste0(base_dir, "/inst/extdata/results/labelled_conflicting_points.gpkg")
sf_points <- sf::st_read(labelled_samples)


# retrieve the data cube
cube_20LMR <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = "./inst/extdata/images"
)
# retrieve the samples 
samples <- readRDS(paste0(proj_dir, "inst/extdata/samples/deforestation_samples_v18.rds"))
# build the model
rf_model <- sits_train(
     samples,
     ml_method = sits_rfor()
)
# build the probabilities
probs_cube <- sits_classify(
     data = cube_20LMR,
     ml_model = rf_model,
     multicores = 16,
     memsize = 64,
     output_dir = paste0(proj_dir, "inst/extdata/probs")
)
# classified map without smoothing
class_cube_nosmooth <- sits_label_classification(
     cube = probs_cube,
     multicores = 16,
     memsize = 64,
     output_dir = paste0(proj_dir, "inst/extdata/class-no-smooth"),
     version = "no_smooth"
)
                             
# variance estimation 
var_cube <- sits_variance(
     cube = probs_cube,
     window_size = 7,
     neigh_fraction = 0.5,
     multicores = 16,
     memsize = 64,
     output_dir = paste0(proj_dir, "inst/extdata/variance")
)
# variance summary
var_classes <- summary(var_cube)
# print variance for classes
var_classes
# save variance for classes
saveRDS(var_classes, file = paste0(proj_dir,"./inst/extdata/results/var_classes.rds"))
# bayes smoothing
bayes_cube <- sits_smooth(
     cube = probs_cube,
     window_size = 7,
     smoothness = c(
          "Clear_Cut_Bare_Soil" = 6.5,
          "Clear_Cut_Burned_Area" = 14,
          "Clear_Cut_Vegetation" = 12,
          "Forest" = 4,
          "Mountainside_Forest" = 15,
          "Riparian_Forest" = 25,
          "Seasonally_Flooded" = 20,
          "Water" = 3,
          "Wetland" = 20
     ),
     multicores = 16,
     memsize = 64,
     output_dir = paste0(proj_dir, "inst/extdata/bayes")
)
# bayes classification 
bayes_class <- sits_label_classification(
     cube = bayes_cube,
     multicores = 16,
     memsize = 64,
     output_dir = paste0(proj_dir, "inst/extdata/class-bayes"),
     version = "bayes"
)
# smooth using gaussian methods
library(bayesEO)
# Probs filename
probs_filename <- "SENTINEL-2_MSI_20LMR_2022-01-05_2022-12-23_probs_v1.tif"
probs_file <- paste0(proj_dir, "/inst/extdata/probs/", probs_filename)

# Probs labels
labels <- sits_labels(samples)
names(labels) <- c(1:length(labels))
# create output directory
output_dir <- paste0(proj_dir, "/inst/extdata/gaussian/")

# read probs file
probs_data <- bayesEO::bayes_read_probs(
     probs_file = probs_file,
     labels     = labels
)
# smooth probs
probs_gaussian <- bayesEO::gaussian_smooth(
     x              = probs_data,
     window_size    = 7,
     sigma          = 5
)

# define output directory
gauss_filename <- "SENTINEL-2_MSI_20LMR_2022-01-05_2022-12-23_probs_gauss.tif"
gauss_file <- paste0(proj_dir, "/inst/extdata/gaussian/", gauss_filename)
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
     data_dir = paste0(proj_dir, "/inst/extdata/gaussian/"),
     bands = "probs",
     labels = labels,
     version = "gauss"
)
# generate a map for gaussian smoothing
gauss_map <- sits_label_classification(
     cube = gauss_probs_cube,
     memsize = 64,
     multicores = 16,
     output_dir = paste0(proj_dir, "/inst/extdata/class-gaussian/"),
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
bilat_file <- paste0(proj_dir, "/inst/extdata/bilateral/", bilat_filename)
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
     data_dir = paste0(proj_dir, "/inst/extdata/bilateral/"),
     bands = "probs",
     labels = labels,
     version = "bilat"
)
# generate a map for bilateral smoothing
bilat_map <- sits_label_classification(
     cube = bilat_probs_cube,
     memsize = 64,
     multicores = 16,
     output_dir = paste0(proj_dir, "/inst/extdata/class-bilat/"),
     version = "bilat"
)
# generate uncertainty cube
uncert_cube <- sits_uncertainty(
     cube = probs_cube,
     type = "margin",
     memsize = 64,
     multicores = 16,
     output_dir = paste0(proj_dir, "/inst/extdata/uncert/")
)
# generate data points with high uncertainty
uncert_samples <- sits_uncertainty_sampling(
     uncert_cube = uncert_cube,
     n = 300,
     min_uncert = 0.5,
     sampling_window = 10,
     multicores = 16,
     memsize = 64
)
saveRDS(uncert_samples, file = paste0(proj_dir, "./inst/extdata/results/uncert_samples.rds"))

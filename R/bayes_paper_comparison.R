library(sits)

# recover maps 
# 
# get the labels
samples <- readRDS("./inst/extdata/samples/deforestation_samples_v18.rds")
labels <- sits_labels(samples)
names(labels) <- c(1:length(labels))
# get the probability maps
probs_cube <- sits_cube(
        source = "MPC",
        collection = "SENTINEL-2-L2A",
        data_dir = "./inst/extdata/probs",
        labels = labels,
        bands = "probs"
)
# get a variance cube in 9 x 9 window
var_cube_9x9 <- sits_variance(
     cube = probs_cube,
     window_size = 9,
     neigh_fraction = 0.5,
     memsize = 4,
     multicores = 12,
     output_dir = "./inst/extdata/variance/",
     version = "9x9_window"
)
saveRDS(var_cube_9x9, file = "./inst/extdata/results/var_cube_9x9.rds")
# bayes smoothing
bayes_cube_9x9 <- sits_smooth(
     cube = probs_cube,
     window_size = 9,
     smoothness = c(
          "Clear_Cut_Bare_Soil" = 18,
          "Clear_Cut_Burned_Area" = 17,
          "Clear_Cut_Vegetation" = 12,
          "Forest" = 20,
          "Mountainside_Forest" = 15,
          "Riparian_Forest" = 35,
          "Seasonally_Flooded" = 18,
          "Water" = 5,
          "Wetland" = 16
     ),
     multicores = 4,
     memsize = 12,
     output_dir = "inst/extdata/bayes",
     version = "window_9x9"
)

map_bayes_9x9 <- sits_label_classification(
     cube = bayes_cube_9x9,
     multicores = 4,
     memsize = 12,
     output_dir = "inst/extdata/class-bayes",
     version = "window_9x9"
)
# produce uncertainty cube using entropy
uncert_cube_entropy <- sits_uncertainty(
        cube = probs_cube,
        output_dir = "./inst/extdata/uncert",
        type = "entropy"
)
# estimate 200 samples with high uncertainty
uncert_samples_500 <- sits_uncertainty_sampling(
        uncert_cube_entropy,
        n = 500, 
        min_uncert = 0.6,
        sampling_window = 100
)

# get the classification maps
# no smooth
map_no_smooth <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = "./inst/extdata/class-no-smooth",
     labels = labels,
     bands = "class",
     version = "no-smooth"
)
# bayes
map_bayes <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = "./inst/extdata/class-bayes",
     labels = labels,
     bands = "class",
     version = "bayes"
)
# gaussian
map_gaussian <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = "./inst/extdata/class-gaussian",
     labels = labels,
     bands = "class",
     version = "gauss"
)
# bilateral
map_bilat <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = "./inst/extdata/class-bilat",
     labels = labels,
     bands = "class",
     version = "bilat"
)
# choose a sampling design
sampling_design <- sits_sampling_design(
     cube = map_bayes_9x9,
     expected_ua = 0.85
)


# save samples with high uncertainty
saveRDS(uncert_samples_500, "./inst/extdata/results/uncert_samples_500.rds")

# get classes for map_no_smooth for uncert samples
classes_no_smooth <- sits_get_class(map_no_smooth, uncert_samples_500)
# get classes for map bayes for uncert samples
classes_bayes <- sits_get_class(map_bayes, uncert_samples_500)
# get classes for map gauss for uncert samples
classes_gauss <- sits_get_class(map_gaussian, uncert_samples_500)
# get classes for map bilat for uncert samples
classes_bilat <- sits_get_class(map_bilat, uncert_samples_500)
# join classes from maps
classes_maps <- tibble::tibble(
        id        = 1:nrow(classes_no_smooth),
        longitude = classes_no_smooth[["longitude"]],
        latitude = classes_no_smooth[["latitude"]],
        reference = "NoClass",
        no_smooth = classes_no_smooth[["label"]],
        bayes     = classes_bayes[["label"]],
        gauss     = classes_gauss[["label"]],
        bilat     = classes_bilat[["label"]]
)

# convert to csv
sits_to_csv(uncert_samples, file = "./inst/extdata/results/uncert_samples.csv")
# save QGIS style 
sits_colors_qgis(map_bayes, file = "./inst/extdata/results/bayes_paper.qml")

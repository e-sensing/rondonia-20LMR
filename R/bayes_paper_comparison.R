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

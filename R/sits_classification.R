# Script to classify Rondonia 20LMR tile
# 
# 1. Install the relevant libraries
library(tibble)
library(sits)
# 2. Get the training samples
deforestation_samples_v18 <- readRDS(
        file = "./inst/extdata/samples/deforestation_samples_v18.rds")

# 3. Show patterns of classes in the training set
deforestation_samples_v18  |> 
     sits_select(bands = c("B02", "B8A", "B11")) |> 
     sits_patterns() |> 
     plot()

# 4. Build a data cube from pre-processed images and plot a band combination
data_dir <- "./inst/extdata/images"

cube_20LMR <- sits_cube(
     source = "MPC",
     collection = "SENTINEL-2-L2A",
     data_dir = data_dir
)
# plot one temporal instance
plot(cube_20LMR, red = "B11", green = "B8A", blue = "B02", date = "2022-07-16")

# 5. Train the data set using random forests ML 
# You can chose any other ML method available in SITS
#  First reduce the number of bands to improve speed
samples_3bands <- sits_select(
        data = deforestation_samples_v18,
        bands = c("B02", "B8A", "B11")
)
# train the reduced set of samples using RF
rfor_model <- sits_train(
        samples = samples_3bands,
        ml_method = sits_rfor()
)

# 6. Classify the data cube 
# Create a directory to store the result
dir.create("~/rondonia20LMR_results")
output_dir <- "~/rondonia20LMR_results"
# Change multicores and memsize to fit our environment
cube_20LMR_probs <- sits_classify(
        data = cube_20LMR,
        ml_model = rfor_model,
        multicores = 4,
        memsize = 24,
        output_dir = output_dir
)
plot(cube_20LMR_probs, label = "Forest", palette = "YlGn")

# 7. Smooth probability cube
cube_20LMR_bayes <- sits_smooth(
        cube = cube_20LMR_probs,
        multicores = 4,
        memsize = 24,
        output_dir = output_dir
)
plot(cube_20LMR_bayes, label = "Forest", palette = "YlGn")

# 8. Label probability cube
# 
cube_20LMR_map <- sits_label_classification(
        cube = cube_20LMR_bayes,
        multicores = 4,
        memsize = 24,
        output_dir = output_dir
)
plot(cube_20LMR_map)

install.packages("raster")
devtools::install_github("JohMast/ImageFusion")

library(ImageFusion)
library(raster)


# Landsat
landsat_base_file <- "LANDSAT_RES_BASE_20240831.tif" 

# Modis
modis_base_file <- "RESAMPLE_MODIS_RES_BASE_20240831.tif"
modis_predict_file <- "RESAMPLE_MODIS_RES_PRED_20240730.tif"

# 4. Set a name for the final output file

output_file_name <- paste0("STARFM_fused_band_NDVI.tif")

## 3. LOAD THE IMAGES (No changes needed)
# ---------------------------------
print("Loading your 3 images...")
# raster() because each file is a single-layer image
# stack() to load the multi-band files
L8_stack <- stack(landsat_base_file)
MOD_stack_base <- stack(modis_base_file)
MOD_stack_pred <- stack(modis_predict_file)

landsat_red_band <- 3
landsat_nir_band <- 4

# (for MODIS: Red = band 1, NIR = band 2)
modis_red_band <- 1
modis_nir_band <- 2


landsat_red <- L8_stack[[landsat_red_band]]
landsat_nir <- L8_stack[[landsat_nir_band]]

landsat_ndvi <- (landsat_nir - landsat_red) / (landsat_nir + landsat_red)
plot(landsat_ndvi)
writeRaster(landsat_ndvi, "NDVI_LANDSAT_20240831.tif", overwrite = TRUE)

modis_red <- MOD_stack_base[[modis_red_band]]
modis_nir <- MOD_stack_base[[modis_nir_band]]
modis_red_pred <- MOD_stack_pred[[modis_red_band]]
modis_nir_pred <- MOD_stack_pred[[modis_nir_band]]

modis_ndvi_base <- (modis_nir - modis_red) / (modis_nir + modis_red)
writeRaster(modis_ndvi_base, "NDVI_MODIS_BASE_20240831.tif", overwrite = TRUE)
modis_ndvi_pred <- (modis_nir_pred - modis_red_pred) / (modis_nir_pred + modis_red_pred)
writeRaster(modis_ndvi_pred, "NDVI_MODIS_PRED_20240730.tif", overwrite = TRUE)


## 4. RUN STARFM
# ---------------------------------
print("Starting STARFM fusion... This can take a while.")

# Run the algorithm
starfm_job(
    input_filenames = c("NDVI_LANDSAT_20240831.tif", "NDVI_MODIS_BASE_20240831.tif", "NDVI_MODIS_PRED_20240730.tif"),
    input_resolutions = c("high", "low", "low"),
    input_dates = c(1, 1, 2),         # (Base, Base, Predict)
    pred_dates = c(2),               # (Predict)
    pred_filenames = c(output_file_name),
)

print("Fusion complete!")


## 5. SAVE THE RESULT
STARFM_Result <- raster(output_file_name)

print(paste("Success! Fused image saved as:", output_file_name))
plot(STARFM_Result)

L8_pred_stack <- stack('LANDSAT_RES_PRED_20240730.tif')
landsat_pred_red <- L8_pred_stack[[landsat_red_band]]
landsat_pred_nir <- L8_pred_stack[[landsat_nir_band]]
landsat_ndvi_pred <- (landsat_pred_nir - landsat_pred_red) / (landsat_pred_nir + landsat_pred_red)
plot(landsat_ndvi_pred)
writeRaster(landsat_ndvi_pred, "NDVI_LANDSAT_20240730.tif", overwrite = TRUE)

## Regresi
# --- 3. ALIGN AND MASK ---
# Ensure the images are aligned and have same extent/resolution
fused_resampled <- resample(STARFM_Result, landsat_ndvi_pred, method = "bilinear")

# Mask out NA values in either raster
mask_combined <- mask(fused_resampled, landsat_ndvi_pred)
mask_combined <- mask(mask_combined, landsat_ndvi_pred)

# Extract values as vectors
fused_vals <- getValues(fused_resampled)
landsat_vals <- getValues(landsat_ndvi_pred)

# Remove NA values
valid_idx <- which(!is.na(fused_vals) & !is.na(landsat_vals))
fused_vals <- fused_vals[valid_idx]
landsat_vals <- landsat_vals[valid_idx]

# --- 4. LINEAR REGRESSION ---
regression <- lm(landsat_vals ~ fused_vals)
summary(regression)

# Optional: Calculate R^2 manually
r_squared <- cor(fused_vals, landsat_vals)^2
print(paste("R-squared:", round(r_squared, 3)))

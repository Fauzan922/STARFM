# --- 1. LOAD REQUIRED PACKAGES ---
library(raster)
library(ggplot2)

# --- 2. LOAD IMAGES (if not already loaded) ---
# STARFM fused result
fused <- stack("STARFM_fused_band_3.tif")
band_to_process <- 3

# Real Landsat image for the prediction date (same band as used in STARFM)
landsat_real <- stack("LANDSAT_RES_PRED_20240831.tif")[[3]]

# --- 3. ALIGN AND MASK ---
# Ensure the images are aligned and have same extent/resolution
fused_resampled <- resample(fused, landsat_real, method = "bilinear")

# Mask out NA values in either raster
mask_combined <- mask(fused_resampled, landsat_real)
mask_combined <- mask(mask_combined, landsat_real)

# Extract values as vectors
fused_vals <- getValues(fused_resampled)
landsat_vals <- getValues(landsat_real)

# Remove NA values
valid_idx <- which(!is.na(fused_vals) & !is.na(landsat_vals))
fused_vals <- fused_vals[valid_idx]
landsat_vals <- landsat_vals[valid_idx]

# --- 4. LINEAR REGRESSION ---
regression <- lm(landsat_vals ~ fused_vals)
summary(regression)

# --- 5. SCATTER PLOT ---
df <- data.frame(Fused = fused_vals, Landsat = landsat_vals)

# --- 6. EXPORT VALUES TO CSV ---
export_data <- data.frame(Fused = fused_vals, Landsat = landsat_vals)

# Specify the file path where the CSV will be saved
write.csv(export_data, "regression_data.csv", row.names = FALSE)

# Confirm the export
cat("CSV file exported successfully!")

ggplot(df, aes(x = Fused, y = Landsat)) +
  geom_point(alpha = 0.3, color = "blue") +
  geom_smooth(method = "lm", color = "red") +
  labs(title = paste("Regression of STARFM vs Landsat - Band", band_to_process),
       x = "STARFM Fused",
       y = "Real Landsat") +
  theme_minimal()

# Optional: Calculate R^2 manually
r_squared <- cor(fused_vals, landsat_vals)^2
print(paste("R-squared:", round(r_squared, 3)))

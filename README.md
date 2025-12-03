STARFM
Implementation of the **Spatial and Temporal Adaptive Reflectance Fusion Model (STARFM)** using R / RStudio.  
This project aims to fuse high-spatial-resolution and high-temporal-resolution remote sensing imagery to generate enhanced reflectance products.

Description
This repository contains an R-based implementation of the STARFM algorithm.  
STARFM is commonly used to combine data from sensors such as Landsat (high spatial resolution, low temporal resolution) and MODIS (low spatial resolution, high temporal resolution) to produce synthetic images with both high spatial and temporal detail.

Requirements
Before running the scripts, ensure you have:

- R
- Rtools that allign with the version of R
- Geospatial package installed (Rasterio, sf, etc)

Notes
- Input data must follow the required spatial, temporal, and projection specifications.
- Output quality strongly depends on compatibility and preprocessing of input imagery.
- Some datasets may need atmospheric correction or harmonization before processed in STARFM.

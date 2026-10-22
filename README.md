# gdal_class

# GDAL class for disturbance mapping using satellite monitoring data 
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_learning/

How to start (before the class)
1. Install R and RStudio
2. Download this repository (Code > Download ZIP) and unzip it (Extract all) in a simple folder, e.g. C:/aula_gdal
3. Open setup_environment.R in RStudio and click Source - it installs conda (Miniforge) and GDAL, and downloads the data (~10-15 min, ~2 GB of disk), wait for "setup ok"

Scripts
- setup_environment.R : installs and finds everything the labs need - run it once before the class, it is also sourced at the top of each lab
- lab1_prodes_deter.R : PRODES and DETER overlap analysis
- lab2_evi_anomaly.R : EVI anomalies during the Amazon droughts
- initial_data_prep.R : this was for internal usage to create the initial test data - do not run this

Activities:

1- cropping raster to extent with gdal_translate

2- cropping vector to extent with ogr2ogr

3- Filtering with gdal_calc : Create PRODES deforestation year 

4- Rasterization with gdal_rasterize : Rasterize DETER to PRODES grid

5- Overlap analysis with gdal_calc : Combine DETER+PRODES

6- Statistics of the overlap analysis

GDAL Functions used:
- gdal_translate
- ogr2ogr
- gdal_rasterize
- gdal_calc
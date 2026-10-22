# GDAL class for disturbance mapping using satellite monitoring data --------------------------------------------------------------
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_learning/

# setup - installs what is missing (only the first time, ~10 min), finds GDAL, defines the folders and downloads the data
## in RStudio the working directory is set to the folder of this script, so no paths need to be changed
if (!requireNamespace("rstudioapi", quietly = T)) install.packages("rstudioapi")
if (rstudioapi::isAvailable()) setwd(dirname(rstudioapi::getSourceEditorContext()$path))
source("setup_environment.R")


# paths to the datasets within the repository - do not need to change this
test_aoi2 = file.path(repository_dir, "test_aoi2.gpkg")
prodes2024 = file.path(repository_dir, "prodes2024_crop_aoi1.tif")
deter2024 = file.path(repository_dir, "deter2024_crop_aoi1.gpkg")

## First start by visualizing these data and aoi in QGIS
## DETER was already filtered to remove Deforestation alerts, only Degradation alerts remain




# @@@ 1- cropping raster to extent with gdal_translate ----------------------------------------------------------------

# define extent based on the vector aoi2
aoi = vect(test_aoi2)
new_ext = ext(aoi)

# crop prodes2024 to aoi2
prodes2024_crop_aoi2 = file.path(project_dir, "prodes2024_crop_aoi2.tif")
gdal_translate_run = paste(gdal_translate,
                           "-projwin", xmin(new_ext), ymax(new_ext), xmax(new_ext), ymin(new_ext),
                           "-co COMPRESS=DEFLATE -co PREDICTOR=2 --config GDAL_CACHEMAX 75",
                           shQuote(prodes2024),
                           shQuote(prodes2024_crop_aoi2)
)
print(gdal_translate_run)
system(gdal_translate_run)

## visualize in QGIS
## Quick plot here
# plot(rast(prodes2024_crop_aoi2))



# @@@ 2- cropping vector to extent with ogr2ogr -----------------------------------------------------

# define extent based on the vector aoi2
aoi = vect(test_aoi2)
new_ext = ext(aoi)

# crop deter2024 to aoi2 using ogr2ogr
deter2024_crop_aoi2 <- file.path(project_dir, "deter2024_crop_aoi2.gpkg")
ogr2ogr_run <- paste(
  ogr2ogr,                                       # path to ogr2ogr binary
  "-f GPKG",                                     # output format
  shQuote(deter2024_crop_aoi2),                 # output file
  shQuote(deter2024),                           # input file
  "-clipsrc", xmin(new_ext), ymin(new_ext), xmax(new_ext), ymax(new_ext),  # clip extent (xmin ymin xmax ymax)
  "-nlt PROMOTE_TO_MULTI",                       # ensure geometry consistency
  "-nln deter2024_crop_aoi1",                   # output layer name
  "--config OGR_GPKG_FOREIGN_KEY_CHECK OFF"      # optional: speed-up for GPKG
)
print(ogr2ogr_run)
system(ogr2ogr_run)

## more operations and parameters here https://gdal.org/en/stable/programs/ogr2ogr.html#ogr2ogr

## visualize in QGIS
## quick plot here
# plot(vect(deter2024_crop_aoi2))


# @@@ 3- Filtering with gdal_calc : Create PRODES deforestation year --------

# define the operations we will be doing
calc_str = paste("--calc \" numpy.where(A==7, 1990,
                           numpy.where(logical_and(A>=8,A<=49), A.astype(numpy.uint16) + 2000,
                           numpy.where(logical_and(A>=50,A<=90), A.astype(numpy.uint16) - 40 + 2000,
                           numpy.where(A==100, 1, 0)))) \"")
## Remaining Forest will be == 1
## PRODES is Byte (0-255), so A + 2000 does not fit : A.astype(numpy.uint16) first converts A to UInt16 (0-65535)

# calc
prodes_year = file.path(project_dir, "prodes_year.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",shQuote(prodes2024_crop_aoi2),
                      #"--quiet",
                      "--overwrite",
                      "--outfile", shQuote(prodes_year)
)
print(gdal_calc_run)
system(gdal_calc_run)
# plot(rast(prodes_year))

## Visualize in QGIS, now we have PRODES year e.g. 2020, value 1 for forest, or 0 for rest
## exercise : if i wanted to get only prodes deforestation binary, how would one achieve that with gdal_calc ?



# @@@ 4- Rasterization with gdal_rasterize : Rasterize DETER to PRODES grid --------

# rasterize binary degradation
new_ext = ext(rast(prodes_year))
tr1 = res(rast(prodes_year))[1]
tr = paste("-tr", tr1, tr1)
deter_binary = file.path(project_dir, "deter_binary.tif")
gdal_rasterize_run = paste(gdal_rasterize,
                           "-burn 1",
                           "-te", xmin(new_ext), ymin(new_ext), xmax(new_ext), ymax(new_ext),
                           tr,
                           "-ot Byte", # 0-255
                           "-init 0 -a_nodata 255", # pixels start as 0 = no degradation, otherwise gdal_rasterize marks 0 as nodata
                           "-co COMPRESS=DEFLATE",
                           shQuote(deter2024),
                           shQuote(deter_binary)
)
print(gdal_rasterize_run)
system(gdal_rasterize_run)
# plot(rast(deter_binary))
# plot(rast(prodes_year))

## Visualize in QGIS
## note the two rasters have same dimension and extent - they are ready for analysis
## if you filter DETER for specific degradation, you can create different rasters for each degradation type
## more operations and parameters here https://gdal.org/en/stable/programs/gdal_rasterize.html#gdal-rasterize



# @@@ 5- Overlap analysis with gdal_calc : Combine DETER+PRODES --------

## Here we want to combine DETER+PRODES to assess how much area was degraded, deforested, or both
## for that, gdal_calc is our best friend forever

## rationale :
## for this analysis we will do a trick where we combine sets of values
## prodes is 0,1,1990,2008-2024
## deter is 0,1
## since prodes does not have numbers bigger than 10000, lets make deter 0,10000, then sum both and voila!

# multiply deter by 10000 so its either 0 or 10000
calc_str = paste("--calc \" A.astype(numpy.uint16)*10000 \"") # deter is Byte (0-255), convert to UInt16 so 10000 fits
deter_binary10000 = file.path(project_dir, "deter_binary10000.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",shQuote(deter_binary),
                      #"--quiet",
                      "--overwrite",
                      "--outfile", shQuote(deter_binary10000)
)
print(gdal_calc_run)
system(gdal_calc_run)
# plot(rast(deter_binary10000))

## Always visualize/validate results before going deep into analysis.


# sum prodes and deter
calc_str = paste("--calc \" A+B \"")
overlap_prodes_deter = file.path(project_dir, "overlap_prodes_deter.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",shQuote(prodes_year),
                      "-B",shQuote(deter_binary10000),
                      #"--quiet",
                      "--overwrite",
                      "--outfile", shQuote(overlap_prodes_deter)
)
print(gdal_calc_run)
system(gdal_calc_run)
# plot(rast(overlap_prodes_deter))

## Visualize in QGIS see all the different numbers
## more operations and parameters here https://gdal.org/en/stable/programs/gdal_calc.html#gdal-calc


# @@@ 6- Statistics of the overlap analysis --------------------------------------

# lets do a simple analysis now, get the table frequency of values
r = rast(overlap_prodes_deter)
r_table = table(values(r))
print(r_table)

# calculate relative frequency
r_table_relative = r_table * 100 / sum(r_table)
r_table_combined = data.frame(pixel_value = names(r_table), pixel_count = as.numeric(r_table), pixel_count_relative = as.numeric(r_table_relative))
r_table_combined$pixel_count_relative
r_table_combined$pixel_count_relative <- format(r_table_combined$pixel_count_relative, scientific = FALSE)
print(r_table_combined)

## exercise 1 : how much % of the area was deforested between 2008 and 2024?
## exercise 2 : how much % of the area was degraded ?
## exercise 3 : how much % of the area was degraded and then deforested ?
## extra exercise if there is enough time : gdal_retile, gdal_sieve, gdal_polygonize, check at https://gdal.org/en/stable/programs/index.html

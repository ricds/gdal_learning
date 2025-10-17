# GDAL class for disturbance mapping using satellite monitoring data --------------------------------------------------------------
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_class/

# libraries
library(sf)
library(raster)


# conda config ------------------------------------------------------

## download miniconda3
## open the anaconda prompt terminal, and type in :
# conda create -n gdal_py36 python=3.6.3
# activate gdal_py36
# conda install -c conda-forge gdal
## in Windows, to add this version of gdal to environmental variables - may not be needed if we use the whole path when calling functions
# Win+R --> control sysdm.cpl --> environmental variables --> System variables (bottom) --> add to Path the environment folder e.g. C:\ProgramData\Miniconda3\envs\gdal_py36\
## check if the environment is installed, gdal_py36 should be listed there
# conda env list
## get the folder besides gdal_py36 and assign to the objects below, find the other directories, should follow the same file structure though
## these are the locations where the gdal functions were installed, you can check there all the functions that 
gdal_path = "C:\\ProgramData\\miniconda3\\envs\\gdal_py36\\Library\\bin\\"
py_path = "C:\\ProgramData\\miniconda3\\envs\\gdal_py36\\"
gdal_py_path = "C:\\ProgramData\\miniconda3\\envs\\gdal_py36\\Scripts\\"

# define functions to simplify the usage
gdalinfo = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdalinfo.exe"))))
gdaladdo = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdaladdo.exe"))))
gdalbuildvrt = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdalbuildvrt.exe"))))
gdal_translate = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdal_translate.exe"))))
gdalwarp = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdalwarp.exe"))))
gdal_retile = paste(paste0(py_path,"python"), paste0(gdal_py_path, "gdal_retile.py"))
gdal_calc = paste(paste0(py_path,"python"), paste0(gdal_py_path, "gdal_calc.py"))
gdaldem = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdaldem.exe"))))
gdal_rasterize = shQuote(shortPathName(normalizePath(file.path(gdal_path, "gdal_rasterize.exe"))))
gdal_proximity = paste(paste0(py_path,"python"), paste0(gdal_py_path, "gdal_proximity.py"))
gdal_sieve = paste(paste0(py_path,"python"), paste0(gdal_py_path, "gdal_sieve.py"))
ogr2ogr = shQuote(shortPathName(normalizePath(file.path(gdal_path, "ogr2ogr.exe"))))


# define directories ------------------------------------------------------

# define the repository directory
repository_dir = "D:/Meus_Documentos/GitHub/gdal_class/"

# define the project directory, where files will be saved during the exercises
project_dir = "D:/class_analysis/"
dir.create(project_dir, showWarnings = F)



# define paths to the datasets within the repository - do not need to change this ------------------------------------------

# paths to data
test_aoi2 = paste0(repository_dir, "test_aoi2.gpkg")
prodes2024 = paste0(repository_dir, "prodes2024_crop_aoi1.tif")
deter2024 = paste0(repository_dir, "deter2024_crop_aoi1.gpkg")

## First start by visualizing these data and aoi in QGIS
## DETER was already filtered to remove Deforestation alerts, only Degradation alerts remain




# @@@ 1- cropping raster to extent with gdal_translate ----------------------------------------------------------------

# define extent based on the vector aoi2
aoi = st_read(test_aoi2)
new_ext = extent(aoi)

# crop prodes2024 to aoi2
prodes2024_crop_aoi2 = paste0(project_dir, "prodes2024_crop_aoi2.tif")
gdal_translate_run = paste(gdal_translate,
                           "-projwin", new_ext@xmin, new_ext@ymax, new_ext@xmax, new_ext@ymin,
                           "-co COMPRESS=DEFLATE -co PREDICTOR=2 --config GDAL_CACHEMAX 75",
                           prodes2024,
                           prodes2024_crop_aoi2
)
print(gdal_translate_run)
system(gdal_translate_run)

## visualize in QGIS




# @@@ 2- cropping vector to extent with ogr2ogr -----------------------------------------------------

# define extent based on the vector aoi2
aoi = st_read(test_aoi2)
new_ext = extent(aoi)

# crop deter2024 to aoi2 using ogr2ogr
deter2024_crop_aoi2 <- paste0(project_dir, "deter2024_crop_aoi2.gpkg")
ogr2ogr_run <- paste(
  ogr2ogr,                                       # path to ogr2ogr binary
  "-f GPKG",                                     # output format
  deter2024_crop_aoi2,                          # output file
  deter2024,                                    # input file
  "-clipsrc", new_ext@xmin, new_ext@ymin, new_ext@xmax, new_ext@ymax,  # clip extent (xmin ymin xmax ymax)
  "-nlt PROMOTE_TO_MULTI",                       # ensure geometry consistency
  "-nln deter2024_crop_aoi1",                   # output layer name
  "--config OGR_GPKG_FOREIGN_KEY_CHECK OFF"      # optional: speed-up for GPKG
)
print(ogr2ogr_run)
system(ogr2ogr_run)

## visualize in QGIS
## more operations and parameters here https://gdal.org/en/stable/programs/ogr2ogr.html#ogr2ogr



# @@@ 3- Filtering with gdal_calc : Create PRODES deforestation year --------

# define the operations we will be doing
calc_str = paste("--calc \" numpy.where(A==7, 1990,
                           numpy.where(logical_and(A>=8,A<=49), A + 2000,
                           numpy.where(logical_and(A>=50,A<=90), A - 40 + 2000,
                           numpy.where(A==100, 1, 0)))) \"")
## Remaining Forest will be == 1

# calc
prodes_year = paste0(project_dir, "prodes_year.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",prodes2024_crop_aoi2,
                      #"--quiet",
                      "--overwrite",
                      "--outfile", prodes_year
)
print(gdal_calc_run)
system(gdal_calc_run)

## Visualize in QGIS, now we have PRODES year e.g. 2020, value 1 for forest, or 0 for rest
## exercise : if i wanted to get only prodes deforestation binary, how would one achieve that with gdal_calc ?




# @@@ 4- Rasterization with gdal_rasterize : Rasterize DETER to PRODES grid --------

# rasterize binary degradation
new_ext = extent(raster(prodes_year))
tr1 = res(raster(prodes_year))[1]
tr = paste("-tr", tr1, tr1)
deter_binary = paste0(project_dir, "deter_binary.tif")
gdal_rasterize_run = paste(gdal_rasterize,
                           "-burn 1",
                           "-te", new_ext@xmin, new_ext@ymin, new_ext@xmax, new_ext@ymax,
                           tr,
                           "-ot Byte", # 0-255
                           "-co COMPRESS=DEFLATE",
                           deter2024,
                           deter_binary
)
print(gdal_rasterize_run)
system(gdal_rasterize_run)
# plot(raster(deter_i_binary))
# plot(raster(prodes_i_binary))

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
calc_str = paste("--calc \" A*10000 \"")
deter_binary10000 = paste0(project_dir, "deter_binary10000.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",deter_binary,
                      #"--quiet",
                      "--overwrite",
                      "--outfile", deter_binary10000
)
print(gdal_calc_run)
system(gdal_calc_run)

## Always visualize/validate results before going deep into analysis.


# sum prodes and deter
calc_str = paste("--calc \" A+B \"")
overlap_prodes_deter = paste0(project_dir, "overlap_prodes_deter.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",prodes_year,
                      "-B",deter_binary10000,
                      #"--quiet",
                      "--overwrite",
                      "--outfile", overlap_prodes_deter
)
print(gdal_calc_run)
system(gdal_calc_run)

## Visualize in QGIS see all the different numbers
## more operations and parameters here https://gdal.org/en/stable/programs/gdal_calc.html#gdal-calc


# @@@ 6- Statistics of the overlap analysis --------------------------------------

# lets do a simple analysis now, get the table frequency of values
r = raster(overlap_prodes_deter)
r_table = table(r[])
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

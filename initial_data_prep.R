# GDAL class data prep --------------------------------------------------------------
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_class/

## This script prepares the initial data given in this repository, do not need to run it

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


# crop original data to test AOI ------------------------------------------

# paths to data
prodes2024 = "D:/1_Dataset/8_LANDCOVER/1_PRODES/8_PRODES_Amazonia_Legal_2024/prodes_amazonia_legal_2024.tif"
deter2024 = "D:/1_Dataset/8_LANDCOVER/11_DETER_alerts/2_deter-amz-public-2025feb24/deter-amz-deter-public.shp"
test_aoi1 = "D:/Meus_Documentos/GitHub/gdal_class/test_aoi1.gpkg"
repository_dir = "D:/Meus_Documentos/GitHub/gdal_class/"
project_dir = "D:/class_analysis/"
dir.create(project_dir, showWarnings = F)


# cropping raster to extent ----------------------------------------------------------------

# define extent based on the vector aoi1
aoi1 = st_read(test_aoi1)
new_ext = extent(aoi1)

# crop prodes2024 to aoi1
prodes2024_crop_aoi1 = paste0(repository_dir, "prodes2024_crop_aoi1.tif")
gdal_translate_run = paste(gdal_translate,
                           "-projwin", new_ext@xmin, new_ext@ymax, new_ext@xmax, new_ext@ymin,
                           "-co COMPRESS=DEFLATE -co PREDICTOR=2 --config GDAL_CACHEMAX 75",
                           prodes2024,
                           prodes2024_crop_aoi1
)
system(gdal_translate_run)


# crop vector to extent -----------------------------------------------------

# crop deter2024 to aoi1 using ogr2ogr
deter2024_crop_aoi1 <- paste0(repository_dir, "deter2024_crop_aoi1.gpkg")
ogr2ogr_run <- paste(
  ogr2ogr,                                       # path to ogr2ogr binary
  "-f GPKG",                                     # output format
  deter2024_crop_aoi1,                          # output file
  deter2024,                                    # input file
  "-clipsrc", new_ext@xmin, new_ext@ymin, new_ext@xmax, new_ext@ymax,  # clip extent (xmin ymin xmax ymax)
  "-nlt PROMOTE_TO_MULTI",                       # ensure geometry consistency
  "-nln deter2024_crop_aoi1",                   # output layer name
  "--config OGR_GPKG_FOREIGN_KEY_CHECK OFF"      # optional: speed-up for GPKG
)
system(ogr2ogr_run)


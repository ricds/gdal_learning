# Setup of the class environment --------------------------------------------------------------
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_learning/

## Run this script once before the class (Source button in RStudio), it is also sourced at the top of every lab
## The first time it runs it installs what is missing (~10-15 min, ~2 GB), after that it only finds things:
## 1- R packages
## 2- conda (Miniforge) and a conda environment called gdal_class with GDAL
## 3- the paths to the GDAL functions
## 4- the class data (downloaded from Google Drive)


# 1- R packages ------------------------------------------------------

neededPackages = c("terra", "RColorBrewer", "rstudioapi")
missingPackages = neededPackages[!neededPackages %in% rownames(installed.packages())]
if (length(missingPackages) > 0) install.packages(missingPackages)
library(terra)

# folders, relative to the repository folder - in RStudio the working directory is set to the folder of the open script
if (rstudioapi::isAvailable()) setwd(dirname(rstudioapi::getSourceEditorContext()$path))
if (!file.exists("setup_environment.R")) stop("the working directory is not the repository folder : in RStudio use Session > Set Working Directory > To Source File Location")
repository_dir = getwd()
data_dir = file.path(repository_dir, "data")
project_dir = file.path(repository_dir, "class_analysis") # where files will be saved during the exercises
dir.create(project_dir, showWarnings = F)


# 2- conda and the gdal_class environment ------------------------------------------------------

is_windows = .Platform$OS.type == "windows"
home = if (is_windows) Sys.getenv("USERPROFILE") else path.expand("~")
env_name = "gdal_class"

# places where conda is usually installed
conda_roots = c(file.path(home, c("miniforge3", "miniconda3", "anaconda3")),
                "C:/miniforge3", "C:/ProgramData/miniforge3", "C:/ProgramData/miniconda3", "C:/ProgramData/anaconda3",
                "/opt/miniforge3", "/opt/miniconda3", "/opt/anaconda3")
if (Sys.which("conda") != "") conda_roots = c(dirname(dirname(Sys.which("conda"))), conda_roots)
conda_exe = file.path(conda_roots, if (is_windows) "Scripts/conda.exe" else "bin/conda")
conda_exe = conda_exe[file.exists(conda_exe)][1]

# if there is no conda, install Miniforge (a small conda that uses conda-forge by default)
if (is.na(conda_exe)) {
  message("conda not found, installing Miniforge...")
  options(timeout = 3600)
  url = "https://github.com/conda-forge/miniforge/releases/latest/download/"
  if (is_windows) {
    ## conda does not like spaces or accents in the folder name, e.g. C:/Users/Joao Silva
    conda_root = file.path(home, "miniforge3")
    if (grepl("[^A-Za-z0-9_:/\\\\.-]", conda_root)) conda_root = "C:/miniforge3"
    installer = file.path(tempdir(), "Miniforge3-Windows-x86_64.exe")
    download.file(paste0(url, "Miniforge3-Windows-x86_64.exe"), installer, mode = "wb")
    system(paste(shQuote(installer), "/InstallationType=JustMe /RegisterPython=0 /AddToPath=0 /S",
                 paste0("/D=", normalizePath(conda_root, mustWork = F))))
    conda_exe = file.path(conda_root, "Scripts/conda.exe")
  } else {
    conda_root = file.path(home, "miniforge3")
    os = if (Sys.info()[["sysname"]] == "Darwin") "MacOSX" else "Linux"
    installer = file.path(tempdir(), "Miniforge3.sh")
    download.file(paste0(url, "Miniforge3-", os, "-", Sys.info()[["machine"]], ".sh"), installer, mode = "wb")
    system(paste("bash", shQuote(installer), "-b -p", shQuote(conda_root)))
    conda_exe = file.path(conda_root, "bin/conda")
  }
  conda_roots = c(conda_root, conda_roots)
}

# find the gdal_class environment, if it does not exist create it with GDAL from conda-forge
find_env = function() {
  env_dirs = c(file.path(conda_roots, "envs", env_name), file.path(home, ".conda", "envs", env_name))
  env_dirs[dir.exists(env_dirs)][1]
}
env_dir = find_env()
if (is.na(env_dir)) {
  message("creating the conda environment ", env_name, " with GDAL...")
  system(paste(shQuote(conda_exe), "create -y -n", env_name, "-c conda-forge --override-channels gdal=3.12"))
  env_dir = find_env()
  if (is.na(env_dir)) stop("could not create the conda environment ", env_name, ", see the messages above")
}
## the same by hand, in the terminal (Miniforge Prompt) :
# conda create -y -n gdal_class -c conda-forge --override-channels gdal=3.12
# conda env list


# 3- paths to the GDAL functions ------------------------------------------------------

bin_dir = file.path(env_dir, if (is_windows) "Library/bin" else "bin")
share_dir = file.path(env_dir, if (is_windows) "Library/share" else "share")
python = file.path(env_dir, if (is_windows) "python.exe" else "bin/python")
exe = if (is_windows) ".exe" else ""

# the GDAL functions need to find their own support files
Sys.setenv(GDAL_DATA = file.path(share_dir, "gdal"), PROJ_DATA = file.path(share_dir, "proj"), PROJ_LIB = file.path(share_dir, "proj"))

# define functions to simplify the usage
gdal_function = function(name) shQuote(normalizePath(file.path(bin_dir, paste0(name, exe))))
gdal_py_function = function(name) paste(shQuote(normalizePath(python)), "-m", paste0("osgeo_utils.", name))
gdalinfo = gdal_function("gdalinfo")
gdaladdo = gdal_function("gdaladdo")
gdalbuildvrt = gdal_function("gdalbuildvrt")
gdal_translate = gdal_function("gdal_translate")
gdalwarp = gdal_function("gdalwarp")
gdaldem = gdal_function("gdaldem")
gdal_rasterize = gdal_function("gdal_rasterize")
ogr2ogr = gdal_function("ogr2ogr")
gdal_calc = gdal_py_function("gdal_calc")
gdal_retile = gdal_py_function("gdal_retile")
gdal_proximity = gdal_py_function("gdal_proximity")
gdal_sieve = gdal_py_function("gdal_sieve")


# 4- class data ------------------------------------------------------

# files in the class Google Drive folder https://drive.google.com/drive/folders/1rnAEkjYTJFK4zN5pOAuuLVFE_lmxqFBH
drive_files = c("MAIAC_Amazonia_EVI_August.tif" = "1fl5O6nuAJYNtaEecxvx1pBrBgrdN_ujC",
                "Limite_Estados/estadosl_2007.shp" = "1LiXMN2PJlubagVkP717fjcI0Eq8i2g-L",
                "Limite_Estados/estadosl_2007.shx" = "1QR4_Q4SVr9eQrKTPwwwCAggxnLWqQ5La",
                "Limite_Estados/estadosl_2007.dbf" = "1qLS--eYX3f6jB2Z40eOFBXtToFusmqrb")
for (f in names(drive_files)) {
  dest = file.path(data_dir, f)
  if (!file.exists(dest)) {
    message("downloading ", f, "...")
    options(timeout = 3600)
    dir.create(dirname(dest), recursive = T, showWarnings = F)
    url = paste0("https://drive.usercontent.google.com/download?id=", drive_files[[f]], "&export=download&confirm=t")
    download.file(url, paste0(dest, ".part"), mode = "wb")
    file.rename(paste0(dest, ".part"), dest) # only after the download finished, so a broken download is not kept
  }
}


# check that GDAL works
system(paste(gdalinfo, "--version"))
message("setup ok - GDAL in ", env_dir, "\noutputs will be saved in ", project_dir)

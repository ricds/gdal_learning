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
evi_data = "D:/2_Projects/7_Presentation_Classes/38_Lecture_Forest_Disturbance_geospatial_analysis/1_Class_v1_INPE_2025/Lab_TS/3_Anomaly_EVI/MAIAC_Amazonia_EVI_August.tif"




# @@@ 1- cropping raster to extent with gdal_translate ----------------------------------------------------------------


# define the operations we will be doing
calc_str = paste("--calc \" (A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q)/17 \"")
calc_str = paste("--calc \" numpy.nanmean([A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q], axis=0) \"")
calc_str = paste("--calc \" numpy.nanstd([A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q], axis=0) \"")

calc_str = paste("--calc \" numpy.nanmean([numpy.where(numpy.isnan(A) | (A==-9999), numpy.nan, A), \
  numpy.where(numpy.isnan(B) | (B==-9999), numpy.nan, B), \
  numpy.where(numpy.isnan(C) | (C==-9999), numpy.nan, C), \
  numpy.where(numpy.isnan(D) | (D==-9999), numpy.nan, D), \
  numpy.where(numpy.isnan(E) | (E==-9999), numpy.nan, E), \
  numpy.where(numpy.isnan(F) | (F==-9999), numpy.nan, F), \
  numpy.where(numpy.isnan(G) | (G==-9999), numpy.nan, G), \
  numpy.where(numpy.isnan(H) | (H==-9999), numpy.nan, H), \
  numpy.where(numpy.isnan(I) | (I==-9999), numpy.nan, I), \
  numpy.where(numpy.isnan(J) | (J==-9999), numpy.nan, J), \
  numpy.where(numpy.isnan(K) | (K==-9999), numpy.nan, K), \
  numpy.where(numpy.isnan(L) | (L==-9999), numpy.nan, L), \
  numpy.where(numpy.isnan(M) | (M==-9999), numpy.nan, M), \
  numpy.where(numpy.isnan(N) | (N==-9999), numpy.nan, N), \
  numpy.where(numpy.isnan(O) | (O==-9999), numpy.nan, O), \
  numpy.where(numpy.isnan(P) | (P==-9999), numpy.nan, P), \
  numpy.where(numpy.isnan(Q) | (Q==-9999), numpy.nan, Q)], axis=0) \"")

# calc
evi_data_mean = paste0(project_dir, "evi_data_mean4.tif")
evi_data_mean = paste0(project_dir, "evi_data_std.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      "--format GTiff --type UInt16",
                      "--co COMPRESS=DEFLATE",
                      "-A",evi_data,"--A_band=1",
                      "-B",evi_data,"--B_band=2",
                      "-C",evi_data,"--C_band=3",
                      "-D",evi_data,"--D_band=4",
                      "-E",evi_data,"--E_band=5",
                      "-F",evi_data,"--F_band=6",
                      "-G",evi_data,"--G_band=7",
                      "-H",evi_data,"--H_band=8",
                      "-I",evi_data,"--I_band=9",
                      "-J",evi_data,"--J_band=10",
                      "-K",evi_data,"--K_band=11",
                      "-L",evi_data,"--L_band=12",
                      "-M",evi_data,"--M_band=13",
                      "-N",evi_data,"--N_band=14",
                      "-O",evi_data,"--O_band=15",
                      "-P",evi_data,"--P_band=16",
                      "-Q",evi_data,"--Q_band=17",
                      #"--quiet",
                      "--overwrite",
                      "--outfile", evi_data_mean
)
print(gdal_calc_run)
system(gdal_calc_run)


calc_str = paste("--calc numpy.std([A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q], axis=0) \" ) \"")



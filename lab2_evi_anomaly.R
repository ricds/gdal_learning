# GDAL class for disturbance mapping using satellite monitoring data --------------------------------------------------------------
# Lab 2 - EVI anomalies during the Amazon droughts
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_learning/

# setup - installs what is missing (only the first time, ~10 min), finds GDAL, defines the folders and downloads the data
## in RStudio the working directory is set to the folder of this script, so no paths need to be changed
if (!requireNamespace("rstudioapi", quietly = T)) install.packages("rstudioapi")
if (rstudioapi::isAvailable()) setwd(dirname(rstudioapi::getSourceEditorContext()$path))
source("setup_environment.R")


# paths to data - do not need to change this
evi_data = file.path(data_dir, "MAIAC_Amazonia_EVI_August.tif")
states = file.path(data_dir, "Limite_Estados", "estadosl_2007.shp")
## MODIS (MAIAC) EVI of August from 2000 to 2016, one band per year : band 1 = 2000, band 2 = 2001 ... band 17 = 2016
## EVI values are multiplied by 10000




# @@@ 1- Looking at the data with gdalinfo and gdal_translate ----------------------------------------------------------------

# information about the raster : size, resolution, projection, number of bands, nodata
gdalinfo_run = paste(gdalinfo, shQuote(evi_data))
print(gdalinfo_run)
system(gdalinfo_run)

# extract one year from the stack, 2005 is band 6
evi_2005 = file.path(project_dir, "evi_2005.tif")
gdal_translate_run = paste(gdal_translate,
                           "-b 6",
                           "-co COMPRESS=DEFLATE",
                           shQuote(evi_data),
                           shQuote(evi_2005)
)
print(gdal_translate_run)
system(gdal_translate_run)

# visualize
plot(rast(evi_2005))

# visualize
## we exclude data <5th percentile and >95th percentile to improve visualization
r_test = rast(evi_2005)
q = quantile(values(r_test), probs = c(0.05, 0.95), na.rm = T)
r_test[r_test < q[1] | r_test > q[2]] = NA
plot(r_test)




# @@@ 2- Mean and standard deviation of the normal years with gdal_calc ----------------------------------------------------------------

# select non drought years to calculate mean and sd, without drought years (2005, 2010, 2015, 2016)
## we remove the years of interest because our time series is short
nodrought_bands = c(1,2,3,4,5,7,8,9,10,12,13,14,15)
band_letters = LETTERS[1:length(nodrought_bands)] # gdal_calc gives one letter to each input : A, B, C ...

# inputs of gdal_calc : -A file --A_band=1 -B file --B_band=2 ...
calc_inputs = paste0("-", band_letters, " ", shQuote(evi_data), " --", band_letters, "_band=", nodrought_bands, collapse = " ")
print(calc_inputs)

# nodata (-1.7e308) becomes NaN, so nanmean and nanstd skip the missing years - like mean(x, na.rm=T) in R
calc_bands = paste0("numpy.where(", band_letters, " < -1e300, numpy.nan, ", band_letters, ")", collapse = ", ")
print(calc_bands)
## without this, a pixel missing in any of the 13 years would be lost : that is ~40% of the Amazon in this data
## pixels with no data in any year give a warning "Mean of empty slice" - that is ok, they become nodata (-9999)
## gdal_calc may print other warnings in red (RuntimeWarning, DeprecationWarning) - they are ok, the result is fine

# calc the mean
calc_str = paste0("--calc \"numpy.nan_to_num(numpy.nanmean([", calc_bands, "], axis=0), nan=-9999)\"")
evi_mean = file.path(project_dir, "evi_mean.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      calc_inputs,
                      "--hideNoData --NoDataValue=-9999", # hideNoData : we treat the nodata ourselves in the formula
                      "--format GTiff --type Float32",
                      "--co COMPRESS=DEFLATE",
                      "--overwrite",
                      "--outfile", shQuote(evi_mean)
)
print(gdal_calc_run)
system(gdal_calc_run)

# calc the sd
## ddof=1 is the sample standard deviation, the same as sd() in R
calc_str = paste0("--calc \"numpy.nan_to_num(numpy.nanstd([", calc_bands, "], axis=0, ddof=1), nan=-9999)\"")
evi_sd = file.path(project_dir, "evi_sd.tif")
gdal_calc_run = paste(gdal_calc,
                      calc_str,
                      calc_inputs,
                      "--hideNoData --NoDataValue=-9999",
                      "--format GTiff --type Float32",
                      "--co COMPRESS=DEFLATE",
                      "--overwrite",
                      "--outfile", shQuote(evi_sd)
)
print(gdal_calc_run)
system(gdal_calc_run)

# visualize
plot(rast(evi_mean))
plot(rast(evi_sd))

## sd has some outliers, lets exclude some pixels to visualize it better
r_sd2 = rast(evi_sd)
r_sd2[r_sd2 > quantile(values(r_sd2), prob = 0.95, na.rm = T)] = NA
plot(r_sd2)
## ok now we can see something, oks




# @@@ 3- Anomaly with gdal_calc ----------------------------------------------------------------

# anomaly (z-score) = (EVI - mean) / sd, calculated for the 17 years at once
## --allBands=A repeats the calculation for every band of A, while B (mean) and C (sd) have one band
## numpy.where keeps only the pixels with data (A > -1e300) and sd > 0, the rest becomes nodata (-9999)
evi_anomaly = file.path(project_dir, "MAIAC_Amazonia_EVI_August_anomalies.tif")
gdal_calc_run = paste(gdal_calc,
                      "--calc \"numpy.where((A > -1e300) & (C > 0), (A - B) / C, -9999)\"",
                      "-A", shQuote(evi_data), "--allBands=A",
                      "-B", shQuote(evi_mean),
                      "-C", shQuote(evi_sd),
                      "--NoDataValue=-9999",
                      "--format GTiff --type Float32",
                      "--co COMPRESS=DEFLATE",
                      "--overwrite",
                      "--outfile", shQuote(evi_anomaly)
)
print(gdal_calc_run)
system(gdal_calc_run)
# plot(rast(evi_anomaly)[[1]])

## Visualize in QGIS, the anomaly has 17 bands, one per year




# @@@ 4- Plot anomalies 2005, 2010, 2015, 2016 ----------------------------------------------------------------

# load anomalies and the states perimeter
r_anom = rast(evi_anomaly)
EST = vect(states)

# Confidence intervals were established as follows (Lee &Wong, 2001)
#P =  0.1 z-score <= -1.65 ; z-score >= 1.65
#P = 0.05 z-score <= -1.96 ; z-score >= 1.96
#P = 0.01 z-score <= -2.57 ; z-score >= 2.57
myBreaks = c(-4, -2.57, -1.96, -1.65, 1.65, 1.96, 2.57, 4)

# function to plot the anomalies of one year
plot_anomalies = function(x, year) {
  i = year - 1999 # band of the year
  r_anom_class = clamp(x[[i]], -4, 4)
  myColours = RColorBrewer::brewer.pal(7, "Spectral"); myColours[4] = "white"
  plot(r_anom_class, breaks = myBreaks, col = myColours, main = year, maxcell = ncell(r_anom_class))
  lines(EST)
}

# plot the drought years, from 2000-2016
plot_anomalies(r_anom, year = 2005)
## Does the 2005 and 2010 drought reproduce the expected impacts of the 2005 and 2010 droughts?
## exercise : plot the other drought years 2010, 2015 and 2016, and one normal year
## exercise : extract the 2010 anomaly to a new file with gdal_translate -b and open it in QGIS




# Summary -----------------------------------------------------------------

## This was an example showing how to calculate anomalies
## it can be used for many different variables, from VIs, climate variables, Fire, etc
## simple and powerful method used in many studies !

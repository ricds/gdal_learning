# gdal_class

# GDAL class for disturbance mapping using satellite monitoring data 
# Ricardo Dalagnol da Silva (ricds@hotmail.com)
# www.github.com/ricds/gdal_class/

Scripts
- gdal_class.R : this is the main script of the class
- gdal_class_initial_data_prep.R : this was for internal usage to create the initial test data - do not run this

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
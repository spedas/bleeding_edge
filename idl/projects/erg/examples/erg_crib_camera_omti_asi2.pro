;+
; PROCEDURE: ERG_CRIB_CAMERA_OMTI_ASI
;    A sample crib sheet that explains how to analyze OMTI cdf data. 
;    You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run erg_crib_camera_omti_asi
;
; NOTE: See the rules of the road.
;       For more information, see:
;       https://stdb2.isee.nagoya-u.ac.jp/omti/
; Written by: A. Shinbori, August 15, 2022
;             Institute for Space-Earth Environmental Research, Nagoya University.
;             shinbori at isee.nagoya-u.ac.jp
;-

;---Initialize
thm_init

;---Set the date and period (in hour)
timespan, '2001-11-12/15:00', /h, 1

;---Load OMTI cdf data at the Sata station. The wavelengths are 630, and 572.5 nm.
erg_load_camera_omti_asi, site = 'sta', wavelength= [6300, 5725]

;---View the loaded tplot names
tplot_names

;---Convert the count data into the absolute data
tabsint, site = 'sta', wavelength= [6300, 5725]

;---Create the map table in geographic coordinates
;For degree unit
tmake_map_table, 'omti_asi_sta_6300_image_abs', mapping_alt = 250, grid = 0.02, mapsize = 512
;For km unit
;tmake_map_table, 'omti_asi_sta_6300_image_abs', mapping_alt = 250, grid = 1, mapsize = 512, /in_km

;---Create the image data at a mapping altitude of 250 km in geographic coordinates
tasi2gmap, 'omti_asi_sta_6300_image_abs', 'omti_asi_sta_6300_gmap_table_250'

;---Plot the raw image data and make png:
plot_omti_image, 'omti_asi_sta_6300_image_raw', time = '2001-11-12/15:33:03', z_min = 0, z_max = 4500
makepng, 'plot_image_raw_ex'
stop

;---Plot the absolute image data and make png:
plot_omti_image, 'omti_asi_sta_6300_image_abs', time = '2001-11-12/15:33:03', z_min = 0, z_max = 1000
makepng, 'plot_image_abs_ex'
stop

;---Plot the two-dimensional map of absolute image data and make png:
plot_omti_gmap, 'omti_asi_sta_6300_image_abs_gmap_250', time = '2001-11-12/15:33:03', z_min = 0, z_max = 1000
makepng, 'plot_gmap_abs_ex'
stop

;---Calculate normaized deviation from 1-hour running average
tmake_image_dev, 'omti_asi_sta_6300_image_abs'
tasi2gmap, 'omti_asi_sta_6300_image_abs_dev', 'omti_asi_sta_6300_gmap_table_250'
plot_omti_gmap, 'omti_asi_sta_6300_image_abs_dev_gmap_250', time = '2001-11-12/15:33:03', z_min = -0.3, z_max = 0.3
makepng, 'plot_gmap_abs_dev_ex'
stop

;---Create tplot variables for keogram plots at specified latitude and longitude and plot the data:
;---In this case, geographic latitude and longitude are 30 and 131 degrees, respectively.
keogram_image, 'omti_asi_sta_6300_image_abs_dev_gmap_250', lat = 30, lon = 131
zlim, ['omti_asi_sta_6300_image_abs_dev_gmap_250_keogram_lon_131','omti_asi_sta_6300_image_abs_dev_gmap_250_keogram_lat_30'], -1, 1
tplot, ['omti_asi_sta_6300_image_abs_dev_gmap_250_keogram_lon_131','omti_asi_sta_6300_image_abs_dev_gmap_250_keogram_lat_30']
makepng, 'plot_gmap_abs_dev_keogram_ex'
stop

end
;+
; PROGRAM: iug_crib_gps_isee
;   This is an example crib sheet that will load GPS-TEC data.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run iug_crib_gps_isee
;
; NOTE: See the rules of the road.
;       For more information, see https://stdb2.isee.nagoya-u.ac.jp/GPS/GPS-TEC/index.html
;
; Written by: A. Shinbori, Oct 6, 2021
;             DIMR, ISEE, Nagoya Univ.
;
;   $LastChangedBy: $
;   $LastChangedDate:  $
;   $LastChangedRevision:  $
;   $URL:  $
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2017-09-08'

; Load the data
iug_load_gps_isee, datatype = 'atec'

; Create tplot variables for keogram plots at the geographical longitudes of 130.0, 135.0 and 140.0 [deg].:
; If the glong is not set, this procedure will create a keogram data along the geographical longitude of 0.0 [deg]. 
atec_keogram_glat_glong, glong = [130.0,135.0,140.0]

; View the loaded data names
tplot_names

; Create a latitude-time plot (keogram) at a specific longitude:
tplot, ['atec_keogram_geocoord_130.0', 'atec_keogram_geocoord_135.0','atec_keogram_geocoord_140.0']
stop

; Create a two-dimensional map at a specific time:
atec_global_2dmap, 'iug_gps_atec', st_time = '2017-09-08/01:00:00'

end

;+
; PROCEDURE: iug_crib_map2d
;    A sample crib sheet that explains how to plot 2D data on the 
;    world map. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_map2d
;
; Written by: Y.-M. Tanaka, Aug. 1, 2014
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in hours)
timespan,'2014-2-16/20',/hour, 1

; Load NIPR ASI data
iug_load_asi_nipr,site='hus'

; View the loaded data names
tplot_names

; Initialize map2d parameters
map2d_init, set_time=2030  ; map2d_time, 2030

; Get the 2D data
get_data_asi_nipr, 'nipr_asi_hus_0000', data=d

; Check structure for the 2D data
help, d, /str

; Create a new window 
window, 1, xsize=600, ysize=600 & erase

; Draw map
map2d_set, glatc=65., glonc=-25., scale=20e+6, /label, charsize=1.5

; Overlay ASI images on the map
overlay_map_asi_nipr, 'nipr_asi_hus_0000', cscharsize=1.5, tlcharsize=3.0

; Overlay coast
overlay_map_coast, /geo_plot

; Stop
stop



; Change to AACGM
map2d_init, coord='aacgm'  ; map2d_coord, 'aacgm'

; Create a new window 
window, 1, xsize=600, ysize=600 & erase

; Draw map
map2d_set, glatc=65., glonc=-25., scale=20e+6, /mltlabel, charsize=2.0

; Overlay ASI images on the map.
; If the DLM for AACGM is not used, it may take long time for calculation.
overlay_map_asi_nipr, 'nipr_asi_hus_0000', cscharsize=1.5, tlcharsize=3.0

; Overlay coast
overlay_map_coast

end

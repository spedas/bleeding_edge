;+
;PROCEDURE: erg_crib_superdarn
; 
; :DESCRIPTION:
;    A crib sheet to demonstrate how procedures/functions for 
;    SuperDARN data work.
;
;    You can run this crib sheet by copying&pasting each command 
;    below into the IDL command line. 
;
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;   
; :HISTORY:
;    2011/01/11: Added commands for 2-D map plotting
;    2010/06/24: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-


;Initialize 
thm_init 

;Set the date and time for loading data
timespan, '2007-06-21', 1, /day 

;Load the data with the position table
erg_load_sdfit, site='hok', /get_support 

;List the loaded data names
tplot_names

;Plot data containing all beams
window, 0, xsize=600, ysize=750
tplot, ['sd_hok_pwr_1', 'sd_hok_vlos_iscat_1', 'sd_hok_spec_width_1']

;Change the time range of the plot
tlimit, ['2007-06-21/13:00','2007-06-21/15:00']

;With the L-O-S Doppler velocity data for both ionospheric echoes 
;and ground scatter  
loadct_sd, 44    ;Use Cutlass color table
tplot, ['sd_hok_pwr_1', 'sd_hok_vlos_bothscat_1', 'sd_hok_spec_width_1']


;Divide the data into those for separate beams
splitbeam, ['sd_hok_pwr_1', 'sd_hok_vlos_bothscat_1', 'sd_hok_spec_width_1']

;Plot data for a specific beam
tplot, ['sd_hok_pwr_1_azim04', 'sd_hok_vlos_bothscat_1_azim04', $
        'sd_hok_spec_width_1_azim04']

;Plot the northward and eastward components in the geographical coordinates 
;of the line-of-sight Doppler velocity 
splitbeam, ['sd_hok_vnorth_bothscat_1','sd_hok_veast_bothscat_1']
tplot, ['sd_hok_vnorth_bothscat_1_azim04','sd_hok_veast_bothscat_1_azim04']

;Plot some parameters relating to the radar operation
timespan, '2007-06-21', 1, /day    ;again set the time range to be 1 day
erg_load_sdfit, site='hok', /get_support_data  ;Load data with the supporting data
splitbeam, 'sd_hok_elev_angle_1'
ylim, 'sd_hok_noise_1', 0,0, 1  ;auto range with log scale
tplot, 'sd_hok_'+['elev_angle_1_azim04','scanno_1','smsep_1',$
	'tfreq_1','noise_1', 'num_ave_1']


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Commands for 2-dimensional plotting on the ground map 

;Create a new window 
window, 1, xsize=600, ysize=600 & erase

;Initialize some system variables for 2-D plotting
sd_init

;Set the time for 2-D plotting
sd_time, 1340

;Define the lat-lon grid and set the center of plot panel 
;to the designated position and draw the MLT labels
sd_map_set, /mltlabel, $
center_glat=70,center_glon=170

;Superpose a 2-D fan plot of SD on the AACGM grid
overlay_map_sdfit,'sd_hok_vlos_bothscat_1'

;Plot only the ionospheric echoes. Please note that sd_map_set 
;is run with "erase" keyword to clear the plot window. 
sd_map_set, /erase, /clip, /mltlabel, $
center_glat=70,center_glon=170
overlay_map_sdfit,'sd_hok_vlos_iscat_1'

;Superpose the world map in AACGM
overlay_map_coast

;An exmaple of plotting THM ASI and SD on the same map
;CAUTION!!!
;Loading THM ASI data might take a long time.

;Load SD data
timespan, '2008-04-03'
erg_load_sdfit, site='hok',/get_support

;Generate a ASI mosaic plot
thm_asi_create_mosaic, '2008-04-03/11:51:00', $
central_lat=70,central_lon=170,/thumb

;Superpose SD data in geographical coords after restoring 
;the Cutlass color table
loadct_sd, 44
sd_time, 1151
overlay_map_sdfit,'sd_hok_vlos_iscat_1', /geo_plot
overlay_map_coast, /geo_plot  ;redraw the coast lines


end


;+
; NAME: crib_tplot_panel_labels
; 
; PURPOSE:  Crib to show how to apply lables inside ptlot panels
;           You can run this crib by typing:
;           IDL>.run crib_tplot_panel_labels
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

;---------------------------------------------------------------------------------------------------
; Set Up 
;---------------------------------------------------------------------------------------------------

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;set a time and load some data.
timespan,'2025-01-25'

;loading THEMIS ESA L2 data
thm_load_esa, probe = 'e'

;set new color scheme (for aesthetics)
init_crib_colors

;---------------------------------------------------------------------------------------------------
; Plot Variables
;---------------------------------------------------------------------------------------------------


print, " "
print, "You have loaded THEMIS E L2 ESA data, Plot some:"
print, " "
print, "IDL Command: "
print, "tplot, ['the_peer_sc_pot', 'the_pe?f_en_eflux', 'the_pe?f_velocity_dsl']"
print, " "

tplot, ['the_peer_sc_pot', 'the_pe?f_en_eflux', 'the_pe?f_velocity_dsl']
print, 'Type ".c" to continue'
stop

print, " "
print, "Set some panel_labels, using tplot_panel_label: "
print, "CALLING SEQUENCE: tplot_panel_label, tplot_variable, x, y"
print, " "
print, "X and Y positions are relative to the panel window for that variable."
print, "/data_coordinates are also an option, but be aware that the x position input must be in "
print, "seconds from the start of the tplot, making tlimit calls problematic"
print, " "
print, "IDL Commands: "
print, " "
print, "tplot_panel_label, 'the_peef_velocity_dsl', 'PEEF_V', 0.5, 0.90"
print, "tplot_panel_label, 'the_peif_velocity_dsl', 'PEIF_V', time_double('2025-01-25/09:00')-time_double('2025-01-25'),40.0, /data_coordinates"
print, "tplot, 'the_pe?f_velocity_dsl"
print, " "

tplot_panel_label, 'the_peef_velocity_dsl', 'PEEF_V', 0.5, 0.90
tplot_panel_label, 'the_peif_velocity_dsl', 'PEIF_V', time_double('2025-01-25/09:00')-time_double('2025-01-25'),40.0, /data_coordinates
tplot, 'the_pe?f_velocity_dsl'
print, 'Type ".c" to continue'
stop

print, " "
print, "Try a keyword option, options are /upper_right (default if no x, y are passed in), "
print, "/upper_left, /Lower_right, /lower_left, /upper_middle, /lower_middle"
print, " "
print, "IDL Commands: "
print, " "
print, "tplot_panel_label, 'the_peif_en_eflux', 'THE_PEIF', /upper_right"
print, "tplot_panel_label, 'the_peef_en_eflux', 'THE_PEEF', /lower_right"
print, "tplot, 'the_pe?f_en_eflux'"
print, " "

tplot_panel_label, 'the_peif_en_eflux', 'THE_PEIF', /upper_right
tplot_panel_label, 'the_peef_en_eflux', 'THE_PEEF', /lower_right
tplot, 'the_pe?f_en_eflux'
print, 'Type ".c" to continue'
stop

print, " "
print, "Color and charsize are also options:"
print, " "
Print, "IDL Commands: "
print, " "
print, "tplot_panel_label, 'the_peer_sc_pot', 'THE_SCPOT', /upper_right, color = 6, charsize = 2"
print, "tplot, 'the_peer_sc_pot'"
print, " "

tplot_panel_label, 'the_peer_sc_pot', 'THE_SCPOT', /upper_right, color = 6, charsize = 2
tplot, 'the_peer_sc_pot'
print, 'Type ".c" to continue'
stop

print, " "
print, "Oops, that label doesn't fit, move it to lower_middle. TPLOT_PANEL_LABEL will overwrite"
print, " "
Print, "IDL Commands: "
print, " "
print, "tplot_panel_label, 'the_peer_sc_pot', 'THE_SCPOT', /lower_middle, color = 6, charsize = 2"
print, "tplot, 'the_peer_sc_pot'"
print, " "

tplot_panel_label, 'the_peer_sc_pot', 'THE_SCPOT', /lower_middle, color = 6, charsize = 2
tplot, 'the_peer_sc_pot'
stop
print, 'Type ".c" to continue'

print, " "
print, "To Remove a label, usse the /remove_label option"
print, " "
Print, "IDL Commands: "
print, " "
print, "tplot_panel_label, 'the_peer_sc_pot', /remove_label"
print, "tplot, 'the_peer_sc_pot'"
print, " "

tplot_panel_label, 'the_peer_sc_pot', /remove_label
tplot, 'the_peer_sc_pot'
print, "Done, feel free to experiment with the panel labels. "


End

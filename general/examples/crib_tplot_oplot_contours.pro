;+
; NAME: crib_oplot_contours
; 
; PURPOSE:  Crib to demonstrate overplotting contours on a tplot
; spectrogram, using THEMIS ESA data
;           You can run this crib by typing:
;           IDL>.run crib_oplot_contours
;           IDL>.go
;           
;           When you reach a stop, press
;           IDL>.c
;           to continue
;           
;           Or you can copy and paste commands directly onto the command line
;
; SEE ALSO: crib_tplot  (basic tplot commands)
; NOTES:
;   If you see any useful commands missing from these cribs, please let us know.
;   these cribs can help double as documentation for tplot.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-01-25 11:34:48 -0800 (Wed, 25 Jan 2023) $
; $LastChangedRevision: 31426 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot_oplot_contours.pro $
;-

;this line deletes data so we start the crib fresh
store_data,'*',/delete

;first we set a time and load some data.
timespan,'2021-03-24'

;load data
thm_load_esa, level = 'l2', probe = 'a'

;plot spectral data, add default contours, using 'options'
options, 'tha_peif_en_eflux', 'overplot_contour', 1
tplot, 'tha_peif_en_eflux'
print, 'Default contour options'

stop
;change contour options, any keywrd that can be passed into contour
;can be set up using options
options, 'tha_peif_en_eflux', 'contour_options', {c_thick:2, c_color:6}
tplot
print, 'Changed contour color and thickness'
stop

;Change levels, and use a different color for each level
options, 'tha_peif_en_eflux', 'contour_options', $
         {levels: [1e3, 1e4, 1e5, 1e6], c_color: [2, 4, 6, 8], c_thick:2}
tplot
print, 'Changed contour levels and colors'
stop

;Use nlevels to use equally spaced levels
options, 'tha_peif_en_eflux', 'contour_options', $
         {nlevels:4, c_thick:2}
tplot
print, 'Used nlevels for equally spaced levels (in logs - since log plotting was set by default on input)'
stop

;Contours work with burst data too, but degapping should be done
tdegap, 'tha_peib_en_eflux', gap_dt = 600, /overwrite
options, 'tha_peib_en_eflux', 'overplot_contour', 1
options, 'tha_peib_en_eflux', 'contour_options', $
         {nlevels:4, c_thick:2, c_color:6}
tplot, 'tha_peib_en_eflux'
print, 'Contours over burst mode data, 4 levels, red, Use tlimit to isolate bursts'

tlimit, '2021-03-24/05:00', '2021-03-24/07:00'

print, 'Note that any contour plot keyword can be set, but not all have been exhaustively tested'


End

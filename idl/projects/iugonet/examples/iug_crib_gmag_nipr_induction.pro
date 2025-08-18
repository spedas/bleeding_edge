;+
; PROCEDURE: IUG_CRIB_GMAG_NIPR_INDUCTION
;    A sample crib sheet that explains how to use the  
;    "iug_load_gmag_nipr_induction" procedure. You can run this crib sheet 
;    by copying & pasting each command below (except for stop and end)
;    into the IDL command line. Or alternatively compile and run using
;    the command:
;        .run iug_crib_gmag_nipr_induction
;
; NOTE: See the rules of the road.
;       For more information, see:
;       http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=103
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=115
; Written by: Y.-M. Tanaka, May 2, 2011
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2006-04-17'

; Load NIPR data
iug_load_gmag_nipr_induction,site='syo'

; View the loaded data names
tplot_names

; Plot the loaded data
tplot, 'nipr_imag_syo_20hz'

; Stop
print,'Enter ".c" to continue.'
stop

; Split vector
split_vec, 'nipr_imag_syo_20hz'

; Calculate power spectrum
tdpwrspc, 'nipr_imag_syo_20hz_x', nboxpoints=8192

; Plot
tplot, 'nipr_imag_syo_20hz_x_dpwrspc'

; Set title
;tplot_options, 'title', 'Sample plot of NIPR magnetometer data'

; Plot
;tplot

end

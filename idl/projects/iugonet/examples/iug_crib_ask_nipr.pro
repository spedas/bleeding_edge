;+
; PROCEDURE: IUG_CRIB_ASK_NIPR
;    A sample crib sheet that explains how to use the "iug_load_ask_nipr" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_ask_nipr
;
; NOTE: See the rules of the road.
;       For more information, see:
;       http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=101
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=114
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=115
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=224
; Written by: Y.-M. Tanaka, October 10, 2014
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2012-01-22'

; Load NIPR data
iug_load_ask_nipr,site='tro', wavelength='0000'

; View the loaded data names
tplot_names

; Plot the loaded data
tplot, ['nipr_ask_tro_0000_ns', 'nipr_ask_ew_tro_0000_ew']

; Stop
print,'Enter ".c" to continue.'
stop

; Set new timespan
timespan,'2012-01-22/18:00:00',6,/hours

; Set title
; tplot_options, 'title', 'Sample plot of NIPR all-sky imager data'

; Plot
tplot

end

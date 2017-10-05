;+
; PROCEDURE: ERG_CRIB_GMAG_NIPR
;    A sample crib sheet that explains how to use the "erg_load_gmag_nipr" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_gmag_nipr
;
; NOTE: See the rules of the road.
;       For more information, see:
;       http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=102
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=103
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=115
;
; Written by: Y.-M. Tanaka, Feb. 18, 2011
;             National Institute of Polar Research, Japan.
;             email: ytanaka at nipr.ac.jp
; Last Updated:  Y.-M. Tanaka,  Aug 29, 2011
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2003-10-29'

; Load NIPR data
erg_load_gmag_nipr,site=['syo','hus','tjo']

; View the loaded data names
tplot_names

; Plot the loaded data
tplot,'nipr_mag_*'

stop

; Set new timespan
timespan,'2003-10-29/06:00:00',4,/hours

; Set y-axis
ylim,'nipr_mag_*',-4000,2000

; Plot
tplot

end

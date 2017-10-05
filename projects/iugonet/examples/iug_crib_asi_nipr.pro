;+
; PROCEDURE: IUG_CRIB_ASI_NIPR
;    A sample crib sheet that explains how to use the "iug_load_asi_nipr" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_asi_nipr
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

; Set the date and duration (in minute)
timespan, '2012-01-22/20:30', /min, 30

; Load NIPR data
iug_load_asi_nipr,site='hus', wavelength='0000'

; View the loaded data names
tplot_names

; Plot the loaded data
tplot, 'nipr_asi_hus_0000'

; Stop
print,'Enter ".c" to continue.'
stop

; Show 2D image
window,1,xsize=480,ysize=480
ctime,/cut


end

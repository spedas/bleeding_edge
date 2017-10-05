;+
; PROCEDURE: IUG_CRIB_IRIO_NIPR
;    A sample crib sheet that explains how to use the "iug_load_irio_nipr" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_irio_nipr
;
; NOTE: See the rules of the road.
;       For more information, see:
;       http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=104
;    &  http://scidbase.nipr.ac.jp/modules/metadata/index.php?content_id=115
; Written by: Y.-M. Tanaka, May 2, 2011
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2003-02-09'

; Load IRIO data
iug_load_irio_nipr, site='syo', /keogram

; View the loaded data names
tplot_names

; Plot the loaded data
tplot, ['nipr_irio30_syo_cna_N3E0-7', 'nipr_irio30_syo_cna_N0-7E3']

; Stop
print,'Enter ".c" to continue.'
stop

; Plot 2D image of CNA
iug_plot2d_irio, 'nipr_irio30_syo_cna', 2, 2, start_time='2003-02-09/01:30', $
   step=60, /flipns, /oblique_cor

end

;+
;PROCEDURE: IUG_CRIB_METEOR_NIPR.PRO
;    A sample crib sheet that explains how to use the "iug_crib_meteor_nipr.pro" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_meteor_nipr
;
;Written by: Y.-M. Tanaka, Aug. 2, 2012
;-

; Initializes system variables for themis:
thm_init

; Specify timespan:
timespan,'2009-1-1', 59

; Load data
iug_load_meteor_nipr

; Show loaded data
tplot_names

; Plot
tplot, ['iug_meteor_tro_uwnd', 'iug_meteor_tro_vwnd']

stop

; Change tlimit
tlimit, '2009-1-15', '2009-2-3'

end

;+
; PROCEDURE: IUG_CRIB_SMART
;    A sample crib sheet that explains how to use the "iug_load_smart" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_smart
;
; :Author:
;    Y.-M. Tanaka (E-mail: ytanaka at nipr.ac.jp)
;    Satoru UeNo (E-mail: ueno@kwasan.kyoto-u.ac.jp)
;-

; Initialize
thm_init

; Set the date and duration
timespan, '2005-08-03/05:00', 6, /minute

; Load SMART solar images
iug_load_smart,filter='p00'
iug_load_smart,filter='m08'

; View the loaded data names
tplot_names

; Plot the loaded images
iug_plot2d_smart,'smart_t1_p00',3,3

; Stop
;print,'Enter ".c" to continue.'
;stop

; Show movie
;iug_movie_smart,'smart_t1_m08'

end

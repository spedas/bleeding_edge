;+
; PROCEDURE: IUG_CRIB_EISCAT_VIEF
;    A sample crib sheet that explains how to use the "iug_load_eiscat_vief" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_eiscat_vief
;
; NOTE: See the rules of the road.
;       For more information, see:
;           http://polaris.nipr.ac.jp/~eiscat/eiscatdata/
; Written by: Y.-M. Tanaka, August 16, 2013
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2011-2-4', 4

; Load vector ion velocity and electric field observed by EISCAT
iug_load_eiscat_vief, site='kst'

; View the loaded data names
tplot_names

; Plot the loaded Vi and E
tplot, ['eiscat_kst_vi', 'eiscat_kst_vierr', 'eiscat_kst_E', 'eiscat_kst_Eerr']

; Stop
print,'Enter ".c" to continue.'
stop

; Set new timespan
tlimit,'2011-2-4/14:00','2011-2-5/8:00'

; Plot
tplot

; Stop
print,'Enter ".c" to continue.'
stop

; Load vector ion velocity and electric field observed by EISCAT
; with support data.
iug_load_eiscat_vief, site='kst', /get_support_data

; Plot the other data
tplot, ['eiscat_kst_pulse', 'eiscat_kst_inttim', 'eiscat_kst_inttimr', $
        'eiscat_kst_lat', 'eiscat_kst_long', 'eiscat_kst_alt', 'eiscat_kst_q']

end


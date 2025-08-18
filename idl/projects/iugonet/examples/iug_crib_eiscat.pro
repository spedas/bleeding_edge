;+
; PROCEDURE: IUG_CRIB_EISCAT
;    A sample crib sheet that explains how to use the "iug_load_eiscat" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_eiscat
;
; NOTE: See the rules of the road.
;       For more information, see:
;           http://polaris.nipr.ac.jp/~eiscat/eiscatdata/
; Written by: Y.-M. Tanaka, July 26, 2011
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
; Modified by: Y.-M. Tanaka, December 1, 2011
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2010-1-18',3

; Load the ESR-42m radar data
iug_load_eiscat, site='esr_42m'

; View the loaded data
tplot_names

; Plot Ne, Te, Ti, Vi for ESR-42m radar
tplot,['eiscat_esr42m_ne','eiscat_esr42m_te',$
       'eiscat_esr42m_ti','eiscat_esr42m_vi']


; Stop
print,'Enter ".c" to continue.'
stop

; Load data observed at all sites
iug_load_eiscat

; View the loaded data
tplot_names

; Set title
; tplot_options, 'title', 'Sample plot of EISCAT radar data'

; Plot Ne for all sites
tplot, 'eiscat_*_ne'

end

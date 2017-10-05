;+
;PROCEDURE: IUG_CRIB_LFRTO
;    A crib sheet to demonstrate how to deal with data from
;    Low Frequency Radio Transmitter Observation (LFRTO) using udas.
;    You can run this crib sheet by copying&pasting each command
;    below into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_lfrto
;
; Written by: M. Yagi, Jan 20, 2013 
; Last Update: M. Yagi, Jan 20, 2013
;-

;Initialize
thm_init 

;Specify the time span.
timespan, '2010-05-29/04:00:00',9,/hour

;Load LFRTO data
iug_load_lfrto,site='nal',trans='msf'

; View the loaded data names
tplot_names

; Plot the loaded data
xlim,'lfrto_nal_msf_pha30s',-180,180
tplot,['lfrto_nal_msf_pow30s','lfrto_nal_msf_pha30s']

; Stop
print,'Enter ".c" to continue.'
stop

; Plot the loaded data with 'trange' option
tplot,['lfrto_nal_msf_pow30s','lfrto_nal_msf_pha30s'],trange=['2010-05-29/07:00:00','2010-05-29/10:00:00']

end

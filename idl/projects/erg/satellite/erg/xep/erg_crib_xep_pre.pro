;+
; PROGRAM: erg_crib_xep_pre
;   This is an example crib sheet that will load Provisonal XEP data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_xep_pre
;
; NOTE: See the rules of the road.
;      
;
; Written by: M. Teramoto, August 25, 2017
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
;   $LastChangedRevision: 29823 $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-04-01'

; load Provisonal XEP data
erg_load_xep_pre
;and please enter uname and passwd

; view the loaded data names
tplot_names

;Change the COUNT range
zlim,'erg_xepe_pre_COUNT',1e-1,1e4

; Plot E-t diagram
tplot,['erg_xep_pre_COUNT']


; Change line plot
options,'erg_xep_pre_COUNT',spec=0,ytitle='COUNT [count/s]'
;Change the COUNT range
ylim,'erg_xep_pre_COUNT',1e-1,1e4
tplot,['erg_xep_pre_COUNT']

end
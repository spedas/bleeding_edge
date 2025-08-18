;+
; PROGRAM: erg_crib_xep
;   This is an example crib sheet that will load XEP L2 data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_xep
;
; NOTE: See the rules of the road.
;      
;
; Written by: M. Teramoto, September 01, 2018
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-06-01'

; load L2 XEP data
erg_load_xep
;and please enter uname and passwd

; view the loaded data names
tplot_names

;Change the OMNI flux range
zlim,'erg_xep_l2_FEDO_SSD',1e-1,1e4

; Plot E-t diagram
tplot,['erg_xep_l2_FEDO_SSD']


; Change line plot
options,'erg_xep_l2_FEDO_SSD',spec=0,ytitle='[/cm2-str-s-keV]'


;Change the Flux range
ylim,'erg_xep_l2_FEDO_SSD',1e-1,1e4
tplot,['erg_xep_l2_FEDO_SSD']

end

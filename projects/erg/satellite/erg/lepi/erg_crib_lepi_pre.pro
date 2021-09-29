;+
; PROGRAM: erg_crib_lepi_pre
;   This is an example crib sheet that will load Provisonal LEPI data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;     .run erg_crib_lepi_pre
;
; NOTE: See the rules of the road.
;      
;
; Written by: Y. Miyoshi, July 07, 2017
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
;   $LastChangedRevision: 29823 $
;-

; initialize
erg_init

; set the date and duration (in days)
timespan, '2017-05-01'

; load Provisonal LEP-i data
erg_load_lepi_pre
;and please enter uname and passwd

; view the loaded data names
tplot_names

; Plot E-t diagram
tplot,['erg_lepi_pre_FPDO']

;Change the COUNT range
zlim,'erg_lepi_pre_FPDO',1.0,1.e4


end


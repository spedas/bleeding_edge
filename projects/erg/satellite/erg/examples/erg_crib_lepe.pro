;+
; PROGRAM: erg_crib_lepe
;   This is an example crib sheet that will load LEP-e L2 omniflux data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;   IDL> .run erg_crib_lepe
;
; NOTE: See the rules of the road.
;
; Written by: Tzu-Fang Chang, Aug. 28, 2018
;             ERG Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; Initialize the user environmental variables for ERG
erg_init

; set the date and duration (in days)
timespan, '2017-04-04'

; load LEP-e L2 omniflux data
erg_load_lepe

; view the loaded data names
tplot_names

; Plot E-t diagram
tplot,['erg_lepe_l2_omniflux_FEDO']

end


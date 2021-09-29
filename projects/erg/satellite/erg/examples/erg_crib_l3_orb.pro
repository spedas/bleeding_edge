;+
; PROGRAM: erg_crib_l3_orb
;   This is an example crib sheet that will load orbit L3 data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;   IDL> .run erg_crib_l3_orb
;
; NOTE: See the rules of the road.
;
; Update:
; 2020-12-11: updated crib sheet to load ERG orbit l3 data for OP77Q, T89, and TS04 model
;
; Written by: Tzu-Fang Chang, Aug. 28, 2018
;             ERG Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2021-03-25 13:25:21 -0700 (Thu, 25 Mar 2021) $
;   $LastChangedRevision: 29822 $
;-

; Initialize the user environmental variables for ERG
erg_init

; set the date and duration (in days)
timespan, '2017-04-04'

; load ERG orbit L3 data
; 1) using OP77Q model
erg_load_orb_l3; or add a keyword (model='op')

; view the loaded data names
tplot_names

; Plot Spacecraft positions mapped onto the magnetic equator &
; Magnetic filed at spacecraft position
tplot,['erg_orb_l3_pos_eq_op','erg_orb_l3_pos_blocal_op']

; Plot McIlwain L (Lm) parameter for different pitch angles &
; Roederer L (L-star) parameter for different pitch angles
tplot,['erg_orb_l3_pos_lmc_op','erg_orb_l3_pos_lstar_op']
stop

; 2) using T89 model
erg_load_orb_l3, model='t89'

; view the loaded data names
tplot_names

; Plot Spacecraft positions mapped onto the magnetic equator &
; Magnetic filed at spacecraft position
tplot,['erg_orb_l3_pos_eq_t89','erg_orb_l3_pos_blocal_t89']

; Plot McIlwain L (Lm) parameter for different pitch angles &
; Roederer L (L-star) parameter for different pitch angles
tplot,['erg_orb_l3_pos_lmc_t89','erg_orb_l3_pos_lstar_t89']
stop

; 3) using TS04 model
erg_load_orb_l3, model='ts04'

; view the loaded data names
tplot_names

; Plot Spacecraft positions mapped onto the magnetic equator &
; Magnetic filed at spacecraft position
tplot,['erg_orb_l3_pos_eq_TS04','erg_orb_l3_pos_blocal_TS04']

; Plot McIlwain L (Lm) parameter for different pitch angles &
; Roederer L (L-star) parameter for different pitch angles
tplot,['erg_orb_l3_pos_lmc_TS04','erg_orb_l3_pos_lstar_TS04']
stop

end


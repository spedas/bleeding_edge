;+
; PROGRAM: erg_crib_pwe
;   This is an example crib sheet that will load PWE data of the ERG satellite.
;   Open this file in a text editor and then use copy and paste to copy
;   selected lines into an idl window.
;   Or alternatively compile and run using the command:
;   IDL> .run erg_crib_pwe
;
; NOTE: See the rules of the road.
;       For more information, see http://ergsc.isee.nagoya-u.ac.jp/
;
; Written by: Yasunori Tsugawa, Aug. 30, 2018
;             ERG Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

; Initialize the user environmental variables for ERG
erg_init

; Set the date and duration
timespan, '2017-04-01'

; Load PWE EFD-E_spin data
erg_load_pwe_efd, datatype='E_spin'

; Load PWE EFD-POT data
erg_load_pwe_efd, datatype='pot'

; Load PWE OFA-SPEC data
erg_load_pwe_ofa, datatype='spec'

; Load PWE HFA-SPEC data (low and monitor modes)
erg_load_pwe_hfa

; View the loaded data names
tplot_names

; Plot examples of PWE data
tplot,['erg_pwe_hfa_l2_lm_spectra_esum','erg_pwe_ofa_spec_l2_E_spectra_merged','erg_pwe_hfa_l2_lm_spectra_bgamma','erg_pwe_ofa_spec_l2_B_spectra_merged','erg_pwe_efd_l2_Eu_dsi','erg_pwe_efd_l2_Vave']

end


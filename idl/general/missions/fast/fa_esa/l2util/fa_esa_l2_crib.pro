;+
;NAME:
;fa_esa_l2_crib
;PURPOSE:
;Crib for loading FAST ESA L2 data
;-

; Set timespan 

	timespan, '1996-11-12'

; Load data

	fa_esa_load_l2

; You can also load by orbit number, 
        
        fa_esa_load_l2, orbit = 900

; Or an orbit range

        fa_esa_load_l2, orbit = [900, 905]

;Variables are in common blocks:

        common fa_ies_l2, get_ind_ies, all_dat_ies
        common fa_ees_l2, get_ind_ees, all_dat_ees
        common fa_ieb_l2, get_ind_ieb, all_dat_ieb
        common fa_eeb_l2, get_ind_eeb, all_dat_eeb

        help, all_dat_ies


; Generate tplot structures; fa_esa_l2_tplot creates an angle averaged
; energy spectrum using the eflux variable for each type, with names
; fa_ies_l2_en_quick, fa_ees_l2_en_quick, fa_ieb_l2_en_quick, fa_eeb_l2_en_quick

	fa_esa_l2_tplot

        tplot, 'fa_*_l2_en_quick'

; If you set the /counts keyword, fa_esa_l2_tplot will generate the
; 'l1' tplot variables, for comparison with the tplot vars created in
; fa_load_esa_l1.pro

	fa_esa_l2_tplot, /counts

        tplot, 'fa_*_l1_en_quick'

; If you don't want all of the data types, use the type keyword:

        fa_esa_load_l2, orbit = 900, type = ['ies', 'ees']

	fa_esa_l2_tplot

        tplot, 'fa_*_l2_en_quick'

; Get a pitch angle distribution, integrated over a single energy
; range, the default is to use all energies:
        get_data, 'fa_ies_l2_en_quick', trange = tr
        ipa_dist = fa_esa_l2_pad('ies', trange = tr)
; Vary the energy range:
        ipa_dist1 = fa_esa_l2_pad('ies', trange = tr, energy = [10.0, 50.0], name = 'fa_ies_1050_pad')
; Get a single energy:
        ipa_dist2 = fa_esa_l2_pad('ies', trange = tr, energy = [11.0, 11.0], name = 'fa_ies_11_pad')
; Or a high energy:
        ipa_dist3 = fa_esa_l2_pad('ies', trange = tr, energy = [2000.0, 2200.0], name = 'fa_ies_20002200_pad') 
; tplot, the pitch angle distributsions:
        tplot, 'fa_ies*pad'

; Energy flux distribution, all pitch angles:
        p1 = fa_esa_l2_edist('ies', trange=tr)

; set a pa_range, around zero:
        p2 = fa_esa_l2_edist('ies', trange=tr, parange = [350.0, 10.0], name = 'fa_ies_35010_edist')

; get a small pa_range
        p3 = fa_esa_l2_edist('ies', trange=tr, parange = [10.0, 12.0], name = 'fa_ies_1012_edist')

; get a small pa at an odd angle
        p4 = fa_esa_l2_edist('ies', trange=tr, parange = [180.0, 182.0], name = 'fa_ies_180182_edist')
        

End

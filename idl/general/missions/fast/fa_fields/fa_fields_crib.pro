;Sample Load using timespan
;timespan, '1996-12-11'
;fa_despun_e_load
;tplot, 'fa_'+['e_along_v', 'e_near_b']
;sample load using orbit
fa_despun_e_load, orbit = 1211

;Load some ESA data
fa_esa_load_l2, orbit = 1211
fa_esa_l2_tplot ;creates '_quick' energy distributions, integrated over angle

;load some B field data
;you need a trange or a timespan
get_data,'fa_sc_pot', data = scp
fa_load_mag_hr_dcb,trange = minmax(scp.x)+[-60.0,60.0]


;load e4k data
fa_despun_e_load, orbit = 1211, datatype = 'e4k'
;oops no file, but 16k works.
fa_despun_e_load, orbit = 1211, datatype = 'e16k'
;DSP data
fa_dsp_load, orbit = 1211
;SFA data
fa_sfa_load, orbit = 1211


tplot, 'fa_'+['e_along_v', 'e_near_b']
tplot, 'fa_sc_pot*'
tplot, ['fa_e_along_v','fa_e_near_b','fa_?eb_l2_en_quick','fa_hr_dcb_B_DSC']


end







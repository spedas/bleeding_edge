;correction and L2-like processing of moments for
;probe = 'a', date = '2010-04-01'

print, 'This crib demonstrates the use of THM_SST_ATT_CORRECT.'
print, 'For more information, see the document README_SST_ATT_CORRECT.pdf'
print, 'in the SST_cal_workdir directory.'

Print, 'First calculate the correction variables, tha_psif_ratio_var and tha_psef_ratio_var'

probe = 'a' & date = '2010-04-01'
thm_sst_att_correct, probe, date, /auto_extend ;auto_extend extends alculation up to plus or minus 7 days to fine transitions
print, 'Plot variables, note that all SST data variables are deleted during this process, except for tha_psif_ratio_var tha_psef_ratio_var. Note extended time range.'

stop

;Plot variables, note that all SST data variables are deleted during this process, except for tha_psif_ratio_var tha_psef_ratio_var. Note extended time range.
tplot, '*_ratio_var'
print, 'Next calculate moments, state, fit, and sc_pot variables are needed, in addition to SST. Note that we use THM_LOAD_SST2. Plot density'

stop

;Next calculate moments, state, fit, and sc_pot variables are needed, in addition to SST. Note that we use THM_LOAD_SST2. Plot density
timespan, date
thm_load_state, probe = probe, /get_support_data
thm_load_fit,probe=probe,coord='dsl'
thm_part_load,probe=probe,datatype='psif'
thm_part_load,probe=probe,datatype='psef'
thm_load_esa_pot,probe=probe 
thm_load_mom, probe = probe, level = 'l1'
print, 'Data is loaded, processing ion moments'
thm_part_products,probe=probe,datatype='psif', $
                  outputs =['energy','moments'],tplotnames=ipsxx_names
tplot, 'tha_psif_density'
print, 'Spikes at attenuator transitions are common. Sanitize PSIF moments using THM_SANITIZE_L2_SST to remove spikes'

stop
;Spikes at attenuator transitions are common. Sanitize PSIF moments using THM_SANITIZE_L2_SST to remove spikes
thm_sanitize_l2_sst, probe, 'psif', ipsxx_names
tplot
print, 'Compare with old L2 density calculation. (this step will go away when we reprocess L2 SST) Note that discontinuities at transitions are missing in new data.'

stop
;Compare with old L2 density calculation. (this step will go away when
;we reprocess L2 SST) Note that discontinuities at transitions are
;missing in new data.
thm_load_sst, probe = probe, level='l2', suffix = 'L2'
options, '*atten', 'labels', ['IN', 'OUT', 'IN', 'OUT']
tplot, 'tha_psif_density tha_psif_densityL2 tha_psif_atten'
print, 'Use tlimit to show a shorter interval. Better corrections are pretty obvious'

stop
;Use tlimit to show a shorter interval. Better corrections are pretty obvious
tlimit, '2010-04-01 04:00', '2010-04-01 12:00'
Print, 'Calculate, sanitize and plot Electron densities,'

stop
;Calculate, sanitize and plot electron densities
thm_part_products,probe=probe,datatype='psef', $
                  outputs =['energy','moments'],tplotnames=epsxx_names
thm_sanitize_l2_sst, probe, 'psef', epsxx_names
tplot, 'tha_psef_density tha_psef_densityL2 tha_psef_atten'
print, 'The new density is not much different than the old density for electrons, only slightly higher for atteunated intervals.'

End






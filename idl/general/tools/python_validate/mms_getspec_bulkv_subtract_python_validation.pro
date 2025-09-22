pro mms_getspec_bulkv_subtract_python_validation 
del_data,'*'
trange = ['2015-11-19/08:34:41', '2015-11-19/08:35:53']
; fac_energy and energy yield the same output variable names, so we'll do the fac version first and rename it out of the way with a 'mag' infix
mms_part_getspec, data_rate='brst', output=['fac_energy'], /no_regrid, trange=trange, species='i', probe=1, /center, units='eflux', suffix='_no_bulk_subtract'
copy_data,'mms1_dis_dist_brst_energy_no_bulk_subtract', 'mms1_dis_dist_brst_energy_mag_no_bulk_subtract'
mms_part_getspec, /subtract_bulk, data_rate='brst', output=['fac_energy'], /no_regrid, trange=trange, species='i', probe=1, /center, units='eflux', suffix='_bulk_subtract'
copy_data,'mms1_dis_dist_brst_energy_bulk_subtract', 'mms1_dis_dist_brst_energy_mag_bulk_subtract'

mms_part_getspec, data_rate='brst', output=['energy', 'theta', 'phi', 'moments'], trange=trange, species='i', probe=1, /center, units='eflux', suffix='_no_bulk_subtract'

; Time range with only two samples for diagnosing moment differences
;short_trange = ['2015-11-19/08:35:13.9','2015-11-19/08:35:14.2']
;mms_part_getspec, data_rate='brst', output=['moments'], trange=short_trange, species='i', probe=1, /center, units='eflux', suffix='_single_no_bulk_subtract'

mms_part_getspec, data_rate='brst', output=['pa', 'gyro', 'fac_moments'], /no_regrid, trange=trange, species='i', probe=1, /center, units='eflux', suffix='_no_bulk_subtract'
mms_part_getspec, /subtract_bulk, data_rate='brst', output=['energy','theta','phi', 'pa', 'gyro', 'moments', 'fac_moments'], trange=trange, species='i', probe=1, /center, units='eflux', suffix='_bulk_subtract'

; fac_energy and energy yield the same output variable names, so do the fac version first and rename
mms_part_getspec, instrument='hpca', data_rate='brst', output=['fac_energy'], /no_regrid, trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_no_bulk_subtract'
copy_data,'mms1_hpca_hplus_phase_space_density_energy_no_bulk_subtract', 'mms1_hpca_hplus_phase_space_density_energy_mag_no_bulk_subtract'
mms_part_getspec, /subtract_bulk, instrument='hpca', data_rate='brst', output=['fac_energy'], /no_regrid, trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_bulk_subtract'
copy_data,'mms1_hpca_hplus_phase_space_density_energy_bulk_subtract', 'mms1_hpca_hplus_phase_space_density_energy_mag_bulk_subtract'

mms_part_getspec, instrument='hpca', data_rate='brst', output=['energy', 'phi', 'theta','moments'], trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_no_bulk_subtract'
mms_part_getspec, /subtract_bulk, instrument='hpca', data_rate='brst', output=['energy', 'phi', 'theta', 'moments'], trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_bulk_subtract'
mms_part_getspec, instrument='hpca', data_rate='brst', output=['pa', 'gyro', 'fac_moments'], /no_regrid, trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_no_bulk_subtract'
mms_part_getspec, /subtract_bulk, instrument='hpca', data_rate='brst', output=['pa','gyro', 'fac_moments'], /no_regrid,trange=trange, species='hplus',probe=1, /center, units='eflux',suffix='_bulk_subtract'
tplot_names,'*hpca*'
testvars=[$
  ; FPI Spectra
  'mms1_dis_dist_brst_energy_no_bulk_subtract','mms1_dis_dist_brst_energy_bulk_subtract',$
  'mms1_dis_dist_brst_energy_mag_no_bulk_subtract','mms1_dis_dist_brst_energy_mag_bulk_subtract',$
  'mms1_dis_dist_brst_phi_no_bulk_subtract','mms1_dis_dist_brst_phi_bulk_subtract',$
  'mms1_dis_dist_brst_theta_no_bulk_subtract','mms1_dis_dist_brst_theta_bulk_subtract',$
  'mms1_dis_dist_brst_pa_no_bulk_subtract','mms1_dis_dist_brst_pa_bulk_subtract',$
  'mms1_dis_dist_brst_gyro_no_bulk_subtract','mms1_dis_dist_brst_gyro_bulk_subtract',$
  
  ; HPCA Spectra
  'mms1_hpca_hplus_phase_space_density_energy_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_energy_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_phi_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_phi_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_theta_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_theta_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_energy_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_energy_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_pa_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_pa_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_gyro_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_gyro_bulk_subtract',$

  ; FPI Moments  
  'mms1_dis_dist_brst_avgtemp_no_bulk_subtract','mms1_dis_dist_brst_avgtemp_bulk_subtract',$
  'mms1_dis_dist_brst_density_no_bulk_subtract','mms1_dis_dist_brst_density_bulk_subtract',$
  'mms1_dis_dist_brst_eflux_no_bulk_subtract','mms1_dis_dist_brst_eflux_bulk_subtract',$
  'mms1_dis_dist_brst_qflux_no_bulk_subtract','mms1_dis_dist_brst_qflux_bulk_subtract',$
  'mms1_dis_dist_brst_flux_no_bulk_subtract','mms1_dis_dist_brst_flux_bulk_subtract',$
  'mms1_dis_dist_brst_mftens_no_bulk_subtract','mms1_dis_dist_brst_mftens_bulk_subtract',$
  'mms1_dis_dist_brst_ptens_no_bulk_subtract','mms1_dis_dist_brst_ptens_bulk_subtract',$
  'mms1_dis_dist_brst_sc_current_no_bulk_subtract','mms1_dis_dist_brst_sc_current_bulk_subtract',$
  'mms1_dis_dist_brst_velocity_no_bulk_subtract','mms1_dis_dist_brst_velocity_bulk_subtract',$
  'mms1_dis_dist_brst_vthermal_no_bulk_subtract','mms1_dis_dist_brst_vthermal_bulk_subtract',$
  'mms1_dis_dist_brst_magf_no_bulk_subtract','mms1_dis_dist_brst_magf_bulk_subtract',$
  'mms1_dis_dist_brst_magt3_no_bulk_subtract','mms1_dis_dist_brst_magt3_bulk_subtract',$
  'mms1_dis_dist_brst_t3_no_bulk_subtract','mms1_dis_dist_brst_t3_bulk_subtract',$
  'mms1_dis_dist_brst_sc_pot_no_bulk_subtract','mms1_dis_dist_brst_sc_pot_bulk_subtract',$
  'mms1_dis_dist_brst_symm_no_bulk_subtract','mms1_dis_dist_brst_symm_bulk_subtract',$
  'mms1_dis_dist_brst_symm_theta_no_bulk_subtract','mms1_dis_dist_brst_symm_theta_bulk_subtract',$
  'mms1_dis_dist_brst_symm_phi_no_bulk_subtract','mms1_dis_dist_brst_symm_phi_bulk_subtract',$
  'mms1_dis_dist_brst_symm_ang_no_bulk_subtract','mms1_dis_dist_brst_symm_ang_bulk_subtract',$
  
  ; FPI moments, single point interval
  ;'mms1_dis_dist_brst_avgtemp_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_density_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_eflux_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_flux_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_mftens_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_ptens_single_no_bulk_subtract',$
  ;;'mms1_dis_dist_brst_sc_current_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_velocity_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_vthermal_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_vthermal_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_magf_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_magt3_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_t3_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_sc_pot_single)no_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_single_theta_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_phi_single_no_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_ang_single_o_bulk_subtract',$


  ; FPI Field-aligned moments 
  'mms1_dis_dist_brst_avgtemp_mag_no_bulk_subtract','mms1_dis_dist_brst_avgtemp_mag_bulk_subtract',$ 
  'mms1_dis_dist_brst_density_mag_no_bulk_subtract','mms1_dis_dist_brst_density_mag_bulk_subtract',$
  'mms1_dis_dist_brst_eflux_mag_no_bulk_subtract','mms1_dis_dist_brst_eflux_mag_bulk_subtract',$
  'mms1_dis_dist_brst_qflux_mag_no_bulk_subtract','mms1_dis_dist_brst_qflux_mag_bulk_subtract',$
  'mms1_dis_dist_brst_flux_mag_no_bulk_subtract','mms1_dis_dist_brst_flux_mag_bulk_subtract',$
  'mms1_dis_dist_brst_mftens_mag_no_bulk_subtract','mms1_dis_dist_brst_mftens_mag_bulk_subtract',$
  'mms1_dis_dist_brst_ptens_mag_no_bulk_subtract','mms1_dis_dist_brst_ptens_mag_bulk_subtract',$
  'mms1_dis_dist_brst_sc_current_mag_no_bulk_subtract','mms1_dis_dist_brst_sc_current_mag_bulk_subtract',$
  'mms1_dis_dist_brst_velocity_mag_no_bulk_subtract','mms1_dis_dist_brst_velocity_mag_bulk_subtract',$
  'mms1_dis_dist_brst_vthermal_mag_no_bulk_subtract','mms1_dis_dist_brst_vthermal_mag_bulk_subtract',$
  
  ; These quantities are not generated for some reason, when field-aligned coordinates are requested.
  ;'mms1_dis_dist_brst_magf_mag_no_bulk_subtract','mms1_dis_dist_brst_magf_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_magt3_mag_no_bulk_subtract','mms1_dis_dist_brst_magt3_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_t3_mag_no_bulk_subtract','mms1_dis_dist_brst_t3_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_sc_pot_mag_no_bulk_subtract','mms1_dis_dist_brst_sc_pot_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_mag_no_bulk_subtract','mms1_dis_dist_brst_symm_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_theta_mag_no_bulk_subtract','mms1_dis_dist_brst_symm_theta_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_phi_mag_no_bulk_subtract','mms1_dis_dist_brst_symm_phi_mag_bulk_subtract',$
  ;'mms1_dis_dist_brst_symm_ang_mag_no_bulk_subtract','mms1_dis_dist_brst_symm_ang_mag_bulk_subtract'
  
  ; HPCA Moments
  'mms1_hpca_hplus_phase_space_density_avgtemp_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_avgtemp_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_density_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_density_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_eflux_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_eflux_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_qflux_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_qflux_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_flux_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_flux_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_mftens_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_mftens_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_ptens_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_ptens_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_sc_current_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_sc_current_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_velocity_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_velocity_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_vthermal_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_vthermal_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_magf_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_magf_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_magt3_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_magt3_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_t3_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_t3_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_sc_pot_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_sc_pot_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_symm_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_symm_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_symm_theta_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_symm_theta_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_symm_phi_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_symm_phi_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_symm_ang_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_symm_ang_bulk_subtract',$

  ; HPCA Field-aligned moments
  'mms1_hpca_hplus_phase_space_density_avgtemp_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_avgtemp_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_density_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_density_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_eflux_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_eflux_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_qflux_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_qflux_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_flux_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_flux_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_mftens_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_mftens_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_ptens_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_ptens_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_sc_current_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_sc_current_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_velocity_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_velocity_mag_bulk_subtract',$
  'mms1_hpca_hplus_phase_space_density_vthermal_mag_no_bulk_subtract','mms1_hpca_hplus_phase_space_density_vthermal_mag_bulk_subtract']
 
;tplot,testvars
tplot_save,testvars,filename='/tmp/mms_getspec_bulkv_validate'
end
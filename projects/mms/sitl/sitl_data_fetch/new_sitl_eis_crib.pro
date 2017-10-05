; Crib for EIS.
; 


timespan, '2016-03-15/00:00:00', 24, /hour

probe = '2'
sc_id = 'mms'+probe
data_units = 'cps'

varformat = ['mms'+probe+'_epd_eis_*_spin', $
  'mms'+probe+'_epd_eis_*_pitch_angle_t*', $
  'mms'+probe+'_epd_eis_*_*_cps_t*']

;mms_load_eis, probes=probe, datatype='extof', level='l1b', data_units = data_units, varformat=varformat
mms_load_eis, probes=probe, trange=trange, datatype='extof', level='l1b', data_units = data_units, varformat=varformat

name = sc_id + '_epd_eis_extof_proton_cps_omni_spin'
newname = sc_id + 'epd_eis_extof_proton_omni_spin'

tplot_rename, name, newname

ylim, newname, 50, 1000

store_data, ['*cps*'], /delete



tplot, newname

end

mms_init, local_data_dir='C:\mms_data_dir'

sw_intervals = [['2017-10-27/20:30', '2017-10-27/20:32'], $
  ['2017-11-18/07:50', '2017-11-18/07:52'], $
  ['2016-12-07/14:40', '2016-12-07/15:15'], $
  ['2016-12-06/11:36', '2016-12-06/11:43'], $ ; no srvy mode velocity data for this date
  ['2017-10-10/02:30', '2017-10-10/02:40'], $
  ['2017-12-01/17:00', '2017-12-01/17:05'], $
  ['2017-12-04/10:10', '2017-12-04/10:15']]

probe='2'
output=['pa', 'energy']
species = 'hplus'
output_folder = 'bulk_vel_subtraction/'
data_rate='brst'

for sw_i=0, n_elements(sw_intervals[0, *])-1 do begin
  mms_part_getspec, instrument='hpca', trange=sw_intervals[*, sw_i], species = 'hplus', output=output, probe=probe, data_rate=data_rate

  mms_part_getspec, tplotnames=tn, instrument='hpca', trange=sw_intervals[*, sw_i], species = 'hplus', output=output, /subtract_bulk, suffix='_bulk', probe=probe, data_rate=data_rate
  
  if undefined(tn) then continue
  
  tdegap, 'mms'+probe+'_hpca_hplus_phase_space_density_energy'+['', '_bulk'], /over
  
  tplot, 'mms'+probe+'_hpca_hplus_phase_space_density_energy'+['', '_bulk']
  makepng, output_folder+'mms'+probe+'_hpca_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDDhhmmss')+'_'+data_rate+'_energy'
  
  tdegap, 'mms'+probe+'_hpca_hplus_phase_space_density_pa'+['', '_bulk'], /over
  
  wi, 1
  tplot, 'mms'+probe+'_hpca_hplus_phase_space_density_pa'+['', '_bulk'], window=1
  makepng, output_folder+'mms'+probe+'_hpca_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDDhhmmss')+'_'+data_rate+'_pad', window=1
  
  del_data, '*'
endfor

stop
end
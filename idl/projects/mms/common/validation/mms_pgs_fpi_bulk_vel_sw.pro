
mms_init, local_data_dir='C:\mms_data_dir' ; so I don't use any local data

sw_intervals = [['2017-10-27/20:30', '2017-10-27/20:32'], $
  ['2017-11-18/07:50', '2017-11-18/07:52'], $
  ['2016-12-07/14:40', '2016-12-07/15:15'], $
  ['2016-12-06/11:36', '2016-12-06/11:43'], $ 
  ['2017-10-10/02:30', '2017-10-10/02:40'], $
  ['2017-12-01/17:00', '2017-12-01/17:05'], $
  ['2017-12-04/10:10', '2017-12-04/10:15']]

probe='4'
output=['pa', 'energy']
species = 'i'
output_folder = 'bulk_vel_subtraction/'
data_rate='fast'
subtract_error = 1
err_suffix = subtract_error eq 1 ? '_err-removed' : ''
subtract_spintone = 1
spintone_suffix = subtract_spintone eq 1 ? '_spintone-removed' : ''

for sw_i=0, n_elements(sw_intervals[0, *])-1 do begin
  mms_part_getspec, instrument='fpi', trange=sw_intervals[*, sw_i], species = species, $
    output=output, probe=probe, data_rate=data_rate, subtract_error=subtract_error

  mms_part_getspec, tplotnames=tn, instrument='fpi', trange=sw_intervals[*, sw_i], $
    species = species, output=output, subtract_spintone=subtract_spintone, $
    subtract_error=subtract_error, /subtract_bulk, suffix='_bulk'+err_suffix+spintone_suffix, probe=probe, data_rate=data_rate
  
  if undefined(tn) then continue
  
  tdegap, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+'_energy'+['', '_bulk'+err_suffix+spintone_suffix], /over
  wi, 0
  tplot, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+'_energy'+['', '_bulk'+err_suffix+spintone_suffix], window=0
  makepng, output_folder+'mms'+probe+'_fpi_'+species+'_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDDhhmmss')+'_'+data_rate+'_energy'+err_suffix+spintone_suffix, window=0
  
  tdegap, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+'_pa'+['', '_bulk'+err_suffix+spintone_suffix], /over
  wi, 1
  tplot, 'mms'+probe+'_d'+species+'s_dist_'+data_rate+'_pa'+['', '_bulk'+err_suffix+spintone_suffix], window=1
  makepng, output_folder+'mms'+probe+'_fpi_'+species+'_'+time_string(sw_intervals[0, sw_i], tformat='YYYYMMDDhhmmss')+'_'+data_rate+'_pad'+err_suffix+spintone_suffix, window=1
  
  
  del_data, '*'
endfor

stop
end
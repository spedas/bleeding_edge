; validation script to compare pitch angles from FEEPS CDFs to those produced from the magnetic field
; 10/1/2018

interval = ['2016-12-31', '2017-1-1']
interval = ['2017-9-1', '2017-9-10']
mms_load_brst_segments, trange=interval, start_times=start_times, end_times=end_times
probe=1
data_rate='brst'
prefix='mms1'
level='l2'
datatype='electron'

for seg_idx=0, n_elements(start_times)-1 do begin
  trange=[start_times[seg_idx], end_times[seg_idx]]

  mms_load_feeps, trange=trange, probe=probe, level=level, data_rate=data_rate, /time_clip, /latest
  mms_feeps_pitch_angles, trange=trange, probe=probe, level=level, data_rate=data_rate, datatype=datatype, suffix=suffix_in, idx_maps=idx_maps
  
  cdf = prefix+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pitch_angle'
  spd = prefix+'_epd_feeps_'+data_rate+'_'+level+'_'+datatype+'_pa'
  tplot, [cdf, spd]
  calc, '"diff"=abs("'+cdf+'"-"'+spd+'")*100/"'+cdf+'"'
  tplot, 'diff', /add
  makepng, 'feeps/feeps_pa_'+time_string(start_times[seg_idx], tformat='YYYYMMDDhhmmss')
 ; stop
endfor


stop
end
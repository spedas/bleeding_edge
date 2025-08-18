pro get_fpc_stuff

times=get_fpc(/times)
n=n_elements(times)
nan=!values.f_nan
nan4=replicate(nan,4)
dnan = !values.d_nan
str={time:dnan, freq:nan, wave_ampl:nan ,sint:nan,cost:nan , $
  total:nan4 , sin:nan4 , cos:nan4 $
  , sin_sig:nan4  , cos_sig:nan4  $
  , e_steps:0 }
data=replicate(str,128,n)

for i=0l,n-1 do begin

  dat= get_fpc(index=i)
  dat.sample_time=dat.sample_time[1] + findgen(128) * dat.spinperiod/512
  
  data[*,i].time = dat.time + dat.sample_time
  data[*,i].freq =dat.freq / dat.spinperiod *1024
  data[*,i].wave_ampl =dat.wave_ampl
  data[*,i].total = transpose(dat.total)
  data[*,i].sin = transpose(dat.sin)
  data[*,i].cos = transpose(dat.cos)
  data[*,i].sin_sig = transpose(dat.sin/sqrt(dat.total+1))
  data[*,i].cos_sig = transpose(dat.cos/sqrt(dat.total+1))
  data[*,i].sint = dat.sint
  data[*,i].cost = dat.cost
  data[*,i].e_steps = dat.e_steps

endfor

data=reform(data,n*128)

store_data,'fpc',data=data,dlim={psym:3}

end
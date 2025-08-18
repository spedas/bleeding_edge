


function thm_sst_dist3d_def,dformat=dformat  ;,ion=ion,elec=elec,time,probe=prb,index=index


dprint,dlevel=3,'Defining: ',  dformat

ion  = strmid(dformat,6,1) eq 'i'
elec = strmid(dformat,6,1) eq 'e'
prb  = strmid(dformat,2,1)
ang  = strmid(dformat,9,3)

case ang of
  '001' :  dat = thm_sst_dist3d_16x1(ion=ion,elec=elec,probe=prb)
  '006' :  dat = thm_sst_dist3d_16x6(ion=ion,elec=elec,probe=prb)
  '064' :  dat = thm_sst_dist3d_16x64(ion=ion,elec=elec,probe=prb)
  '128' : begin & dat = thm_sst_dist3d_16x64(ion=ion,elec=elec,probe=prb) & message & end
endcase

dat.magf = !values.f_nan
;dat.sc_pot = !values.f_nan
dat.index = -1
dat.project_name = 'THEMIS'
dat.data_name = strmid(dformat,4,4)
dat.spacecraft = prb
dat.units_name = 'Compressed Counts'
dat.units_procedure = 'thm_sst_convert_units'
dat.tplotname = dformat

return,dat
end




;20220617 Ali
;creates a series of mvn_sep_fov_snap png images for post-processing into a movie
;trange: time range
;init: run mvn_sep_fov first to calculate parameters

pro mvn_sep_fov_movie,trange=trange,init=init,res=res,save=save,times=times,load=load,spice=spice

  @mvn_sep_fov_common.pro
  if n_elements(save) eq 0 then save=1
  if n_elements(load) eq 0 then load=1
  if n_elements(spice) eq 0 then spice=1
  tr=timerange(trange)
  if tr[0] eq tr[1] then tr[1]+=60.*60*24
  if keyword_set(res) then times=(dgen(range=tr,res=res))[0:-2]
  if keyword_set(init) then mvn_sep_fov,load=load,spice=spice,/calc,/fraction,/store,/tplot,times=times,tr=tr
  if ~keyword_set(times) then times=mvn_sep_fov.time
  wt=where(/null,(times ge tr[0]) and (times le tr[1]))
  foreach time,times[wt],i do begin
    mvn_sep_fov_snap,time=time,/sep,vector=2,save=save
  endforeach

end
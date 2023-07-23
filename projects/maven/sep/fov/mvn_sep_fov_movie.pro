;20220617 Ali
;creates a series of mvn_sep_fov_snap png images for post-processing into a movie
;trange: time range
;init: run mvn_sep_fov first to calculate parameters

pro mvn_sep_fov_movie,trange=trange,init=init

  @mvn_sep_fov_common.pro
  if keyword_set(init) then begin
    tr=timerange(trange)
    if tr[0] eq tr[1] then tr[1]+=60.*60*24
    times=(dgen(range=tr,res=60))[0:-2]
    mvn_sep_fov,/load,/spice,/calc,/fraction,/store,/tplot,times=times
  endif else begin
    times=mvn_sep_fov.time
    tr=minmax(times)
    times=(dgen(range=tr,res=60))
  endelse
  foreach time,times,i do begin
    mvn_sep_fov_snap,time=time,/sep,vector=2,/save
  endforeach

end
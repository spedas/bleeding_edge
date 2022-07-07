;20180405 Ali
;calculates a range of sep fov parameters for different celestial objects and stores them in common block and tplot variables
;fov calculations are done in maven_sep1 coordinates
;lowres: loads sep lowres (5min average) data (use with /load keyword)
;store: stores the results in tplot variables
;tplot: tplots the data
;load: loads sep data
;spice: loads spice data
;trange: specifies time range
;arc: loads sep archive (burst) data
;restore: restores the 5min averaged (lowres) results in the common block
;occalt: lower and upper bound of tangent altitude within which occultation happens
;times: manually input times. e.g., useful for future predict calculations where no sep data is available
;calc: calls mvn_sep_fov_calc to calculate a bunch of parameters
;snap: calls mvn_sep_fov_snap to create plots of fov at a specific time
;nospice: skips slow spice calculations
;
pro mvn_sep_fov,lowres=lowres,tplot=tplot,load=load,spice=spice,trange=trange,arc=arc,restore=restore,occalt=occalt,$
  times=times,calc=calc,snap=snap,objects=objects,nospice=nospice,model=model,fraction=fraction,store=store

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  if keyword_set(restore) then begin
    restore,file='/home/rahmati/Desktop/sep/sep x-rays/mvn_sep_fov_5min_140922_180630.sav'
    ;   restore,file='/home/rahmati/Desktop/sep/sep x-rays/sep_svy_5min_data_140922_180630.sav'
    return
  endif

  if (n_elements(lowres) eq 0) && keyword_set(mvn_sep_fov0) then lowres=mvn_sep_fov0.lowres
  if keyword_set(times) then trange=minmax(times)
  if keyword_set(load) then mvn_sep_var_restore,lowres=lowres,/basic,units='Rate',trange=trange
  if keyword_set(spice) then mvn_spice_load,trange=trange

  if ~keyword_set(times) then begin
    if ~keyword_set(sep1_svy) then begin
      dprint,'sep data not loaded. Please run with the /load keyword. returning...'
      return
    endif
    if keyword_set(arc) then sep1=*(sep1_arc.x) else sep1=*(sep1_svy.x)
    if ~keyword_set(sep1) then begin
      dprint,'no sep data available for selected time range. returning...'
      return
    endif
    times=sep1.time
  endif
  toframe='maven_sep1'
  ;toframe='MSO' ;useful for predictions of future times where sep frame spice data is not available

  if ~keyword_set(occalt) then occalt=[50.,110.]
  if ~keyword_set(objects) then objects=['sun','earth','mars','phobos','deimos']
  mvn_sep_fov0={                                 $
    rmars:3390.d                                ,$ ;km (not accurate)
    detlab:['A-O','A-T','A-F','B-O','B-T','B-F'],$ ;single detector label
    detcol:['k',  'g',  'r',  'b',  'c',  'm']  ,$ ;single detector color
    lowres:keyword_set(lowres)                  ,$
    arc:keyword_set(arc)                        ,$
    occalt:occalt                               ,$
    objects:objects                             ,$
    toframe:toframe}

  if keyword_set(calc) then mvn_sep_fov_calc,times,nospice=nospice
  if keyword_set(snap) then mvn_sep_fov_snap,/sep,/mars,vector=2
  if keyword_set(model) then mvn_sep_fov_xray_model
  mvn_sep_fov_tplot,store=store,tplot=tplot,fraction=fraction,vector=2

end
;+
; PROCEDURE:
;         elf_fgm_fsp_gei2obw
;
; PURPOSE:
;         This routine converts full spin resolved fgm data from GEI coordinates to OBW
;         coordinates system, where b is along model field,
;                                   o is normal to b but outwards from Earth
;                                   w is normal to b but westward: w = (rxb)/|rxb|, where r is satellite position
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probe:        probe name, valid probes for elfin are ['a','b'].
;                       if no probe is specified the default is probe 'a'
;         sz_starttimes: array of science zone collection start times for the specified range.
;                        format is time_double.
;         sz_endtimes:  array of science zone collection end times for the specified range.
;                        format is time_double.
;         no_download:  set this flag so data is not downloaded from server but rather picked
;                       up from the local disk (uses !elf.local_data_dir)
;
; NOTES:
;       This routine expects elfin elx_fgs_fsp_res_gei and elx_pos_gei data to be loaded in tplot
;       variables along with state data. 
;       Position data is interpolated so sz_start/end times are needed so data is not interploated
;       over gaps.
;       Sz_start/end times are passed in from elf_load_fgm rather than determined in this routine.
;       This is because elf_fgm_fsp_gei2ndw requires sz times also. This way the zone times are not
;       calculated twice.
;
;-

pro elf_fgm_fsp_gei2obw, trange=trange, probe=probe, sz_starttimes=sz_starttimes,sz_endtimes=sz_endtimes, $
    no_download=no_download

  ; Initialized variables
  timeduration=(time_double(trange[1])-time_double(trange[0]))
  timespan,trange[0],timeduration,/seconds
  tr=timerange()
  elf_load_state, probe=probe, trange=tr, no_download=no_download, suffix='_fsp'
  if ~keyword_set(probe) then probe = 'a' else probe = probe
  if ~keyword_set(sz_starttimes) then begin
    dprint, 'No *fgs_fsp_* data.'
    return
  endif

  ; will also need state data. check that is has been loaded
;  if not spd_data_exists('el'+probe+'_pos_gei',tr[0],tr[1]) then $
;    elf_load_state, probe=probe, trange=tr, no_download=no_download
  ; verify that state data was loaded, if not print error and return
  if not spd_data_exists('el'+probe+'_pos_gei_fsp',tr[0],tr[1]) then begin
    dprint, 'There is no data for el'+probe+'_pos_gei for '+ $
      time_string(tr[0])+ ' to ' + time_string(tr[1])
    return
  endif

  copy_data, 'el'+probe+'_pos_gei_fsp', 'elx_pos_gei'
  tinterpol_mxn, 'el'+probe+'_att_gei_fsp', 'el'+probe+'_pos_gei_fsp'
  copy_data, 'el'+probe+'_att_gei_fsp_interp', 'elx_att_gei'
  copy_data, 'el'+probe+'_fgs_fsp_res_dmxl', 'elx_fgs_fsp_res_dmxl'
  copy_data, 'el'+probe+'_fgs_fsp_res_gei', 'elx_fgs_fsp_res_gei'
  copy_data, 'el'+probe+'_fgs_fsp_igrf_dmxl', 'elx_fgs_fsp_igrf_dmxl'
  copy_data, 'el'+probe+'_fgs_fsp_igrf_gei', 'elx_fgs_fsp_igrf_gei'

  get_data, 'elx_pos_gei', data=pos, dlimits=dlpos, limits=lpos
  get_data, 'elx_att_gei', data=att, dlimits=dlatt, limits=latt
  get_data, 'elx_fgs_fsp_igrf_dmxl', data=igrf_dmxl

  ; Interpolate position and attitude data to spin resolution
  for i=0,n_elements(sz_starttimes)-1 do begin
    time_clip, 'elx_pos_gei', sz_starttimes[i], sz_endtimes[i], newname='elx_pos_gei_tclipped'
    time_clip, 'elx_att_gei', sz_starttimes[i], sz_endtimes[i], newname='elx_att_gei_tclipped'
    time_clip, 'elx_fgs_fsp_igrf_dmxl', sz_starttimes[i], sz_endtimes[i], newname='elx_fgs_fsp_igrf_dmxl_tclipped'
    tinterpol_mxn,'elx_pos_gei_tclipped','elx_fgs_fsp_igrf_dmxl_tclipped',newname='elx_pos_gei_tclipped' ; get same times as for actual data
    tinterpol_mxn,'elx_att_gei_tclipped','elx_fgs_fsp_igrf_dmxl_tclipped',newname='elx_att_gei_tclipped' ; get same times as for actual data
    get_data, 'elx_pos_gei_tclipped', data=pos_tclip
    get_data, 'elx_att_gei_tclipped', data=att_tclip
    append_array, post, pos_tclip.x
    append_array, posx, pos_tclip.y[*,0]
    append_array, posy, pos_tclip.y[*,1]
    append_array, posz, pos_tclip.y[*,2]
    append_array, attt, att_tclip.x
    append_array, attx, att_tclip.y[*,0]
    append_array, atty, att_tclip.y[*,1]
    append_array, attz, att_tclip.y[*,2]
  endfor

  store_data, 'elx_pos_gei', data={x:post, y:[[posx],[posy],[posz]]}, dlimits=dlpos, limits=lpos
  store_data, 'elx_att_gei', data={x:attt, y:[[attx],[atty],[attz]]}, dlimits=dlpos, limits=lpos
  
  tinterpol_mxn,'elx_pos_gei','elx_fgs_fsp_igrf_dmxl',newname='elx_pos_gei' ; get same times as for actual data
  tinterpol_mxn,'elx_att_gei','elx_fgs_fsp_igrf_dmxl',newname='elx_att_gei' ; get same times as for actual data
  ;
  ; Rotate to FAC (obw)
  ;   get b first by normalizing the model field (IGRF)
  ;   then get w = (rxb)/|rxb|
  ;   then get o = bxw
  tnormalize,'elx_fgs_fsp_igrf_gei',newname='elx_fgs_fsp_igrf_gei_norm'
  tnormalize,'elx_pos_gei',newname='elx_pos_gei_norm'
  tcrossp,'elx_pos_gei_norm','elx_fgs_fsp_igrf_gei_norm',newname='BperpWest'
  tnormalize,'BperpWest',newname='BperpWest_norm'
  tcrossp,'elx_fgs_fsp_igrf_gei_norm','BperpWest_norm',newname='BperpOut'
  tnormalize,'BperpOut',newname='BperpOut_norm'
  ;
  get_data,'elx_fgs_fsp_igrf_gei_norm',data=elx_fgs_fsp_igrf_gei_norm,dlim=my_dl_elx_fgs_fsp_igrf_gei_norm,lim=my_lim_elx_fgs_fsp_igrf_gei_norm
  get_data,'BperpOut_norm',data=BperpOut_norm
  get_data,'BperpWest_norm',data=BperpWest_norm
  gei2obw=[[[BperpOut_norm.y[*,0]],[elx_fgs_fsp_igrf_gei_norm.y[*,0]],[BperpWest_norm.y[*,0]]],$
    [[BperpOut_norm.y[*,1]],[elx_fgs_fsp_igrf_gei_norm.y[*,1]],[BperpWest_norm.y[*,1]]],$
    [[BperpOut_norm.y[*,2]],[elx_fgs_fsp_igrf_gei_norm.y[*,2]],[BperpWest_norm.y[*,2]]]]
  store_data,'rotgei2obw',data={x:elx_fgs_fsp_igrf_gei_norm.x,y:gei2obw},dlim=my_dl_elx_fgs_fsp_igrf_gei_norm,lim=my_lim_elx_fgs_fsp_igrf_gei_norm
  ;
  tvector_rotate,'rotgei2obw','elx_fgs_fsp_igrf_gei',newname='elx_fgs_fsp_igrf_obw'
  calc," 'elx_fgs_fsp_gei' = 'elx_fgs_fsp_res_gei'+'elx_fgs_fsp_igrf_gei' "
  tvector_rotate,'rotgei2obw','elx_fgs_fsp_gei',newname='elx_fgs_fsp_obw'
  calc," 'elx_fgs_fsp_res_obw' = 'elx_fgs_fsp_obw'-'elx_fgs_fsp_igrf_obw' "

  copy_data, 'elx_fgs_fsp_res_obw', 'el'+probe+'_fgs_fsp_res_obw'
  copy_data, 'elx_fgs_fsp_igrf_obw', 'el'+probe+'_fgs_fsp_igrf_obw'
  options,'el'+probe+'_fgs_fsp_res_obw',spec=0, colors=['b','g','r'],labels=['O','B','W'],labflag=1;, ytitle='el'+probe+'_fgs_fsp_res_obw'
  options,'el'+probe+'_fgs_fsp_igrf_obw',spec=0, colors=['b','g','r'],labels=['O','B','W'],labflag=1;, ytitle='el'+probe+'_fgs_fsp_igrf_obw'
  options,'el'+probe+'_fgs_*','databar',0.

  ; remove unneeded tplot variables.
  del_data, 'elx*'
  del_data, 'rot*'
  del_data, 'calc*'
  del_data, 'Bper*'
  del_data, '*fgs_fsp_igrf_ndw'
  del_data, '*fgs_fsp_igrf_obw'

end

;+
; PROCEDURE:
;         elf_fgm_fsp_gei2ndw
;
; PURPOSE:
;         This routine converts full spin resolved fgm data from GEI coordinates to NDW
;         spherical coordinates (NDW: N=north (spherical -theta, positive North), D=radial down (spherical -r)
;         W=west (spherical -phi)
;
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
;       Position data is interpolated To sz_start/end times are needed so data is not interploated 
;       over gaps. 
;       Sz_start/end times are passed in from elf_load_fgm rather than determined in this routine.
;       This is because elf_fgm_fsp_gei2obw requires sz times also. This way the zone times are not
;       calculated twice.
;
;-

pro elf_fgm_fsp_gei2ndw, trange=trange, probe=probe, sz_starttimes=sz_starttimes,sz_endtimes=sz_endtimes, $
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
 
  ; check that fgs_fsp data has been loaded
  if ~spd_data_exists('el'+probe+'_fgs_fsp_res_dmxl',tr[0],tr[1]) then begin
    dprint, 'There is no el'+probe+'_fgs_fsp_res_dmxl data'
    return
  endif

  ; will also need state data. check that it's has been loaded
;  if ~spd_data_exists('el'+probe+'_pos_gei',tr[0],tr[1]) then $
;    elf_load_state, probe=probe, trange=tr, no_download=no_download
  ; verify that state data was loaded, if not print error and return
  if ~spd_data_exists('el'+probe+'_pos_gei_fsp',tr[0],tr[1]) then begin
    dprint, 'There is no data for el'+probe+'_pos_gei for '+ $
      time_string(tr[0])+ ' to ' + time_string(tr[1])
    return
  endif      
 
  ; check for science zone times
  if ~keyword_set(sz_starttimes) OR ~keyword_set(sz_endtimes) then begin
     dprint, 'There are no science zones for '+ $
       time_string(tr[0])+ ' to ' + time_string(tr[1])
     return
  endif
 
  copy_data, 'el'+probe+'_pos_gei_fsp', 'elx_pos_gei'
  copy_data, 'el'+probe+'_att_gei_fsp', 'elx_att_gei'
  copy_data, 'el'+probe+'_fgs_fsp_res_dmxl', 'elx_fgs_fsp_res_dmxl'
  copy_data, 'el'+probe+'_fgs_fsp_res_gei', 'elx_fgs_fsp_res_gei'
  copy_data, 'el'+probe+'_fgs_fsp_igrf_dmxl', 'elx_fgs_fsp_igrf_dmxl'
  copy_data, 'el'+probe+'_fgs_fsp_igrf_gei', 'elx_fgs_fsp_igrf_gei'

  get_data, 'elx_pos_gei', data=pos, dlimits=dlpos, limits=lpos
  get_data, 'elx_att_gei', data=att, dlimits=dlatt, limits=latt
  get_data, 'elx_fgs_fsp_res_dmxl', data=fsp_dmxl

  ; Perform interpolation of position and attide data (then append values and store after loop)
  for i=0,n_elements(sz_starttimes)-1 do begin
    time_clip, 'elx_pos_gei', sz_starttimes[i], sz_endtimes[i], newname='elx_pos_gei_tclipped'
;    time_clip, 'elx_att_gei', sz_starttimes[i], sz_endtimes[i], newname='elx_att_gei_tclipped'
    time_clip, 'elx_fgs_fsp_res_dmxl', sz_starttimes[i], sz_endtimes[i], newname='elx_fgs_fsp_res_dmxl_tclipped'    
    tinterpol_mxn,'elx_pos_gei_tclipped','elx_fgs_fsp_res_dmxl_tclipped',newname='elx_pos_gei_tclipped' ; get same times as for actual data
;    tinterpol_mxn,'elx_att_gei_tclipped','elx_fgs_fsp_res_dmxl_tclipped',newname='elx_att_gei_tclipped' ; get same times as for actual data
    get_data, 'elx_pos_gei_tclipped', data=pos_tclip
;    get_data, 'elx_att_gei_tclipped', data=att_tclip
    append_array, post, pos_tclip.x
    append_array, posx, pos_tclip.y[*,0]
    append_array, posy, pos_tclip.y[*,1]
    append_array, posz, pos_tclip.y[*,2]
;    append_array, attt, att_tclip.x
;    append_array, attx, att_tclip.y[*,0]
;    append_array, atty, att_tclip.y[*,1]
;    append_array, attz, att_tclip.y[*,2]
  endfor
  store_data, 'elx_pos_gei', data={x:post, y:[[posx],[posy],[posz]]}, dlimits=dlpos, limits=lpos
;  store_data, 'elx_att_gei', data={x:attt, y:[[attx],[atty],[attz]]}, dlimits=dlpos, limits=lpos

  ; Convert from GEI coordinates to SM  
  cotrans,'elx_pos_gei','elx_pos_gse',/GEI2GSE
  cotrans,'elx_pos_gse','elx_pos_gsm',/GSE2GSM
  cotrans,'elx_pos_gsm','elx_pos_sm',/GSM2SM 
 
  ; cotrans fgs_fsp_res_gei into SM 
  cotrans,'elx_fgs_fsp_res_gei','elx_fgs_fsp_res_gse',/GEI2GSE
  cotrans,'elx_fgs_fsp_res_gse','elx_fgs_fsp_res_gsm',/GSE2GSM
  cotrans,'elx_fgs_fsp_res_gsm','elx_fgs_fsp_res_sm',/GSM2SM 
  
  ; cotrans fgs_fsp_igrf_gei into SM 
  cotrans,'elx_fgs_fsp_igrf_gei','elx_fgs_fsp_igrf_gse',/GEI2GSE
  cotrans,'elx_fgs_fsp_igrf_gse','elx_fgs_fsp_igrf_gsm',/GSE2GSM
  cotrans,'elx_fgs_fsp_igrf_gsm','elx_fgs_fsp_igrf_sm',/GSM2SM
   
  ; Convert to polar coordinates and rotate data 
  xyz_to_polar,'elx_pos_sm',/co_latitude
  calc," 'elx_pos_sm_mlat' = 90.-'elx_pos_sm_th' "
  get_data,'elx_pos_sm_th',data=elx_pos_sm_th,dlim=myposdlim,lim=myposlim
  get_data,'elx_pos_sm_phi',data=elx_pos_sm_phi
  calc," 'elx_pos_sm_mlt' = ('elx_pos_sm_phi' + 180. mod 360. ) / 15. "
  csth=cos(!PI*elx_pos_sm_th.y/180.)
  csph=cos(!PI*elx_pos_sm_phi.y/180.)
  snth=sin(!PI*elx_pos_sm_th.y/180.)
  snph=sin(!PI*elx_pos_sm_phi.y/180.)
  rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
  store_data,'rot2rthph',data={x:elx_pos_sm_th.x,y:rot2rthph},dlim=myposdlim,lim=myposlim
  tvector_rotate,'rot2rthph','elx_fgs_fsp_res_sm',newname='elx_fgs_fsp_res_sm_sph'
  tvector_rotate,'rot2rthph','elx_fgs_fsp_igrf_sm',newname='elx_fgs_fsp_igrf_sm_sph'
  rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]]
  ; here use a new system, spherical coord's satellite centered, NDW: N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  rotSMSPH2NDW=[[[snth*0.],[snth*0.-1],[snth*0.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.],[snth*0.-1]]]
  ;
  store_data,'rotSMSPH2NDW',data={x:elx_pos_sm_th.x,y:rotSMSPH2NDW},dlim=myposdlim,lim=myposlim
  ;
  tvector_rotate,'rotSMSPH2NDW','elx_fgs_fsp_res_sm_sph',newname='elx_fgs_fsp_res_sm_NDW' ; N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  tvector_rotate,'rotSMSPH2NDW','elx_fgs_fsp_igrf_sm_sph',newname='elx_fgs_fsp_igrf_sm_NDW' ; N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  ;
  ; set plot options
  options,'elx_fgs_fsp_res_sm_NDW',spec=0, colors=['b','g','r'],labels=['N','D','W'],labflag=1, ytitle='el'+probe+'_fgs_fsp_res_sm_ndw'
  options,'elx_fgs_*','databar',0.
  options,'elx_fgs_*',colors=['b','g','r']
  options,'elx_fgs_*','databar',0.
  options,'elx_fgs_*',colors=['b','g','r']
  copy_data, 'elx_fgs_fsp_res_sm_NDW', 'el'+probe+'_fgs_fsp_res_ndw'
  copy_data, 'elx_fgs_fsp_igrf_sm_NDW','el'+probe+'_fgs_fsp_igrf_ndw'

end


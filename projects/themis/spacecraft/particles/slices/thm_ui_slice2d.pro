;Function to load requested mag data
;and save in tplot variable, 
;returns 1 if successful.
;
function thm_ui_slice2d_getmag, type, probe, trange, name, suffix,  err_msg=err_msg

      compile_opt idl2, hidden

  thm_load_fgm, level=2, coord='dsl', probe=probe, datatype=type, $
                trange=trange, suffix=suffix

  names = tnames('*'+suffix)
  
  if names[0] eq '' then begin
    err_msg = 'Error: Cannot load '+type+' data for requested time range.'
    return, 0b
  endif
  
  store_data, names, newname=name

  return, 1b
  
end



;Function to load requested velocity data 
;and save in tplot variable, returns 1 if 
;successful.
;
function thm_ui_slice2d_getvel, type, probe, trange, vel_name, suffix, err_msg=err_msg

      compile_opt idl2, hidden

  ; Assume type contains 'p???' designation (e.g. 'peif','ptem') 
  inst = strmid(type,1,1)
  dtype = strmid(type,3,1)

  ; Load requested velocify into tplot 
  if dtype eq 'm' then begin
    name = 'th'+probe+'_'+type+'_velocity'+suffix
    thm_load_mom, probe=probe, trange=trange, suffix=suffix
  endif else begin
    if inst eq 'e' then begin
      name = 'th'+probe+'_'+type+'_velocity_dsl'+suffix
      thm_load_esa, probe=probe, datatype = type+'_velocity_dsl', suffix=suffix, trange=trange
    endif else if inst eq 's' then begin
      name = 'th'+probe+'_'+type+'_velocity_dsl'+suffix
      thm_load_sst, probe=probe, datatype = type+'_velocity_dsl', level=2, suffix=suffix, trange=trange
    endif else begin 
      err_msg = 'Error:  This software does not load '+type+' velocity data.'
      return, 0b
    endelse
  endelse

  tname = tnames(name)

  ; Check for no data.
  if tname[0] eq '' then begin
    err_msg = 'Error: Cannot load '+type+' data for requested time range.'
    return, 0b
  endif
  
  store_data, tname[0], newname=vel_name ;rename variable
    
  return, 1b

end



; Checks for valid numbers 
; *Should be used if number is being pulled from a plain
;  text field instead of a spinner widget.
;
function thm_ui_slice2d_checknum, num

    compile_opt idl2, hidden

  if is_numeric(num) then begin
      on_ioerror, fail
    return, double(num)
    fail: return, !values.D_NAN
  endif else begin
    return,!values.D_NAN
  endelse

end



;Standard error message handling for thm_ui_slice2d_gen
;
pro thm_ui_slice2d_error, sb, title, err_msg

      compile_opt idl2, hidden

    ok = dialog_message(err_msg,/center,title=title)
    thm_ui_slice2d_message, err_msg, sb=sb
    
end



;Function to check whether distribution array needs
; to be re-loaded. 
; 
; Returns 1 if loading distributions can be skipped, 0 otherwise
; 
function thm_ui_slice2d_check, tlb, state, previous

    compile_opt idl2, hidden


  ; Were any slices produced last time?
  ;
  if state.flags.forcereload then return, 0b


  ; Check probe
  ;
  id = widget_info(tlb, find_by_uname='probe')
  probeidx = widget_info(id, /list_select)
  if probeidx ne previous.probeidx then return, 0b
  
  
  ; Check distribution type
  ;
  id = widget_info(tlb, find_by_uname='dtype')
  didx = widget_info(id, /list_select)
  if ~array_equal(didx, previous.didx) then return, 0b


  ; Check time range
  ;
  id = widget_info(tlb, find_by_uname='time')
  widget_control, id, get_value=time_obj
  t0 = time_obj->getstarttime()
  t1 = time_obj->getendtime()
  if t0 lt previous.trange[0] then return, 0b
  if t1 gt previous.trange[1] then return, 0b
  
  
  ; Check eclipse corrections
  id = widget_info(tlb, find_by_uname='eclipse')
  if 2 * widget_info(id, /button_set) ne previous.eclipse then return, 0b
  
  ;Check SST calibration
  id = widget_info(tlb, find_by_uname='sstcal')
  if widget_info(id, /button_set) ne previous.sst_cal then return, 0b
  
  
  ;Check ESA background options
  ;
  id = widget_info(tlb, find_by_uname='esaremovebase')
  if widget_info(id, /sens) ne previous.esa_remove then return, 0b

  if widget_info(id, /sens) then begin
    id = widget_info(tlb, find_by_uname='esatype')
    bgnd_type = widget_info(id, /combobox_gettext)
    if bgnd_type ne previous.bgnd_type then return, 0b
    
    id = widget_info(tlb, find_by_uname='esanpoints')
    widget_control, id, get_value = bgnd_npoints
    if bgnd_npoints ne previous.bgnd_npoints then return, 0b
    
    id = widget_info(tlb, find_by_uname='esascale')
    widget_control, id, get_value = bgnd_scale
    if bgnd_scale ne previous.bgnd_scale then return, 0b
  endif
  
  return, 1b

end



;Procedure called to generate slice
;
pro thm_ui_slice2d_gen, tlb, state

      compile_opt idl2, hidden

  ;initializations
  vel_auto = 0b
  mag_name = '2dslice_temp_mag'
  vel_name = '2dslice_temp_vel'
  temp_suffix =  '_2dslice_temp'
  erange=0
  fail='' ;error reporting
  more='' ;output message suffix
  err_title='Error Generating Slice'

  ; skip re-loading distributions?
  skip = thm_ui_slice2d_check(tlb, state, state.previous)
  
  ; if no slices are produced this time then ensure the data
  ; is reloaded next time (double check against option changes)
  state.flags.forcereload = 1b


  ;-------------------------------------------------------------------
  ;Retrieve options from widgets (this may be a bit long...) 
  ;-------------------------------------------------------------------

  ; Get resolution (# points/dimension) for final plot
  id = widget_info(tlb, find_by_uname='resolution')
  if widget_info(id, /sens) then begin
    widget_control, id, get_value=resolution
    if ~finite(resolution) || resolution lt 10 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid resolution, the plot resolution should be >= 10. Operation canceled.'
      return
    endif
  endif
  
  
  ; Type of interpolation
  type=0 ;ensure this is set
  id = widget_info(tlb, find_by_uname='button2di')
  if widget_info(id, /button_set) then type=2
  id = widget_info(tlb, find_by_uname='button3di')
  if widget_info(id, /button_set) then type=3
  
  
  ; Radial Log?
  id = widget_info(tlb, find_by_uname='radiallog')
  log = widget_info(id, /button_set)
  
  
  ; Energy plot?
  id = widget_info(tlb, find_by_uname='slicetype')
  energy = strlowcase(widget_info(id, /combobox_gettext)) eq 'energy'
  
  
  ; Get energy range limits if any
  if widget_info(state.erangebase, /sens) then begin
    id = widget_info(tlb, find_by_uname='emin')
    widget_control, id, get_value = emin
    id = widget_info(tlb, find_by_uname='emax')
    widget_control, id, get_value = emax
    
    if ~finite(emin) || ~finite(emax) || emin lt 0 || emax le 0 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid energy range, operation canceled.'
      return
    endif
    if emin ge emax then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Maximum energy must be greater than minimum, operation canceled.'
      return
    endif
    
    erange = [emin, emax]
  endif


  ; Get theta/z range limits if any
  if widget_info(state.rangebase2d, /sens) then begin
    if widget_info(state.thetarangebase, /sens) then begin
      id = widget_info(tlb, find_by_uname='thetamin')
      widget_control, id, get_value = thetamin
      id = widget_info(tlb, find_by_uname='thetamax')
      widget_control, id, get_value = thetamax
      
      if ~finite(thetamin) || ~finite(thetamax) || thetamin lt -90 || thetamax gt 90 then begin
        thm_ui_slice2d_error, state.statusbar, err_title, $
          'Latitude must be between [-90,90] degrees, operation canceled.'
        return
      endif
      if thetamin ge thetamax then begin
        thm_ui_slice2d_error, state.statusbar, err_title, $
          'Maximum latitude angle must be greater than minimum, operation canceled.'
        return
      endif
      
      thetarange = [thetamin, thetamax]
    endif else begin
      id = widget_info(tlb, find_by_uname='zdirmin')
      widget_control, id, get_value = zdirmin
      id = widget_info(tlb, find_by_uname='zdirmax')
      widget_control, id, get_value = zdirmax
      
      if ~finite(zdirmin) || ~finite(zdirmax) then begin
        thm_ui_slice2d_error, state.statusbar, err_title, $
          'Invalid Z-axis restrictions, operation canceled.'
        return
      endif
      if zdirmin ge zdirmax then begin
        thm_ui_slice2d_error, state.statusbar, err_title, $
          'Maximum latitude angle must be greater than minimum, operation canceled.'
        return
      endif
      
      zdirrange = [zdirmin, zdirmax]
    endelse
  endif

  ; Get angular averaging option
  id = widget_info(tlb, find_by_uname='angleave')
  if widget_info(id,/sens)  && widget_info(id,/button_set) then begin
    id = widget_info(tlb, find_by_uname='angleavemax')
    widget_control, id, get_value=ang_max
    id = widget_info(tlb, find_by_uname='angleavemin')
    widget_control, id, get_value=ang_min
    average_angle = [thm_ui_slice2d_checknum(ang_min), $
                     thm_ui_slice2d_checknum(ang_max)   ]
    if in_set(0,finite(average_angle)) then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid range for angular average.'
      return
    endif
  endif
  
  ; Subtract bulk velocity?
  id = widget_info(tlb, find_by_uname='subtract')
  if widget_info(id, /sens) then begin
    subtract = widget_info(id, /button_set)
  endif
    
  ; Get count threshold?
  id = widget_info(tlb, find_by_uname='count_threshold')
  if widget_info(id,/sens) then begin
    widget_control, id, get_value=count_threshold
    if ~finite(count_threshold) || count_threshold lt 0 then begin 
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid count threshold value.'
      return
    endif
    ;clear count_threshold if contour was requested instead
    id = widget_info(tlb, find_by_uname='ctcontbutton')
    if widget_info(id,/button_set) then begin
      count_contour = temporary(count_threshold)
    endif
  endif
  
  ; Smoothing
  id = widget_info(tlb, find_by_uname='smooth_width')
  if widget_info(id, /sens) then begin
    widget_control, id, get_value=smooth
    if ~finite(smooth) || (smooth le 2) then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid smoothing window width (must be >= 3).'
      return
    endif 
  endif else smooth = 0
  
  ; Get slice's normal vector
  slice_norm = [-1d,-1d,-1d]
  unames = ['orx','ory','orz']
  for i=0, n_elements(slice_norm)-1 do begin
    id = widget_info(tlb, find_by_uname=unames[i])
    widget_control, id, get_value = temp
    slice_norm[i] = thm_ui_slice2d_checknum(temp)
  endfor
  if in_set(0,finite(slice_norm)) then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid normal vector, operation canceled.'
    return
  endif
  if norm(slice_norm) lt 5e-6 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid normal vector, length must be > 0.'
    return
  endif
  
  ; Get x slice vector
  idxe = widget_info(tlb, find_by_uname='xenable')
  if widget_info(idxe,/button_set) then begin
  slice_x = [-1d,-1d,-1d]
  unames = ['xsrx','xsry','xsrz']
  for i=0, n_elements(slice_x)-1 do begin
    id = widget_info(tlb, find_by_uname=unames[i])
    widget_control, id, get_value = temp
    slice_x[i] = thm_ui_slice2d_checknum(temp)
  endfor
  if in_set(0,finite(slice_x)) then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid x slice vector, operation canceled.'
    return
  endif
  if norm(slice_x) lt 5e-6 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid x slice vector, length must be > 0.'
    return
  endif
  endif
  
;  ; Get displacement from origin
;  id = widget_info(tlb, find_by_uname='displace')
;  widget_control, id, get_value=displacement
;  if ~finite(displacement) then begin
;    thm_ui_slice2d_error, state.statusbar, err_title, $
;      'Invalid displacement, operation canceled.'
;    return
;  endif 
  
  
  ; Get Time Options
  ;-----------------------
 
  ; get length of time window
  id = widget_info(tlb, find_by_uname='timewin')
  widget_control, id, get_value = timewin
  if ~finite(timewin) || timewin le 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid time window, please re-enter.'
    return
  endif
  
  ; get time incriment
  id = widget_info(tlb, find_by_uname='timeinc')
  widget_control, id, get_value = timeinc
  if ~finite(timeinc) || timeinc le 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid time increment, please re-enter.'
    return
  endif
  
  ;get center option
  id = widget_info(tlb, find_by_uname='center')
  center_time = widget_info(id, /button_set) 
  
  ; get selected time range and set slice windows
  id = widget_info(tlb, find_by_uname='time')
  widget_control, id, get_value=validtime, func_get_value='spd_ui_time_widget_is_valid'
  if ~validtime then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid time range, please re-enter.'
    return
  endif
  widget_control, id, get_value=time_obj, func_get_value='spd_ui_time_widget_get_value'
  t0 = time_obj->getstarttime()
  t1 = time_obj->getendtime()
  trange = [t0,t1]
  trange_p = trange + 120*[-1,1] ; pad time range by 2 minutes on each end to ensure 
                                 ; interpolated velocity data does not contain NaNs
  if timewin gt 90 then trange_p += (timewin-90)*[-1,1] ; add extra padding for
                                                        ; long time windows

  ; create start times for slices
  for t = t0, t1, timeinc do begin
    if t eq t0 then times = [t] $
      else times = [times,t]
  endfor
  if center_time then timeidx = where(times le t1, c) else $
    timeidx = where(times lt t1, c)
  if c ne 0 then times = times[timeidx]
  ntimes = n_elements(times)

  
  ; Determing probe
  id = widget_info(tlb, find_by_uname='probe')
  probeidx = widget_info(id, /list_select)
  if probeidx ge 0 then begin 
    widget_control, id, get_uvalue=val
    probe = val[probeidx]
  endif else begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'No probe selected, operation canceled.'
    return
  endelse
  
  
  ; Determine distribution type
  id = widget_info(tlb, find_by_uname='dtype')
  didx = widget_info(id, /list_select)
  if didx[0] ge 0 then begin 
    widget_control, id, get_uvalue=val
    dtype = val[didx]
    if n_elements(didx) gt 4 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'No more than 4 distribution types can be combined.'
      return
    endif
  endif else begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'No particle distribution selected, operation canceled.'
    return
  endelse

  
  ; Determine units type
  id = widget_info(tlb, find_by_uname='utype')
  uidx = widget_info(id, /list_select)
  if uidx ge 0 then begin 
    widget_control, id, get_uvalue=val
    units = val[uidx]
  endif else begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'No units selected, operation canceled.'
    return
  endelse


  ; Get coordinates
  id = widget_info(tlb, find_by_uname='coord')
  coord = widget_info(id, /combobox_gettext)
  
  ; Get rotation
  id = widget_info(tlb, find_by_uname='rot')
  rotation = widget_info(id, /combobox_gettext)


  ; Get eclipse correction option
  id = widget_info(tlb, find_by_uname='eclipse')
  eclipse = 2 * widget_info(id, /button_set)

  ; Use new sst calibrations?
  id = widget_info(tlb, find_by_uname='sstcal')
  sst_cal = widget_info(id, /button_set)

  ; Suppress SST contamination removal?
  id = widget_info(tlb, find_by_uname='sstcont')
  if ~widget_info(id, /button_set) then begin
    sst_sun_bins = -1
  endif

  ; ESA background removal
  id = widget_info(tlb, find_by_uname='esaremovebase')
  esa_remove = widget_info(id, /sens)
  if esa_remove then bgnd_remove = esa_remove
  
  ; ESA removal type
  id = widget_info(tlb, find_by_uname='esatype')
  if widget_info(id, /sens) then begin
    bgnd_type = widget_info(id, /combobox_gettext)
  endif
  
  ; ESA number of points for background determination
  id = widget_info(tlb, find_by_uname='esanpoints')
  if widget_info(id, /sens) then begin
    widget_control, id, get_value = bgnd_npoints
    if ~finite(bgnd_npoints) || bgnd_npoints lt 1 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid number of pounts for ESA background removal.'
      return
    endif
  endif
  
  ; ESA background scale factor
  id = widget_info(tlb, find_by_uname='esascale')
  if widget_info(id, /sens) then begin
    widget_control, id, get_value = bgnd_scale
    if ~finite(bgnd_scale) || bgnd_scale le 0 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid scale factor for ESA background removal.'
      return
    endif
  endif


  ; Get B-field data if needed
  id = widget_info(tlb, find_by_uname='mag')
  if widget_info(id, /sens)  then begin
    mag_data = mag_name
    mag = strlowcase(widget_info(id, /combobox_gettext))
    ;do not re-load if selection is unchanged and data is present
    if mag ne state.previous.mag or tnames(mag_name) eq '' then begin
      if ~thm_ui_slice2d_getmag(mag, probe, trange_p, mag_data, temp_suffix, err_msg=err_msg) then begin
        if ~keyword_set(err_msg) then err_msg = 'Unkown error loading magnetic field data.'
        thm_ui_slice2d_error, state.statusbar, err_title, err_msg
        state.previous.mag = ''
        return
      endif
    endif
    state.previous.mag = mag
  endif


  ; Get requested velocity data
  if widget_info(state.velbase, /sens) then begin
    id = widget_info(tlb, find_by_uname='vtype')
    vtype = strlowcase(widget_info(id, /combobox_gettext))
    if stregex(vtype,'p[est][ei][fbm]',/bool) then begin
      vel_data = vel_name 
      ;do not re-load if selection is unchanged and data is present
      if vtype ne state.previous.vtype or tnames(vel_name) eq '' then begin
        if ~thm_ui_slice2d_getvel(vtype, probe, trange_p, vel_name, temp_suffix, err_msg=err_msg) then begin
          if ~keyword_set(err_msg) then err_msg = 'Unknown error loading bulk velocity data.'
          thm_ui_slice2d_error, state.statusbar, err_title, err_msg
          state.previous.vtype = ''
          return
        endif
      endif
    endif
    state.previous.vtype = vtype
  endif


  ;-------------------------------------------------------------------
  ; Get array of particle distributions
  ;-------------------------------------------------------------------
  
  ; Skip re-loading distributions if data type, probe, 
  ; mag data selection, vel data, contamination removal 
  ; options remain unchanged and time range is within previous.
  if ~skip then begin 

    thm_ui_slice2d_message, 'Loading Distributions...', sb=state.statusbar
  

    ; Create arrays of particle distributions
    ;
    for i=0, n_elements(state.distribution)-1 do begin
      ptr_free, state.distribution[i]
      
      if i lt n_elements(dtype) then begin
        err_msg = '' ;ensure message from previous pass does not persist
        distribution = thm_part_dist_array(type=dtype[i], probe=probe, trange=trange, $
                          suffix=temp_suffix, err_msg=err_msg, $
                          /get_sun_direction, $  ;auto load sun vector
                          use_eclipse_corrections = eclipse, $
                          ;esa background
                          bgnd_remove=bgnd_remove, bgnd_type=bgnd_type, $
                          bgnd_npoints=bgnd_npoints, bgnd_scale=bgnd_scale, $
                          ;use new sst cal
                          sst_cal=sst_cal )
        
        
        ; Check for errors from thm_part_dist_array
        if size(distribution,/type) ne 10 then begin
          if ~keyword_set(err_msg) then err_msg='Unknown error loading: '+dtype[i]+' data.'
          thm_ui_slice2d_error, state.statusbar, err_title, err_msg
          continue
        endif else if keyword_set(err_msg) then begin
          ; issue error message, but continue if returned distributions are ok
          thm_ui_slice2d_error, state.statusbar, err_title, err_msg
        endif
        
        ; Save distribution
        state.distribution[i] = ptr_new(distribution)
      endif
    endfor
  
    if total(ptr_valid(state.distribution)) lt 1 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'No data could be loaded, slice generation canceled.'
      return
    endif
    
    ; Save settings
    previous = state.previous
    
    str_element, previous, 'didx', didx, /add ;# elements may change
    previous.probeidx = probeidx
    previous.trange = trange

    previous.eclipse = eclipse

    previous.sst_cal = sst_cal
    
    previous.esa_remove = esa_remove
    previous.bgnd_remove = size(bgnd_remove,/type) ? bgnd_remove:-1
    previous.bgnd_npoints = size(bgnd_npoints,/type) ? bgnd_npoints:-1d
    previous.bgnd_scale = size(bgnd_scale,/type) ? bgnd_scale:-1d
    previous.bgnd_type = size(bgnd_type,/type) ? bgnd_type:''
    
    str_element, state, 'previous', previous, /add
    
  endif else begin ; Use old distribution if required options unchanged
  
    thm_ui_slice2d_message, 'Main options unchanged - loading saved distributions...', sb=state.statusbar
;    distribution = *state.distribution
    
  endelse  ;End skip block
  

  ;-------------------------------------------------------------------
  ; Generate data for plotting
  ;-------------------------------------------------------------------
  
  thm_ui_slice2d_message, 'Generating slices...', sb=state.statusbar
  
  ; Populate input parameters to thm_part_slice2d
  ; Loop over stored pointer array, if the pointer is valid
  ; copy its contents into the next input variable to 
  ; thm_part_slice2d
  for i=0, n_elements(state.distribution)-1 do begin
    if ptr_valid(state.distribution[i]) then begin
      x = [keyword_set(dist1),keyword_set(dist2), $
           keyword_set(dist3),keyword_set(dist4)]
      case total(x) of 
        0: dist1 = *state.distribution[i]
        1: dist2 = *state.distribution[i]
        2: dist3 = *state.distribution[i]
        3: dist4 = *state.distribution[i]
        else:
      endcase
    endif
  endfor

  
  ; store which times produce no plots
  bad = bytarr(ntimes)


  for i=0, ntimes-1 do begin

    thm_part_slice2d, dist1, dist2, dist3, dist4, $
                      slice_time=times[i], timewin=timewin, $
                      center_time=center_time, $ 
                      slice_norm=slice_norm, $
                      slice_x=slice_x, $
                      displacement = displacement, $
                      rotation=rotation, resolution=resolution, $
                      type=type, $
                      coord=coord, $
                      erange=erange, $
                      energy=energy, log=log, $
                      mag_data=mag_data, vel_data=vel_data, $
                      zdirrange=zdirrange, thetarange=thetarange, $
                      average_angle=average_angle, $
                      subtract_bulk=subtract, $
                      sst_sun_bins=sst_sun_bins, $
                      count_threshold=count_threshold, $
                      units=units, $
                      smooth=smooth, $
                      part_slice=slice_tmp, $
                      msg_obj = state.statusbar, $ 
                      fail=fail
                      
    
    ; Check for errors from thm_part_slice2d and skip those slices
    if fail then begin
      bad[i] = 1b
      fail = 'Cannot create slice at '+time_string(times[i])+' - '+fail
      thm_ui_slice2d_message, fail, sb=state.statusbar
      continue
    endif
    
    slices = array_concat(temporary(slice_tmp), slices, /no_copy)
    
    ;repeat the process in counts if threshold contour was requested
    if ~undefined(count_contour) then begin
      thm_part_slice2d, dist1, dist2, dist3, dist4, $
        slice_time=times[i], timewin=timewin, $
        center_time=center_time, $
        slice_norm=slice_norm, $
        displacement = displacement, $
        rotation=rotation, resolution=resolution, $
        type=type, $
        coord=coord, $
        erange=erange, $
        energy=energy, log=log, $
        mag_data=mag_data, vel_data=vel_data, $
        zdirrange=zdirrange, thetarange=thetarange, $
        average_angle=average_angle, $
        subtract_bulk=subtract, $
        sst_sun_bins=sst_sun_bins, $
;        count_threshold=count_threshold, $
        units='counts', $
        smooth=smooth, $
        part_slice=slice_counts_tmp, $
        msg_obj = state.statusbar, $
        fail=fail
  
  
      ; Check for errors from thm_part_slice2d and skip those slices
      if fail then begin
        bad[i] = 1b
        fail = 'Cannot calculate count threshold for slice at '+time_string(times[i])+' - '+fail
        thm_ui_slice2d_message, fail, sb=state.statusbar
        continue
      endif
  
      slices_counts = array_concat(temporary(slice_counts_tmp), slices_counts, /no_copy)
    endif
    
  endfor

  
  ; Remove times that did not produce plots
  good = where(bad eq 0b, ngood, ncomplement=nbad)
  if ngood eq 0 || size(slices,/type) ne 8 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'No valid slices could be created, see console output.'
    return
  endif else if nbad gt 0 then begin
    times = times[good]
  endif 
  
  
  ;-------------------------------------------------------------------
  ; Store data and plot
  ;-------------------------------------------------------------------

  ptr_free, state.slices
  state.slices = ptr_new(slices)
  
  ptr_free, state.slices_counts
  if is_struct(slices_counts) then begin
    state.slices_counts = ptr_new(slices_counts)
  endif

  ; if we made it to here, no need to force reload data next time
  state.flags.forcereload = 0b

  ; prep slider bar (start at first slice by default)
  state.slider->setProperty, range=[0,n_elements(slices)-1], ok=1b
  state.slider->update
  state.slider->getProperty, value=current

  ; prep info
  ptr_free, state.times
  state.times = ptr_new(times)  ;ptr_new(times[good])
  state.last = 'th'+probe+'_'+strjoin(dtype,'-')+'_'+rotation
  
  ; plot
  thm_ui_slice2d_plot, state, current

  ; update title
  s = n_elements(slices) ne 1 ? 's':''
  widget_control, state.tlb, tlb_set_title = state.tlb_title + $
                 '  ('+strtrim(n_elements(slices),2)+' plot'+s+')' 

  if nbad ne 0 then more += ' - Some slices could not be produced, see console output' 
  thm_ui_slice2d_message,'Finished'+more, sb=state.statusbar

end



;Plots current slice with given options
;
pro thm_ui_slice2d_plot, state, current, _extra=_extra

    compile_opt idl2, hidden

  tlb = state.tlb
  err_title = 'Error Creating Plot'
  
  if ~ptr_valid(state.slices) then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'No slices currently loaded, operation canceled.'
    return
  endif

  ; Update fixed-range spinners
  thm_ui_slice2d_rangeupdate, tlb, state


  ; Get Z-range limits & options
  ; If the widgets are not sensitezed then their values will have been updated to
  ; reflect the combined range of all loaded plots. Use this range by default
  ; for multiple plots.
  if widget_info(state.zminmaxbase,/sens) || n_elements(*state.times) gt 1 then begin
    id = widget_info(tlb, find_by_uname='zmin')
    widget_control, id, get_value = zmin
    id = widget_info(tlb, find_by_uname='zmax')
    widget_control, id, get_value = zmax
    
    if ~finite(zmin) || ~finite(zmax) || zmin lt 0 || zmax le 0 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid z-axis limits, operation canceled.'
      return
    endif
    if zmin ge zmax then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Maximum z-axis limit must be greater than the minimum, operation canceled.'
      return
    endif
    range = [zmin, zmax]
  endif

  ; Get XY-range limits & options
  if widget_info(state.xyminmaxbase, /sens) then begin
    id = widget_info(tlb, find_by_uname='xymin')
    widget_control, id, get_value = xymin
    id = widget_info(tlb, find_by_uname='xymax')
    widget_control, id, get_value = xymax
    
    if ~finite(xymin) || ~finite(xymax) then begin
      thm_ui_slice2d_error, state.statusbar, err_tittle, $
        'Invalid x-y axis limits, operations canceled.'
      return
    endif
    if xymin ge xymax then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Maximum X,Y axis limit must be greater than minimum, operation canceled.'
      return
    endif
    xrange = [xymin, xymax]
    yrange = [xymin, xymax]
  endif

  ; Get contour lines options
  id = widget_info(tlb, find_by_uname='nolines')
  if widget_info(id, /sensitive) then begin
    widget_control, id, get_value=olines
    if ~finite(olines) || olines lt 0 || olines gt 1e5 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid number of contour levels, operation canceled.'
      return
    endif 
  endif else begin
    olines = 0
  endelse 

  ; Get contour colors options
  id = widget_info(tlb, find_by_uname='nlevels')
  widget_control, id, get_value=nlines
  if ~finite(nlines) || nlines le 0 || nlines gt 1e5 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid number of color levels, operation canceled.'
    return
  endif 

  ; Get character size
  id = widget_info(tlb, find_by_uname='charsize')
  widget_control, id, get_value=charsize
  charsize /= 100
  if ~finite(charsize) || charsize le 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Invalid character size, operation canceled.'
    return
  endif

  ; Get # of ticks
  id = widget_info(tlb, find_by_uname='nxymajor')
  if widget_info(id, /sens) then widget_control, id, get_value = xymajor
  id = widget_info(tlb, find_by_uname='nxyminor')
  if widget_info(id, /sens) then widget_control, id, get_value = xyminor
  id = widget_info(tlb, find_by_uname='nzmajor')
  if widget_info(id, /sens) then widget_control, id, get_value = zmajor
  ;check majorticks for invalid #s
  if size(xymajor,/type) then begin
    if ~finite(xymajor) || (xymajor lt 0) || (xymajor gt 60) then major_tick_err = 1b
  endif
  if size(zmajor,/type) then begin
    if ~finite(zmajor) || (zmajor lt 0) || (zmajor gt 60) then major_tick_err = 1b
  endif
  if keyword_set(major_tick_err) then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Number of major ticks must be between 0 and 60, operation canceled.'
    return
  endif
  ;check minor ticksfor invalid #s
  if size(xyminor,/type) then begin
    temp = size(xymajor,/type) ? xymajor:4 
    if ~finite(xyminor) || xyminor lt 0 || xyminor*temp gt 250 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Number of minor ticks must be between 0 and 250/(# major ticks), operation canceled.'
      return
    endif
  endif
  
  ; Get X & Y axis annotation precision
  id = widget_info(tlb, find_by_uname='xyprecision')
  xyprecision = widget_info(id, /combobox_gettext)
  widget_control, id, get_value=precisions
  xyprecisionindex = where(xyprecision eq precisions, c)
  if c eq 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Cannot identify x/y axis annotation precision, operation canceled.'
    return
  endif
  
  ; Get Z axis annotation precision
  id = widget_info(tlb, find_by_uname='zprecision')
  zprecision = widget_info(id, /combobox_gettext)
  widget_control, id, get_value=precisions
  zprecisionindex = where(zprecision eq precisions, c)
  if c eq 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Cannot identify z axis annotation precision, operation canceled.'
    return
  endif

  ;Get X & Y annotation style
  for i=0, 2 do begin
    id = widget_info(tlb, find_by_uname='xyanno'+strtrim(i,2))
    if widget_info(id, /button_set) then xystyle=i
  endfor
  if size(xystyle,/type) eq 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Cannot determine X/Y axis annotation style, operation canceled.'
    return
  endif

  ;Get Z annotation style
  for i=0, 2 do begin
    id = widget_info(tlb, find_by_uname='zanno'+strtrim(i,2))
    if widget_info(id, /button_set) then zstyle=i
  endfor
  if size(zstyle,/type) eq 0 then begin
    thm_ui_slice2d_error, state.statusbar, err_title, $
      'Cannot determine Z axis annotation style, operation canceled.'
    return
  endif

  ; Get log option
  id = widget_info(tlb, find_by_uname='zlog')
  zlog = widget_info(id, /button_set)

  ; Get sun vector option
  id = widget_info(tlb, find_by_uname='sundir')
  sundir = widget_info(id, /button_set)

  ; Get bulk velocity option
  id = widget_info(tlb, find_by_uname='plotbulk')
  plotbulk = widget_info(id, /button_set)

  ; Get min/max energy circle option
  id = widget_info(tlb, find_by_uname='ecirc')
  ecircle = widget_info(id, /button_set)

  ; Get plot axes option
  id = widget_info(tlb, find_by_uname='axes')
  plotaxes = widget_info(id, /button_set)

  ; Get label contours option
  id = widgeT_info(tlb, find_by_uname='labelcontours')
  clabels = widget_info(id, /button_set)

  
  ; Plot
  ;
  thm_part_slice2d_plot, (*state.slices)[current], $
                     olines=olines, $
                     nlines=nlines, $
                     range=range, $
                     xrange=xrange, $
                     yrange=yrange, $
                     zlog=zlog, $
                     sundir=sundir, $
                     plotbulk=plotbulk, $
                     ecircle=ecircle, $
                     plotaxes=plotaxes, $
                     clabels = clabels, $
                     charsize=charsize, $
                     xprecision=xyprecisionindex, $
                     yprecision=xyprecisionindex, $
                     zprecision=zprecisionindex, $
                     xstyle=xystyle, $
                     ystyle=xystyle, $
                     zstyle=zstyle, $
                     xticks=xymajor, $
                     xminor=xyminor, $
                     yticks=xymajor, $
                     yminor=xyminor, $
                     zticks=zmajor, $
                     _extra=_extra
                     
  
  ; Add contour line at N counts if requested
  if ptr_valid(state.slices_counts) then begin
    
    id = widget_info(tlb, find_by_uname='count_threshold')
    widget_control, id, get_value=count_threshold
    if ~finite(count_threshold) || count_threshold lt 0 then begin
      thm_ui_slice2d_error, state.statusbar, err_title, $
        'Invalid count threshold value.'
      return
    endif
    
    spd_slice2d_add_line, (*state.slices_counts)[current], count_threshold
    
  endif

end



; Export slice(s) to .png
;
pro thm_ui_slice2d_export, state, event

    compile_opt idl2, hidden


  ; check that current data is valid
  if ~ptr_valid(state.slices) then begin
    thm_ui_slice2d_error, state.statusbar, 'Export Error:', $
      'There are no plots to export, operation canceled.'
    return
  endif

  ;export all plots?
  id = widget_info(state.tlb, find_by_uname='exportall')
  all = widget_info(id, /button_set)

  ; check that plotting window is open if exporting one
  if ~keyword_set(all) and !d.window lt 0 then begin
    thm_ui_slice2d_error, state.statusbar, 'Export Error:', $
      'There is no plot currently open, operation canceled.'
    return
  endif

  ; pull default name from last plot
  last = state.last
  filename = last eq '' ? 'new_slice':last
  filename = '(slice_time)_'+filename
  etypes = ['png','eps']
  
  ; get file type
  etype = widget_info(event.id, /uname)
  if etype eq '' then etype = etypes[0]

  ; get file path
  filepath = spd_ui_dialog_pickfile_save_wrapper(title='Export Slice', filter=('*.'+etype), $
                         file=filename, /write, dialog_parent=state.tlb, $
                         /overwrite_prompt)

  ; continue if file path ok
  if is_string(filepath) then begin

    ;strip extension - will be added regardless
    ext_idx = stregex(filepath, '\.'+etypes[0]+' *$', /fold_case)
    if ext_idx gt 0 then filepath = strmid(filepath,0,ext_idx)
    ext_idx = stregex(filepath, '\.'+etypes[1]+' *$', /fold_case)
    if ext_idx gt 0 then filepath = strmid(filepath,0,ext_idx)
    
    ;insert slice time if flag still exists in filepath
    marker_idx = stregex(filepath, '\(slice_time\)', length=mlength, /fold_case)
    if marker_idx ge 0 then begin
      pathname = strmid(filepath,0,marker_idx)
      filename = strmid(filepath,marker_idx+mlength)
      dynamic = 1b
    endif else begin
      file = filepath
      dynamic = 0b
    endelse

    ;create image(s)
    if ~keyword_set(all) then begin
      if dynamic then begin
        state.slider->getProperty, value=current
        file = pathname + time_string((*state.times)[current],format=2) + filename
      endif
      
      ; check for overwrite
      if file_test(file+'.'+etype) then begin
        overwrite = spd_ui_prompt_widget(state.gui_id, (obj_new()), state.historywin, $
                       promptText='Overwrite file: '+file+' ?', /yes, /no, frame_attr=8)
        if overwrite eq 'no' then begin
          thm_ui_slice2d_message,'Export Canceled', sb=state.statusbar
          return
        endif
      endif

      
      ; export to .png
      if etype eq etypes[0] then begin
        makepng, file, mkdir=1b, no_expose=1b
      endif
      
      ; export to .eps
      if etype eq etypes[1] then begin
        state.slider->getProperty, value=current
        ;use built in export option to allow dynamic formatting 2013-08-07
        thm_ui_slice2d_plot, state, current, export=file, /eps
      endif
      
    endif else begin
    
      for j=0, n_elements(*state.times)-1 do begin
        if dynamic then begin
          file = pathname + time_string((*state.times)[j],format=2) + filename
          suffix = ''
        endif else begin 
          suffix = '_'+strtrim(j,2)
        endelse
        
         ; check for overwrite
        if file_test(file+suffix+'.'+etype) then begin
          if keyword_set(allno) then begin
            thm_ui_slice2d_message,'Export - Skipping: '+file+suffix+'.'+etype, sb=state.statusbar
            continue
          endif
          if ~keyword_set(allyes) then begin
            overwrite = spd_ui_prompt_widget(state.gui_id, (obj_new()), state.historywin, $
                           promptText='Overwrite file: '+file+' ?', /yes, /no, /allyes, /allno, /cancel, frame_attr=8)
            if overwrite eq 'cancel' then begin
              thm_ui_slice2d_message,'Export Canceled', sb=state.statusbar
              return
            endif
            allyes = overwrite eq 'yestoall'
            allno = overwrite eq 'notoall'
            if overwrite eq 'no' or allno then begin
              thm_ui_slice2d_message,'Export - Skipping: '+file+suffix+'.'+etype, sb=state.statusbar
              continue
            endif
          endif
        endif 
        
        ; export all to .png
        if etype eq etypes[0] then begin
          thm_ui_slice2d_plot, state, j
          makepng, file+suffix, mkdir=1b, no_expose=1b
        endif
        
        ; export all to .eps
        if etype eq etypes[1] then begin
          ;use built in export option to allow dynamic formatting 2013-08-07
          thm_ui_slice2d_plot, state, j, export = file+suffix, /eps
        endif
      endfor
      
    endelse
    
    thm_ui_slice2d_message,'Export Successful', sb=state.statusbar
  endif else begin
    thm_ui_slice2d_message,'Export Canceled', sb=state.statusbar
  endelse

end



; Legend for rotation option
;
pro thm_ui_slice2d_legend, gui_ID, top_ID, rotation=rotation, coord=coord, bgnd=bgnd

    compile_opt idl2, hidden

  
  cr = ssl_newline()
  
  if keyword_set(rotation) then begin
    legend_type = 'Rotation'
    text = [ $   
     'This specifies the orientation of the slice plane with respect to the coordinate system.', $ 
     'The slice plane''s x and y axes are aligned as follows: ', $
     ' ', $
     'BV:  The x axis is parallel to B field; the bulk velocity defines the x-y plane.', $
     'BE:  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane.', $
     'XY:  The x axis is along the coordinate''s x axis and y is along the coordinate''s y axis', $
     'XZ:  The x axis is along the coordinate''s x axis and y is along the coordinate''s z axis', $
     'YZ:  The x axis is along the coordinate''s y axis and y is along the coordinate''s z axis', $
     'xvel:  The x axis is along the coordinate''s x axis; the x-y plane is defined by the bulk velocity.', $ 
     'perp:  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk).', $
     'perp_xy:  The coordinate''s x & y axes projected onto the plane normal to the B field.', $
     'perp_xz:  The coordinate''s x & z axes projected onto the plane normal to the B field.', $
     'perp_yz:  The coordinate''s y & z axes projected onto the plane normal to the B field.' $
     ]
  endif else if keyword_set(coord) then begin
    legend_type = 'Coordinates'
    text = [ $
     'This specifies the coordinate system in which the slice plane is aligned.', $
     'For example, choosing "GSE" with an "XZ" rotation aligns the slice along the GSE x-z plane.', $
     ' ', $
     'Field Aligned Coordinates: ', $
     ' All field aligned coordinates are oriented such that the z-axis is parallel to the B field. ', $
     ' The x or y axis is then specified by projecting the following vectors onto the plane perpendicular to z.', $
     ' ', $
     ' xgse:  The x axis is the projection of the GSE x-axis', $
     ' ygsm:  The y axis is the projection of the GSM y-axis', $
     ' zdsl:  The y axis is the projection of the DSL z-axis', $
     ' RGeo:  The x is the projection of radial spacecraft position vector (GEI)', $
     ' mRGeo:  The x axis is the projection of the negative radial spacecraft position vector (GEI)', $
     ' phiGeo:  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive eastward', $
     ' mphiGeo:  The y axis is the projection of the azimuthal spacecraft position vector (GEI), positive westward', $
     ' phiSM:  The y axis is the projection of the azimuthal spacecraft position vector in Solar Magnetic coordinates', $
     ' mphiSM:  The y axis is the projection of the negative azimuthal spacecraft position vector in Solar Magnetic coordinates' $
    ]
  endif else if keyword_set(bgnd) then begin
    legend_type = 'ESA Background Removal'
    text = [ $
     'ESA background removal is performed by calculating and subtracting a background value from the ', $
     'distribution at each time sample. The background is calculated to be the average of the smallest N ', $
     'data points multiplied by the scale (for example: if N=3, scale=1.25, and the data are ', $
     '[1,2,3,4,5,6] then the background would be 2.5).', $
     ' ', $
     'This procedure is applied differently depending on the removal type: ', $
     ' ', $
     ' Angle: ', $
     '   The entire distribution is used.', $
     ' ', $
     ' Omni: ', $
     '   The data are averaged over all look directions (phi & theta), yielding ', $
     '   an average value for each energy.  The background is determined from ', $
     '   the averaged values.', $
     ' ', $
     ' Anode: ', $
     '   Data in each of 16 theta bins are averaged over all look directions, ', $
     '   yielding an average value for each energy in each theta bin. A separate ', $
     '   background is determined from the averaged values in each of the theta ', $
     '   bins (16 background levels).' $
    ]
  endif else begin
    return
  endelse


  m = gui_id ne top_id ; top base must be mobile if group leader is as well
  
  tlb2 = widget_base(title = 'Particle Distribution Slices - '+legend_type+' Legend', $
    /base_align_center, /col, modal=m, float=~m, group_leader=gui_id)
    
  mainBase = widget_base(tlb2, /col, xpad=6, ypad=6, space=2, tab_mode=1)

  ;cross platform size control
  mx = max(strlen(text), mi)
  dummy = widget_label(mainbase, value=text[mi])
  geo = widget_info(dummy,/geo)
  widget_control, dummy, /destroy
  
  margin = 1.04
  rotlegend = widget_label(mainbase, value=strjoin(text,cr), $ 
                        xsize=geo.scr_xsize * margin, $
                        ysize=geo.scr_ysize * n_elements(text) * margin )
  
  centertlb, tlb2
  
  widget_control, tlb2, /realize 

end



; Update specifies range spinners
;
pro thm_ui_slice2d_rangeupdate, tlb, state

    compile_opt idl2, hidden

  factor = [0.999,1.001] ;same factor used in thm_part_slice2d_plot
  state.slider->getProperty, value=current

  ; update zrange if auto-range is on
  if ~widget_info(state.zminmaxbase, /sens) then begin
    zrange = minmax((*state.slices).zrange,/pos)
    id = widget_info(tlb, find_by_uname='zmin')
    widget_control, id, set_value = zrange[0]*factor[0]
    id = widget_info(tlb, find_by_uname='zmax')
    widget_control, id, set_value = zrange[1]*factor[1]
  endif
  
  ; update x/y range if auto-range is on
  if ~widget_info(state.xyminmaxbase, /sens) then begin
    xrange = minmax( (*state.slices)[current].xgrid )
    yrange = minmax( (*state.slices)[current].xgrid )
    xyrange = minmax([xrange,yrange])
    id = widget_info(tlb, find_by_uname='xymin')
    widget_control, id, set_value = xyrange[0]
    id = widget_info(tlb, find_by_uname='xymax')
    widget_control, id, set_value = xyrange[1]
  endif 

end



; Properly sensitize options and set defaults 
; according to the slice method. 
; (see thm_part_slice2d)
;
pro thm_ui_slice2d_methodsens, state, id, select

    compile_opt idl2, hidden


  ; determine new/old
  uname = widget_info(id, /uname)
  geo = (uname eq 'buttongeo') && select
  two = (uname eq 'button2di') && select
  three = (uname eq 'button3di') && select
  
  ; apply to widgets
  widget_control, state.rangebase2d, sens = two ;~s
;  widget_control, state.displacementbase, sens = 0 ;~two ;s
  widget_control, state.averagebase, sens = geo ;y
  
  ;smoothing
  id = widget_info(state.tlb, find_by_uname='smooth')
  widget_control, id, set_button = ~geo ;~s
  id = widget_info(state.tlb, find_by_uname='smoothbase')
  widget_control, id, sens = ~geo ;~s
  
  ;contour lines
  if ~state.flags.olinetouched then begin
    id = widget_info(state.tlb, find_by_uname='olines')
    widget_control, id, set_button = ~geo ;~s 
    id = widget_info(state.tlb, find_by_uname='nolines')
    widget_control, id, sens = ~geo ;~s
  endif
  
  ;resolution
  if ~state.flags.restouched then begin
    id = widget_info(state.tlb, find_by_uname='resbutton')
    if ~widget_info(id,/button_set) then begin
      id = widget_info(state.tlb, find_by_uname='resolution')
      widget_control, id, set_value = geo ? 500:150
    endif
  endif
  
  ;bulk velocity subtraction
  thm_ui_slice2d_subtractsens, state

end


; Properly sensitize options when radial log scaling is selected. 
;
pro thm_ui_slice2d_subtractsens, state

    compile_opt idl2, hidden


  id = widget_info(state.tlb, find_by_uname='buttongeo')
  geo = widget_info(id, /button_set)
  id = widget_info(state.tlb, find_by_uname='radiallog')
  radial = widget_info(id, /button_set)
  
  id = widget_info(state.tlb, find_by_uname='subtract')
  widget_control, id, sens = ~radial
  

end



; Properly sensitize options and set defaults 
; according to the slice type. 
;
pro thm_ui_slice2d_typesens, state, typeid

    compile_opt idl2, hidden


  type = strlowcase(widget_info(typeid, /combobox_gettext))
  
  sens = type eq 'energy' ? 1b:0b

  id = widget_info(state.tlb, find_by_uname='radiallog')
  widget_control, id, sens=sens

end



; Properly sensitize support data options
;
pro thm_ui_slice2d_supportsens, state

    compile_opt idl2, hidden
    
 
  id = widget_info(state.tlb, find_by_uname='rot')
  rotation = strlowcase(widget_info(id, /combobox_gettext))
  
  id = widget_info(state.tlb, find_by_uname='coord')
  coord = strlowcase(widget_info(id, /combobox_gettext)) 
  
  id = widget_info(state.tlb, find_by_uname='subtract')
  sub = widget_info(id, /button_set)
  
  ;option only valid for  BV, BE, xvel, and perp
  if in_set(state.rotvel, rotation) then begin
    vsens = 1b
  endif else begin
    vsens = 0b
  endelse
  
  ;always sensitize if set explicitly
  if sub then vsens = 1b

  ;desensitize mag option when not relevant
  if in_set(state.rotmag, rotation) || in_set(state.coordmag, coord) then begin
    msens = 1b
  endif else begin
    msens = 0b
  endelse

  widget_control, state.velbase, sens=vsens
  widget_control, state.magbase, sens=msens
  
end



; Properly sensitize ticks options
;
pro thm_ui_slice2d_ticksens, event, uval

    compile_opt idl2, hidden

  ; user name of corresponding spinner should be "n" + UVAL
  id = widget_info(event.top, find_by_uname='n'+strlowcase(uval))
  widget_control, id, sens=event.select

end



pro thm_ui_slice2d_checkval, state

    compile_opt idl2, hidden


  ; check that current data is valid
  if ~ptr_valid(state.slices) then begin
    state.statusbar->update,'No plots loaded.'
    return
  endif

  ; check that plotting window is open if exporting one
  if ~keyword_set(all) and !d.window lt 0 then begin
    state.statusbar->update,'No current plot.'
    return
  endif

  state.statusbar->update,'Select a location on the current plot...'
  
  ;get cursor position on mouse-click-up
  cursor, x, y, 4, /data
  
  state.slider->getproperty, value=current
  
  ;check that selection was in range
  xrange = minmax( (*state.slices)[current].xgrid )
  yrange = minmax( (*state.slices)[current].xgrid )
  
  if x lt xrange[0] or x gt xrange[1] or y lt yrange[0] or y gt yrange[1] then begin
    state.statusbar->update,'Selection outside plot range.'
    return
  endif
  
  ;get location and print value
  xidx = value_locate( (*state.slices)[current].xgrid, x )
  yidx = value_locate( (*state.slices)[current].ygrid, y )
  
  ;print x/y location if this isn't a radial log plot
  if keyword_set( (*state.slices)[current].rlog ) then begin
    msg = 'Value = ' + strtrim( (*state.slices)[current].data[xidx,yidx], 2)
  endif else begin
    msg = 'Value at ['+strtrim(round(x),2)+', '+strtrim(round(y),2)+'] = '+ $
          strtrim( (*state.slices)[current].data[xidx,yidx], 2)
  endelse

  state.statusbar->update, msg

end



; Event handler
;
pro thm_ui_slice2d_event, event

    compile_opt idl2, hidden
  
  widget_control, event.top, get_uval=state, /no_copy
  
;error catch block
  catch, on_err
  if on_err ne 0 then begin
    catch, /cancel
    help, /last_message, output=msg
    print, msg
    
    if !d.name eq 'PS' then pclose ;ensure PS device closed
    
    store_data, tnames('*2dslice_temp*'), /delete ; delete any temp variables

    if is_struct(state) then begin

      ok=error_message('An unknown error occured and the current operation had to be canceled, '+ $
                       'see console for details.', /noname,/center,title='Error in 2D Slice Options')

      if widget_valid(state.gui_ID) and obj_valid(state.historywin) then begin
        for j=0, n_elements(msg)-1 do state.historywin->update,msg[j]
      endif

      ; reset these structures if state valid
      str_element, state, 'previous', /add, $
             {probeidx:-1,didx:-1,mag:'',vtype:'',trange:[-1d,-1d], $
              bgnd_remove:-1, bgnd_type:'', bgnd_npoints:-1d, bgnd_scale:-1d, $
              esa_remove:-1, sst_cal:-1, eclipse:-1}
      str_element, state, 'flags', /add, $
             {forcereload:1b,olinetouched:0b,restouched:0b}

      widget_control, event.top, set_uval=state, /no_copy

    endif else begin
      ok=error_message('An unknown error occured and the window must be restarted, see console for details.', $
                     /noname,/center, title='Fatal Error in 2D Slice Options')
      
      ; destroy window if state not valid
      widget_control, event.top, /destroy
    
    endelse
    
    return
  endif


;kill requests
  if tag_names(event,/struc) eq 'WIDGET_KILL_REQUEST' then begin
    thm_ui_slice2d_message,'Widget Killed',hw=state.historywin, /dontshow
    widget_control, event.top, set_uval=state, /no_copy
    widget_control, event.top, /destroy
    return
  endif


;use value for case statement
  widget_control, event.id, get_uval=uval

  if size(uval,/type) ne 0 and n_elements(uval) le 1 then begin
    Case uval Of

      'DONE':Begin
        thm_ui_slice2d_message,'2D Slice Options Closed',hw=state.historywin, sb=state.statusbar, /dontshow
        widget_control, event.top, set_uval=state, /no_copy
        widget_control, event.top, /destroy
        return
      end

      'GENERATE': begin
        widget_control, /hourglass
        thm_ui_slice2d_message,'Working...', sb=state.statusbar
        thm_ui_slice2d_gen, state.tlb, state
        store_data, tnames('*2dslice_temp*'), /delete
      end
      
      'REPLOT': begin
        state.slider->getProperty, value=current
        thm_ui_slice2d_plot, state, current
      end

      'SLIDERBAR': begin
        state.slider->update, /event
        thm_ui_slice2d_plot, state, event.value
      end

      'ROTLEGEND': thm_ui_slice2d_legend, state.tlb, state.gui_id, /rotation
      
      'COORDLEGEND': thm_ui_slice2d_legend, state.tlb, state.gui_id, /coord

      'BGNDLEGEND': thm_ui_slice2d_legend, state.tlb, state.gui_id, /bgnd
      
      'ANGLEAVE': begin
        id = widget_info(event.top, find_by_uname='averagebase')
        widget_control, id, sens=event.select
      end
      
      'METHOD': thm_ui_slice2d_methodsens, state, event.id, event.select

      'ERANGE': widget_control, state.erangebase, sens=event.select
      
      'THETARANGE': widget_control, state.thetarangebase, sens=event.select
      
      'ZDIRRANGE': widget_control, state.zdirrangebase, sens=event.select

      'SLICETYPE': begin
        energy = strlowcase(widget_info(event.id, /combobox_gettext)) eq 'energy'

        id = widget_info(event.top, find_by_uname='radiallog')
        widget_control, id, set_button = energy
 
        thm_ui_slice2d_subtractsens, state
      end

      'RADIALLOG': thm_ui_slice2d_subtractsens, state

      'SUBTRACT': thm_ui_slice2d_supportsens, state
      
      'ROT': thm_ui_slice2d_supportsens, state
      
      'COORD': thm_ui_slice2d_supportsens, state
      
      'XENABLE': begin        
        widget_control, widget_info(event.top, find_by_uname='xsrx'), sens=event.select
        widget_control, widget_info(event.top, find_by_uname='xsry'), sens=event.select
        widget_control, widget_info(event.top, find_by_uname='xsrz'), sens=event.select
      end

      'CTBUTTON': begin
        id = widget_info(event.top, find_by_uname='ctoptionsbase')
        widget_control, id, sens=event.select
      end
      
      'SSTCAL': state.flags.forcereload = 1b
      
      'SMOOTH': begin
        id = widget_info(event.top, find_by_uname='smoothbase')
        widget_control, id, sens=event.select
      end

      'RES': begin
        id = widget_info(event.top, find_by_uname='resolution')
        widget_control, id, sens=event.select
        state.flags.restouched = event.select
      end
      
      'ESAREMOVE': begin
        esabase = widget_info(event.top, find_by_uname='esaremovebase')
        widget_control, esabase, sens = widget_info(event.id, /button_set)
      end
      
      'ZMINMAX': widget_control, state.zminmaxbase, sens=~event.select
      
      'XYMINMAX': widget_control, state.xyminmaxbase, sens=~event.select
      
      'OLINES': begin
        id = widget_info(state.tlb, find_by_uname='nolines')
        widget_control, id, sens = event.select
        state.flags.olinetouched = 1b
      end
      
      'XYMAJOR': thm_ui_slice2d_ticksens, event, uval

      'XYMINOR':thm_ui_slice2d_ticksens, event, uval

      'ZMAJOR':thm_ui_slice2d_ticksens, event, uval
      
      'CHECKVAL': thm_ui_slice2d_checkval, state
      
      'EXPORT': thm_ui_slice2d_export, state, event
      
      'EXPORTOPT': begin
        if widget_info(event.id,/button_set) then break
        
        id = widget_info(state.tlb, find_by_uname='exportall')
        widget_control, id, set_button=~widget_info(id,/button_set)
        
        id = widget_info(state.tlb, find_by_uname='exportcurrent')
        widget_control, id, set_button=~widget_info(id,/button_set)
      end
      
      Else: 
    EndCase
  endif

widget_control, event.top, set_uval=state, /no_copy

end ;----------------------------------------------------



;+
;NAME:
;  thm_ui_slice2d
;
;PURPOSE:
;  Front end window allowing user to create and view "2D" slices 
;  of particle distributions.
;
;CALLING SEQUENCE:
;  thm_ui_slice2d
;
;INPUT:
;  gui_id: group leader widget if opening from SPEDAS GUI
;
;OUTPUT:
;  N/A  
;
;NOTES:
;  This routine requires SPEDAS to run. 
;
;  For command line use see:
;    thm_crib_part_slice2d.pro
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2022-03-02 12:37:51 -0800 (Wed, 02 Mar 2022) $
;$LastChangedRevision: 30641 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_ui_slice2d.pro $
;
;-


pro thm_ui_slice2d, gui_ID=gui_id, $
                    _extra=dummy ;SPEDAS API req

    compile_opt idl2

  tlb_title = 'Particle Distribution Slices v4.5'
spd_get_scroll_sizes,xfrac=0.4,yfrac=0.75,scroll_needed=scroll_needed,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size
if keyword_set(gui_ID) then begin
  if (scroll_needed) then begin
    tlb = widget_base(title = tlb_title, /col, /base_align_center, $
      /Floating,group_leader=gui_id, /scroll,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size,/tlb_kill_request_events, tab_mode=1)   
  endif else begin
    tlb = widget_base(title = tlb_title, /col, /base_align_center, $
      /Floating, group_leader=gui_id,/tlb_kill_request_events, tab_mode=1)  
  endelse
endif else begin
  if (scroll_needed) then begin
    tlb = widget_base(title = tlb_title, /col, /base_align_center, $
      /Floating, /scroll,x_scroll_size=x_scroll_size,y_scroll_size=y_scroll_size,/tlb_kill_request_events, tab_mode=1)
  endif else begin
    tlb = widget_base(title = tlb_title, /col, /base_align_center, $
      /Floating,/tlb_kill_request_events, tab_mode=1)
  endelse
  gui_ID=tlb
endelse

;Ensure color table properly set
thm_init
spd_graphics_config

;Bases
;-----

;Tabs
  tabBase = widget_base(tlb, /col, xpad=0, ypad=0, space=2, /base_align_center)
  tabs = widget_tab(tabBase, /align_center)

;Main Base
  mainBase = widget_base(tabs, title='Main', /col, xpad=4, ypad=4, space=2)
    typerow = widget_base(mainbase, /row, /align_center, ypad=2, space=10)
    timebase = widget_base(mainbase, /col, /align_center, ypad=4, xpad=6, $
                           space=0, frame=1)
      dummy = widget_base(mainbase, ypad=6)
    methodrow = widget_base(mainbase, /col, /align_center, ypad=4)
    mainoptionsbase = widget_base(mainbase, /col, /align_left, ypad=2)
      moptbase1 = widget_base(mainoptionsbase, /col, space=4)

;General Options Base
  optionsBase = widget_base(tabs, title='General Options', /col, xpad=4, ypad=6, space=4)
    rangebase2dnn = widget_base(optionsBase, /col, /align_center, ypad=6, xpad=4)
    rangebase2d = widget_base(optionsBase, /col, /align_center, ypad=6, xpad=4)
;    rangebase3d = widget_base(optionsBase, /col, /align_center, ypad=6, xpad=4)
    optionsBase1 = widget_base(optionsBase, /col, /align_center, ypad=2)

;Data Options Base
  dataOptionsBase = widget_base(tabs, title='Data Options', /col, xpad=4, ypad=8, space=8)
    esaContBase = widget_base(dataOptionsBase, /col, /align_left, ypad=4, xpad=4)
    sstContBase = widget_base(dataOptionsBase, /col, /align_left, ypad=4, xpad=4)
    countThreshBase = widget_base(dataOptionsBase, /col, /align_left, ypad=4, xpad=4)
    genDataOptBase = widget_base(dataOptionsBase, /col, /align_left, ypad=4, xpad=4)

;Annotations & Ticks Base
  annoBase = widget_base(tabs, title='Annotations', /col, xpad=4, ypad=4, space=2)
    annotationsBase1 = widget_base(annoBase, /col, /align_center, ypad=8, xpad=4, space=4)
    annotationsBase2 = widget_base(annoBase, /col, /align_center, ypad=4)
    annoBottomBase = widget_base(annoBase, /col, /align_center, ypad=1, xpad=1, space=2)

;Plot Options Base
  plotBase = widget_base(tabs, title='Plot Options', /col, xpad=4, ypad=4, space=2)
    plotoptionsbase1 = widget_base(plotbase, /col, /align_left, ypad=8, xpad=4, space=8)
    plotoptionsbase2 = widget_base(plotbase, /row, /align_center, ypad=4, xpad=4, space=8)
    plotoptionsbase3 = widget_base(plotbase, /col, /align_center, ypad=1, xpad=1, space=2)
  
;Bottom Bases
  sliderbase = widget_base(tabbase, /col, /align_center, ypad=2, xpad=0)
  buttonBase = widget_base(tabbase, /row, /align_center, ypad=2, xpad=0, space=4)
  statusbarBase = widget_base(tabbase, /row, ypad=0, xpad=0)



;Bottom widgets
;--------------

;Slider bar
  slider = obj_new('thm_ui_slice2d_bar', sliderbase, 100, statusbar=statusbar)

  
;Buttons

  generate = widget_button(buttonbase, value='Generate', uval='GENERATE', $
                       tooltip='Load data and generate plots with current options.')
  checkval = widget_button(buttonbase, value='Check Value', uval='CHECKVAL', $
                       tooltip='Display the data value at a particular location on the plot.')
  exportslice = widget_button(buttonbase, value='Export Plots...', /menu, $
                       tooltip='Export plots to image files or postscript.')
    exportpng = widget_button(exportslice, value='PNG', uval='EXPORT', uname='png')
    exporteps = widget_button(exportslice, value='EPS', uval='EXPORT', uname='eps')
    exportcurrent = widget_button(exportslice, value='Current plot', $
                       /checked_menu,/separator,uval='EXPORTOPT',uname='exportcurrent')
    exportall = widget_button(exportslice, value='All plots', $
                       /checked_menu,uval='EXPORTOPT',uname='exportall')
  done = widget_button(buttonbase, value = 'Close', uval='DONE', tooltip='Exits the window.')


;Output
  statusbar = obj_new('spd_ui_message_bar', statusbarbase,  Xsize=60, YSize=1, $
                      value='Status information is displayed here.')
  if ~obj_valid(historywin) then begin
    historyWin = Obj_New('SPD_UI_HISTORY', 0L, tlb);dummy history window in absence of gui
  endif



;Main Tab Widgets
;------------

  probes = ['a','b','c','d','e']
  stypes = ['Velocity','Energy']
  dtypes = ['peif','peir','peib','psif','psir', $
            'peef','peer','peeb','psef','pser','pseb']
  utypes = ['Counts','DF','Rate','Flux','EFlux']

  ;support data
  magtypes = ['fgl','fgh','fgs','fge']
  veltypes = ['<from distribution>','peim','peem','ptim','ptem', $
              'peif','peib','peir','peef','peeb','peer', $
              'psif', 'psef']

  ;coordinate and rotations
  ctypes = ['DSL', 'GSE', 'GSM', $  ;valid coordinates 
            'RGEO', 'MRGEO', 'PHIGEO', 'MPHIGEO', 'PHISM', 'MPHISM', $
            'XGSE', 'YGSM', 'ZDSL']
  rtypes = ['BV', 'BE', 'XY', 'XZ', 'YZ', 'XVEL', $ ;valid rotations
            'PERP', 'PERP_XY', 'PERP_XZ', 'PERP_YZ']
  coordmag = ['rgeo', 'mrgeo', 'phigeo', 'mphigeo', 'phism', 'mphism', $ ;coordinates requiring mag data
              'xgse', 'ygsm', 'zdsl']
  rotmag = ['bv', 'be', 'perp', 'perp_xyz', $ ;rotations requiring mag data
            'perp_xy', 'perp_xz', 'perp_yz' ]
  rotvel = ['bv','be','xvel','perp'] ;rotations requiring vel data


;Data type selection

  probebase = widget_base(typerow, /col)
    probelabel = widget_label(probebase, value='Probe: ')
    probe = widget_list(probebase, value=probes, uval=probes, $
                        uname='probe', ysize=5)
  disttypebase = widget_base(typerow, /col)
    disttypelabel = widget_label(disttypebase, value='Distribution Type:')
    disttype = widget_list(disttypebase, uname='dtype', uval=dtypes, $
                  ysize=n_elements(dtypes), value=dtypes, /multiple)
  unittypebase = widget_base(typerow, /col)
    unittypelabel = widget_label(unittypebase, value='Units: ')
    unittype = widget_list(unittypebase, uname='utype', uval=utypes, $
                  ysize=n_elements(utypes), value=utypes)

  methodbase = widget_base(methodrow, /exclusive, /row, xpad=8, ypad=0, space=0)
    buttonGeo = widget_button(methodbase, value='Geometric', $
                             uname='buttongeo', uval='METHOD', $
                             tooltip='Points on the slice plane are assigned values '+ $
                             'by which bin(s) they intersect. Use high resolution to '+ $
                             'view bin boundaries and low resolution for smooth gradients.')
    button2di = widget_button(methodbase, value='2D Interpolation', $
                             uname='button2di', uval='METHOD', $
                             tooltip='Datapoints within the specified theta or z-axis range '+ $
                             'are projected onto the slice plane and linearly interpolated.')
    button3di = widget_button(methodbase, value='3D Interpolation', $
                             uname='button3di', uval='METHOD', $
                             tooltip='The distribution is linearly interpolated in '+ $
                             'three dimensions then a slice is extracted along the '+ $
                             'designated orientation. (May interpolate over gaps in data).')


;Time range widgets

  cad = '30'       ;seconds
  incriment = '30' ;

  time = spd_ui_time_widget(timebase, statusbar, historywin, uname='time', suppressoneday=1)

  timeoptbase = widget_base(timebase, /row, xpad=3)
    timewindow = spd_ui_spinner(timeoptbase, label='Window Size (sec): ',  $
                        value=cad, uname='timewin', text_box_size=6, incr=1, $
                        getxlabelsize=timelabelsize, min_value=1, $
                        tooltip='Window over which data will be averaged.')
    padbase = widget_base(timeoptbase, /row)
    cBase = widget_base(timeoptbase, /nonexclusive, xpad=0, ypad=0, space=0)
      center = widget_button(cBase, value='Center Time', uname='center', $
                             tooltip='Specified times are used as the center of the time window.')
  timeoptbase1 = widget_base(timebase, /row, xpad=3)
    timeinc = spd_ui_spinner(timeoptbase1, label='Step Time (sec): ', $
                        value=incriment, uname='timeinc', text_box_size=6, incr=1, $
                        xlabelsize=timelabelsize, min_value=1, $
                        tooltip='Time step between slices.')


;Main options

  orn  = ['0','0','1'] ;default orienation vector
  xsrn = ['1','0','0'] ;default x slice vector
  ndisplacement = '0' ;km/s

  slicetypebase = widget_base(moptbase1, /row, xpad=0, ypad=0)
    slicetypelabel = widget_label(slicetypebase, value='Slice Type: ')
    slicetype = widget_combobox(slicetypebase, uname='slicetype', uval='SLICETYPE', value=stypes)
      dropgeo = widget_info(slicetype,/geo)

  coordbase = widget_base(moptbase1, /row, xpad=0, ypad=0)
    coordlabel = widget_label(coordbase, value='Coordinates: ')
    coord = widget_combobox(coordbase, uname='coord', uval='COORD', value=ctypes)
;      dropgeo = widget_info(coord,/geo)
    coordlegend = widget_button(coordbase, value=' ? ', uval='COORDLEGEND', tooltip = $
                              'Displays description of available coordinates')

  rotbase = widget_base(moptbase1, /row, xpad=0, ypad=0)
    rotationlabel = widget_label(rotbase, value='Rotation: ')
    rotation = widget_combobox(rotbase, uname='rot', uval='ROT', value=rtypes, xsize=10)
    rotlegend = widget_button(rotbase, value=' ? ', uval='ROTLEGEND', tooltip = $
                              'Displays description of available slice alignments')
  
  velbase = widget_base(moptbase1, /row, xpad=0, ypad=0)
    vellabel = widget_label(velbase, value='Bulk Velocity, & Mag Data: ')
      mgeo = widget_info(vellabel,/geo)
    veltype = widget_combobox(velbase, uname='vtype', uval='VTYPE', value=veltypes)
    magdata = widget_combobox(velbase, uname='mag', uval='MAG', value=magtypes)
  
  orientationbase = widget_base(moptbase1, /row, xpad=0, ypad=0) ; 'Specify the slice plane''s normal within the coordinates specified by Coordinates and Rotation.'
    orientationlabel = widget_label(orientationbase, value='Slice Plane Normal (x,y,z): ')    
    orx = widget_text(orientationbase, value=orn[0], xsize=4, uname='orx', /edit)
    ory = widget_text(orientationbase, value=orn[1], xsize=4, uname='ory', /edit)
    orz = widget_text(orientationbase, value=orn[2], xsize=4, uname='orz', /edit)
    
  xslicebase = widget_base(moptbase1, /row, xpad=0, ypad=0) ; 'Specify the slice plane''s x axis within the coordinates specified by Coordinates and Rotation.'
    xslicelabel = widget_label(xslicebase, value='X Axis Direction (x,y,z): ')
    xsrx = widget_text(xslicebase, value=xsrn[0], xsize=4, uname='xsrx', sens=0, /edit)
    xsry = widget_text(xslicebase, value=xsrn[1], xsize=4, uname='xsry', sens=0, /edit)
    xsrz = widget_text(xslicebase, value=xsrn[2], xsize=4, uname='xsrz', sens=0, /edit)
    xenablebase = widget_base(xslicebase, /row, xpad=0, ypad=0, /NonExclusive)
    xenable = widget_button(xenablebase, value='Enable', uname='xenable', uvalue='XENABLE', $
      tooltip='If slice x-axis is not set, the projection of ortogonal to the norm vector is used.')

;  displacementbase = widget_base(moptbase1, /row, xpad=0, ypad=0)
;    displacement = spd_ui_spinner(displacementbase, text_box_size=6, incr=50, $
;                              uname='displace', label='Displacement: ', $
;                              xlabelsize=mgeo.scr_xsize-1, value=ndisplacement, $
;                              tooltip='Displacement of slice from zero along '+ $
;                              "the slice plane's normal")




;Options Tab Widgets
;--------------------

  nthetamin = '-20' ;degrees
  nthetamax = '20'
  nzdirmin = '-250' ;km/s
  nzdirmax = '250'
  nemin = '0'  ;eV
  nemax = '30000'
  ct = '1'  ;masking threshold (counts)
  smth = '7'  ;smoothing width (# points)
  angleave = ['-25','25']
  res = '500' ;resolution

;2D Interpolation Ranges

  label2d = widget_label(rangebase2d, value='2D Interpolation Limits')
  subrangebase2d = widget_base(rangebase2d, /col, /base_align_center, $
                            xpad=4, ypad=4, frame=1)
    buttons2dbase = widget_base(subrangebase2d, /row, /exclusive)
      thetarangebutton = widget_button(buttons2dbase, value='Restrict Latitude', $
                                 uname='thetarange', uval='THETARANGE')
      zdirrangebutton = widget_button(buttons2dbase, value='Restrict Z-Axis', $
                                 uname='zdirrange', uval='ZDIRRANGE')
    range2dbase = widget_base(subrangebase2d, /row)
      thetarangeBase = widget_base(range2dbase, /col, xpad=4, ypad=0)
        thetamax = spd_ui_spinner(thetarangeBase, label='Max ('+string(176b)+'): ', $
                                value=nthetamax, uname='thetamax', text_box_size=7, $
                                incr=5, getxlabelsize=scr_xsize, max_value=90, min_value=-90)
        thetamin = spd_ui_spinner(thetarangeBase, label='Min ('+string(176b)+'): ', $
                                value=nthetamin, uname='thetamin', text_box_size=7, $
                                incr=5, xlabelsize=scr_xsize, max_value=90, min_value=-90)
          dummy = widget_label(range2dbase, value=' ')
      zdirrangeBase = widget_base(range2dbase, /col, xpad=4, ypad=0)
        zdirmax = spd_ui_spinner(zdirrangeBase, label='Max: ', $
                                value=nzdirmax, uname='zdirmax', text_box_size=7, $
                                incr=50, getxlabelsize=scr_xsize)
        zdirmin = spd_ui_spinner(zdirrangeBase, label='Min: ', $
                                value=nzdirmin, uname='zdirmin', text_box_size=7, $
                                incr=50, xlabelsize=scr_xsize)

;General Slice ranges

  label3d = widget_label(optionsBase1, value='General Slice Options')
  optionsSubBase1 = widget_base(optionsBase1, /col, xpad=0, ypad=0, frame=1)
  
  subrangebase3d = widget_base(optionsSubBase1, /col, /base_align_center, xpad=4, ypad=4)
    erangebase = widget_base(subrangebase3d, /row, /base_align_center, xpad=0, ypad=1, space=0)
      erangeBase1 = widget_base(erangebase, /row, xpad=0, ypad=0, /nonexclusive)
        erangebutton = widget_button(erangebase1, value='Restrict Energy Range', $
                                   uname='erange', uval='ERANGE') 
      erangeBase2 = widget_base(erangebase, /col, xpad=4, ypad=0)
        emax = spd_ui_spinner(erangebase2, label='Max (eV): ', value=nemax, $
                                  uname='emax', text_box_size=8, incr=1000, $
                                  getxlabelsize=scr_xsize, min_value=10)
        emin = spd_ui_spinner(erangebase2, label='Min (eV): ', value=nemin, $
                                  uname='emin', text_box_size=8, incr=10, $
                                  xlabelsize=scr_xsize, min_value=0)

;Other Options
  optbase1 = widget_base(optionsSubBase1, /col, /align_left, space=3, xpad=4, ypad=4)
    
    averagebase = widget_base(optbase1, /row, xpad=0, ypad=0)
      averagebuttonbase = widget_base(averagebase, /row, xpad=0, ypad=0, /nonexclusive)
        averagebutton = widget_button(averagebuttonbase, $
                       value='Average about x-axis (deg): ', uval='ANGLEAVE', uname='angleave', $
                       tooltip='Average data within the specified angle range. '+ $
                               'The angle is measured from the slice plane and about '+ $
                               'the plane''s x-axis.')
      averagesubbase = widget_base(averagebase, /row, xpad=0, ypad=0, uname='averagebase')
        averagemin = widget_text(averagesubbase, value=angleave[0], xsize=4, uname='angleavemin', /edit)
        averagemax = widget_text(averagesubbase, value=angleave[1], xsize=4, uname='angleavemax', /edit)


    smoothbase = widget_base(optbase1, /row, xpad=0, ypad=0)
      smoothbuttonbase = widget_base(smoothbase, /row, xpad=0, ypad=0, /nonexclusive)
        smoothbutton = widget_button(smoothbuttonbase, value='Smooth Data (width)', uname='smooth', $
                            uvalue='SMOOTH', tooltip='Applies Gaussian smoothing to slice.')
      smoothsubbase = widget_base(smoothbase, /row, xpad=0, ypad=0, uname='smoothbase')
        smoothspinner = spd_ui_spinner(smoothsubbase, value=smth, text_box_size=4, incr=2, $
                        uname='smooth_width', label='', min_value=3, tooltip = 'Width of '+ $
                        'the smoothing window in # of points (only use odd integers >=3)')

    suboptbase1 = widget_base(optbase1, /col, xpad=0, ypad=0, space=2, /nonexclusive)
      radiallog = widget_button(suboptbase1, value='Logarithmic Radial Scaling', $
                               uname='radiallog', uval='RADIALLOG', tooltip = $
                               'Plot against logarithmically scaled energy or velocity.')
      subtract = widget_button(suboptbase1, value='Subtract Bulk Velocity', $
                               uname='subtract', uval='SUBTRACT', tooltip = $
                               'Subtracts specified bulk velocity from distribution.')      

    resolutionbase = widget_base(optbase1, /row, xpad=0, ypad=0)
      resbuttonbase = widget_base(resolutionbase, /row, xpad=0, ypad=0,/nonexclusive)
        resbutton = widget_button(resbuttonbase, value='Specify Resolution: ', $
                            uvalue='RES', tooltip='Specfies the number of elements in each '+ $
                            'dimension of the slice.', uname='resbutton')
      resbase = widget_base(resolutionbase, /row, xpad=0, ypad=0)
        resolution = spd_ui_spinner(resbase, value=res, text_box_size=6, uname='resolution', $
                                 label='', incr=10, min_value=10, $ ;xlabelsize=geo.scr_xsize-1, $
                                 tooltip = 'Specfies the number of elements in each '+ $
                                 'dimension of the slice.')



;Data Options Tab
;-------------------
  esaBgndTypes = ['Anode','Angle','Omni'] ;types of background removal for esa (bgnd_type)
  esaNPoints = 3.0 ; bgnd_npoints 
  esaScaleVal = 1.0 ; bgnd_scale
  
  ;ESA Widgets
  esaRemoveButtonbase = widget_base(esaContBase, /row, /nonexclusive)
    esaRemoveButton = widget_button(esaRemoveButtonbase, val='Remove ESA Background', $
                                    uval='ESAREMOVE', uname='esaremove')
  
  esaRemoveOptsBase = widget_base(esaContBase, /col, xpad=12, uname='esaremovebase', frame=1)
    esaTypeBase = widget_base(esaRemoveOptsBase, /row)
      esaTypeLabel = widget_label(esaTypeBase, value='Type:  ')
      esaType = widget_combobox(esaTypeBase, value=esaBgndTypes, uname='esatype')
      bgndLegend = widget_button(esaTypeBase, value=' ? ', uval='BGNDLEGEND', $
                          tooltip = 'Displays description of background removal options')
    esaNPtsBase = widget_base(esaRemoveOptsBase, /row)
      esaNPts = spd_ui_spinner(esaNPtsBase, label='Number of Points:  ', text_box_size=6, $
                               uname='esanpoints', incr=1, value=esaNPoints, $
                               getXLabelSize=scr_xsize, min_value=1, $
                               tooltip='The number of lowest values points to '+ $
                               'average over when determining background.')
      widget_control, esaTypeLabel, xsize = scr_xsize+1
    esaScaleBase = widget_base(esaRemoveOptsBase, /row)
      esaScale = spd_ui_spinner(esaScaleBase, label='Scaling:  ', text_box_size=6, $ 
                                uname='esascale', incr=.05, value=esaScaleVal, $
                                xlabelsize=scr_xsize, min_value=0, $
                                tooltip='A scaling factor that the background '+ $
                                'will be multiplied by before it is subtracted.')
  
  ;SST Widgets
  sstButtonBase = widget_base(sstContBase, /col, /nonexclusive, space=6)
    sstContButton = widget_button(sstButtonBase, value='Remove SST Contamination', $
       uname='sstcont', tooltip='Interpolated over the default set of contaminated SST bins.')
    sstCalButton = widget_button(sstButtonBase, value='Use default SST calibrations', $
       uname='sstcal', uval='SSTCAL', tooltip='See documentation in <?>.')

  ;Count threshold
  ctButtonBase = widget_base(countThreshBase, /row, /nonexclusive)
    ctButton = widget_button(ctButtonBase, val='Calculate count threshold', $
                          uval='CTBUTTON', uname='ctbutton')
  
  ctOptionsBase = widget_base(countThreshBase, /row, /base_align_center, space=4, $
                              xpad=12, uname='ctoptionsbase', frame=1)
    ctTypeBase = widget_base(ctOptionsBase, /col, xpad=0, ypad=0, /exclusive)
      ctContButton = widget_button(ctTypeBase, uname='ctcontbutton', $
                   value='Draw contour at threshold ', tooltip= $
                   'Draw dashed contour at the specified number of counts.')
      ctMaskButton = widget_button(ctTypeBase, uname='ctmaskbutton', $
                   value='Mask data below threshold ', tooltip= $
                   'Mask data on the final plot that falls below the specified number of counts.')
    ctspinner = spd_ui_spinner(ctOptionsBase, value=ct, text_box_size=4, incr=1, $
                  uname='count_threshold', label='', min_value=1, tooltip= $
                  'Threshold, in counts.  Value is applied after interpolation/averaging.')
    ctupdate = widget_button(ctOptionsBase, value='Re-Plot', uval='REPLOT', tooltip= $
                 'Click to re-plot contour line after changing the value.  '+ $
                 'Must click Generate to calculate the first time.')

  ;Other data options
  genContToggleBase = widget_base(genDataOptBase, /row, /nonexclusive)
    eclipseButton = widget_button(genContToggleBase, value='Apply eclipse corrections', $
      uname='eclipse', tooltip='Apply spin period corrections when spacecraft is eclipsed')



;Ticks and annotations
;--------------------
  nxticks = '4'  ;tick numbers
  nyticks = '4'
  nzticks = '11'
  ncharsize = '100' ;character size (%)
  nprecision = ['1234 (rounded down)', '1.', '1.2', '1.23', '1.234', '1.1234', $
                '1.01234', '1.001234','1.0001234','1.00001234','1.000001234']

;x & y axes
  xylabel = widget_label(annotationsBase1, value='X & Y Axes')
  xyBase = widget_base(annotationsBase1, /row)

;x & y annotations
    xyAnnoBase = widget_base(xyBase, /row, xpad=0, ypad=0)
      xytextbase = widget_base(xyAnnoBase, /col, /base_align_left)
        xyannotatelabel = widget_label(xytextbase, value='Annotations  ')
        xyannotatebase = widget_base(xytextbase, /col, xpad=4, ypad=6, space=6, frame=1)
          xyprecisionbase = widget_base(xyannotatebase, /row, xpad=0, ypad=0)
            xyprecisionlabel = widget_label(xyprecisionbase, value='Precision: ')
            xyprecision = widget_combobox(xyprecisionbase, value=nprecision, uname='xyprecision')
          xyastylebase =  widget_base(xyannotatebase, /col, /exclusive, ypad=0, xpad=0)
            xyannodefault = widget_button(xyastylebase, value = 'Automatic', uname='xyanno0', $
                                 tooltip='Auto-selects between decimal and scientific notation')
            xyannodecimal = widget_button(xyastylebase, value = 'Decimal Notation', uname='xyanno1')
            xyannoexpo = widget_button(xyastylebase, value = 'Scientific Notation', uname = 'xyanno2') 

;x & y ticks
    xytickbase = widget_base(xyBase, /col, /base_align_left)
      xyticknumlabel = widget_label(xytickbase, value='Specify Number of Ticks  ')
      xyticknumbase = widget_base(xytickbase, /col, frame=1)
        xymajortickbase = widget_base(xyticknumbase, /row)
          xymajorbuttonbase = widget_base(xymajortickbase, xpad=0, ypad=0,/nonexclusive,/align_right)
            xymajortickbutton = widget_button(xymajorbuttonbase,value=' ', uval='XYMAJOR', $
                     tooltip='Specify number of major ticks to draw on the x and y axes.')
          xymajorticknum = spd_ui_spinner(xymajortickbase, label='Major: ', sens=0, incr=1,$
                     text_box_size=5, value=nxticks, min_value=0, max_value=60, $
                     uname='nxymajor', tooltip='Number of major ticks to place on the x and y axes.')
        xyminortickbase = widget_base(xyticknumbase, /row)
          xyminorbuttonbase = widget_base(xyminortickbase, xpad=0, ypad=0,/nonexclusive,/align_right)
            xyminortickbutton = widget_button(xyminorbuttonbase,value=' ', uval='XYMINOR', $
                     tooltip='Specify number minor ticks for each interval.')
          xyminorticknum = spd_ui_spinner(xyminortickbase, label='Minor: ', sens=0, incr=1,$
                     text_box_size=5, value=nxticks, min_value=0, max_value=60, $
                     uname='nxyminor', tooltip='Number of minor ticks per interval.')

  dummy = widget_label(annotationsbase1, value = '  ') ;add space between sections

;z axis
  zlabel = widget_label(annotationsBase1, value='Z Axis')
  zBase = widget_base(annotationsBase1, /row)

;z annotations
    zAnnoBase = widget_base(zBase, /row, xpad=0, ypad=0)
      ztextbase = widget_base(zAnnoBase, /col, /base_align_left)
        zannotatelabel = widget_label(ztextbase, value='Annotations  ')
        zannotatebase = widget_base(ztextbase, /col, xpad=4, ypad=6, space=6, frame=1)
          zprecisionbase = widget_base(zannotatebase, /row, xpad=0, ypad=0)
            zprecisionlabel = widget_label(zprecisionbase, value='Precision: ')
            zprecision = widget_combobox(zprecisionbase, value=nprecision, uname='zprecision')
         zastylebase =  widget_base(zannotatebase, /col, /exclusive, ypad=0, xpad=0)
            zannodefault = widget_button(zastylebase, value = 'Automatic', uname='zanno0', $
                                 tooltip='Auto-selects between decimal and scientific notation')
            zannodecimal = widget_button(zastylebase, value = 'Decimal Notation', uname='zanno1')
            zannoexpo = widget_button(zastylebase, value = 'Scientific Notation', uname = 'zanno2') 
  
;z ticks
    ztickbase = widget_base(zBase, /col, /base_align_left)
      zticklabel = widget_label(ztickbase, value='Specify Number of Ticks  ')
      zticknumbase = widget_base(ztickbase, /col, frame=1)
        zmajortickbase = widget_base(zticknumbase, /row)
          zmajorbuttonbase = widget_base(zmajortickbase, xpad=0, ypad=0,/nonexclusive,/align_right)
            zmajortickbutton = widget_button(zmajorbuttonbase,value=' ', uval='ZMAJOR', $
                     tooltip='Specify number of major ticks to draw on the z axis.')
          zmajorticknum = spd_ui_spinner(zmajortickbase, label='Major: ', sens=0, incr=1,$
                     text_box_size=5, value=nxticks, min_value=0, max_value=60, $
                     uname='nzmajor', tooltip='Number of major ticks to place on the z axis.')

  dummy = widget_base(annotationsbase1, ypad=4) ;add space between sections

;text size
  charsizeBase = widget_base(annotationsBase1, /align_left, ypad=6)
    charsize = spd_ui_spinner(annotationsBase1, label='Annotation Text Size:  ', $
                       text_box_size=5, incr=5, value=ncharsize, units='%', uname='charsize', $
                       min_value=0, tooltip='Size of the text printed on the plot')
          

;Other
  annoReplotBase = widget_base(annoBottomBase, /row, /base_align_center, /align_bottom)
    annoReplot = widget_button(annoReplotBase, value = 'Re-Plot', xsize=buttonsize, $
                         uval='REPLOT', tooltip='Replot current slice')


  

;Plot Tab Widgets
;--------------------
  nolines = '8'  ;# contour lines
  nlevels = '60'  ;# color contour levels
  zmax = '1e1'  ; plotting limites (various units)
  zmin = '1e-6'
  xymin = '-2000'
  xymax = '2000'

  moreoptionsbase = widget_base(plotoptionsbase1, /col, /base_align_center, space=2)
    numlevels = spd_ui_spinner(moreoptionsbase, label='Number of Color Contour Levels: ', $
                             uname='nlevels', text_box_size=5, incr=1, value=nlevels, $
                             min_value=1, tooltip='Specifies the number of color contours to draw.')

  olinesbase = widget_base(plotoptionsbase1, /row, /base_align_center, space=2)
    olinebase1 = widget_base(olinesbase, /col, xpad=0, ypad=0, /nonexclusive)
      olinebutton = widget_button(olinebase1, value='Plot Contour Lines', uval='OLINES', $
                         uname='olines',tooltip='Draws contour lines over default plot.')
    numolines = spd_ui_spinner(olinesbase, label='Number of Contour Levels: ', uval='NOLINES', $
                          uname='nolines', text_box_size=5, incr=1, value=nolines, $
                          min_value=1, tooltip='Specifies the number of contour lines to draw.')

  minmaxbase = widget_base(plotoptionsbase1, /row, /base_align_center, space=0)
    minmaxBase1 = widget_base(minmaxbase, /col, xpad=0,ypad=0, /nonexclusive)
      minmaxbutton = widget_button(minmaxBase1, value='Autorange (Z)', $
                                 uname='zminmax', uval='ZMINMAX', tooltip = $
                                 'Non-zero, pre-interpolated extremes used as range. '+ $
                                 '(Values below this minimum could be the result '+ $
                                 'of interpolation/smoothing)') 
    minmaxBase2 = widget_base(minmaxbase, /col, xpad=4, ypad=0)
        dummy2 = widget_label(minmaxBase2, value='Max: ')
        geo2 = widget_info(dummy2, /geo)
        widget_control, dummy2, /destroy
      zminimum = spd_ui_spinner(minmaxbase2, label='Min: ', value=zmin, $
                                uname='zmin', text_box_size=10, incr=1, $
                                xlabelsize=geo2.scr_xsize)
      zmaximum = spd_ui_spinner(minmaxbase2, label='Max: ', value=zmax, $
                                uname='zmax', text_box_size=10, incr=1, $
                                xlabelsize=geo2.scr_xsize)

  xyminmaxbase = widget_base(plotoptionsbase1, /row, /base_align_center, space=0)
    xyminmaxBase1 = widget_base(xyminmaxbase, /col, xpad=0,ypad=0, /nonexclusive)
      xyminmaxbutton = widget_button(xyminmaxBase1, value='Autorange (X,Y)', $
                                 uname='xyminmax', uval='XYMINMAX', tooltip = $
                                 'Grid extremes used as default. ') 
    xyminmaxBase2 = widget_base(xyminmaxbase, /col, xpad=4, ypad=0)
        dummy2 = widget_label(xyminmaxBase2, value='Max: ')
        geo2 = widget_info(dummy2, /geo)
        widget_control, dummy2, /destroy
      xyminimum = spd_ui_spinner(xyminmaxbase2, label='Min: ', value=xymin, $
                                uname='xymin', text_box_size=10, incr=1, $
                                xlabelsize=geo2.scr_xsize)
      xymaximum = spd_ui_spinner(xyminmaxbase2, label='Max: ', value=xymax, $
                                uname='xymax', text_box_size=10, incr=1, $
                                xlabelsize=geo2.scr_xsize)

  dummy = widget_base(plotoptionsbase1)

  checkboxlabel = widget_label(plotoptionsBase1, value='Other options')
  checkboxtopbase = widget_base(plotoptionsbase1, /row, /align_center, $
                                space=8, ypad=6, xpad=6, frame=1)
    checkboxbase1 = widget_base(checkboxtopbase, /col, /nonexclusive, space=4)
      zlogbutton = widget_button(checkboxbase1, value='Logarithmic Z Axis', $
                     uname='zlog', tooltip = 'Use logaithmic contour spacing.')
      sundirbutton = widget_button(checkboxbase1, value='Plot Sun Direction', $
                     uname='sundir', tooltip='Plot slice plane projection of sun vector.')
      bulkbutton = widget_button(checkboxbase1, value='Plot Bulk Velocity', $
                     uname='plotbulk', tooltip='Plot slice plane projection of bulk velocity.')
    checkboxbase2 = widget_base(checkboxtopbase, /col, /nonexclusive, space=4)
      axesbutton = widget_button(checkboxbase2, value='Plot Axes', $
                     uname='axes', tooltip='Plots dashed lines along zero for both axes.')
      energycircbutton = widget_button(checkboxbase2, value='Draw Energy Limits', $
                     uname='ecirc', tooltip='Plots upper/lower energy limits.')
      labelcontours = widget_button(checkboxbase2, value='Label Contour Lines', $
                     uname='labelcontours', tooltip='Plots the numerical value of each contour line')

;Other
  plotReplotBase = widget_base(plotoptionsbase3, /row, /base_align_center)
    replot = widget_button(plotReplotBase, value = 'Re-Plot', xsize=buttonsize, $
                         uval='REPLOT', tooltip='Replot current slice')



;Initialize widgets
;-----------------

; Main Widgets
  widget_control, unittype, set_list_select=1 ;default units (DF)

  widget_control, buttonGeo, set_button=1 ; type of slice
  
  widget_control, slicetype, set_combobox_select=0 ;default to velocity
  widget_control, coord, set_combobox_select=0 ;default coords (DSL)
  widget_control, rotation, set_combobox_select=2

  widget_control, orz, set_value='1' ;default orientation (0,0,1)
  
  widget_control, xenable, set_button=0
  
  widget_control, exportcurrent, set_button=1

; General Options Widgets
  widget_control, smoothbutton, set_button=0 ; smoothing off by default
    widget_control, smoothsubbase, sens=0
  
  widget_control, averagesubbase, sens=0

  widget_control, resbutton, set_button=0 ;auto res by default
    widget_control, resolution, sens=0

  widget_control, thetarangebutton, set_button=1 ; default is to cut by theta
    widget_control, zdirrangeBase, sens=0

  widget_control, erangebase2, sens=0 ; energy limits off

; Data Options Widgets
  widget_control, esaRemoveOptsBase, sens=0 ; off by def
  
  widget_control, sstcontbutton, set_button=1
  
  widget_control, sstcalbutton, set_button=1

  widget_control, ctbutton, set_button=0 ; don't calculate counts
  widget_control, ctoptionsbase, sens=0  ;
  widget_control, ctContButton, set_button=1 ; default to contour instead of mask
  
;Annotation Widgets
  widget_control, xyprecision, set_combobox_select = 4 ;4 sig figs
  widget_control, xyannodefault, set_button=1

  widget_control, zprecision, set_combobox_select = 3 ;3 sig figs
  widget_control, zannodefault, set_button=1

;Plot Widgets
  widget_control, olinebutton, set_button=0 ;contour lines off
    widget_control, numolines, sens=0 

  widget_control, zlogbutton, set_button=1
  widget_control, sundirbutton, set_button=0 ;may require STATE data
  widget_control, bulkbutton, set_button=1
  widget_control, axesbutton, set_button=1
  widget_control, energycircbutton, set_button=1

  widget_control, minmaxbutton, set_button=1 ; autorange by default
    widget_control, minmaxbase2, sens=0

  widget_control, xyminmaxbutton, set_button=1 ; autorange by default
    widget_control, xyminmaxbase2, sens=0
    

;Resize bases and widgets dynamically
;Most resizing (other than labels/spinners) will be done here
  widget_control, orientationlabel, xsize=mgeo.scr_xsize
  widget_control, xslicelabel, xsize=mgeo.scr_xsize  
  widget_control, coordlabel, xsize=mgeo.scr_xsize
  widget_control, rotationlabel, xsize=mgeo.scr_xsize
  widget_control, slicetypelabel, xsize=mgeo.scr_xsize

  widget_control, coord, xsize=dropgeo.scr_xsize
  widget_control, rotation, xsize=dropgeo.scr_xsize

  zgeo = widget_info(olinebutton,/geo)
    widget_control, minmaxbutton, xsize=zgeo.scr_xsize - 3
    widget_control, xyminmaxbutton, xsize=zgeo.scr_xsize - 3

  ogeo = widget_info(averagebutton,/geo)
    widget_control, smoothbutton, xsize=ogeo.scr_xsize
    widget_control, resbutton, xsize=ogeo.scr_xsize
    
  ggeo = widget_info(generate,/geo)
    widget_control, generate, xsize=1.5*ggeo.scr_xsize

  ;main widgets
  factor = 0.98
  geo = widget_info(tlb, /geo)
  widget_control, tlb, xsize = geo.scr_xsize * (1./factor)

 
;Prep slider bar
  slider->setProperty, xsize = geo.scr_xsize * factor * 0.87
  slider->update


;Set time (arbitrary)
  t0 = '2008-02-26/04:54:00'
  t1 = '2008-02-26/04:54:30'
  tr = obj_new('spd_ui_time_range')
  x = tr->SetStartTime(t0)
  y = tr->SetEndTime(t1)
  widget_control, time, set_value=tr  



;Other Preparations
;------------------

  ;Various flags for state structure
  ;  -Make sure to also edit the error catch block in the event handler 
  ;  if changing the following structure:
  flags = {forcereload:1b, olinetouched:0b, restouched:0b}
  

  ;Settings used the previous time data was loaded.  This will be checked
  ;to determine if the data needs to be re-loaded before generating plots.
  ;  -Make sure to also edit the error catch block in the event handler 
  ;  if changing the following structure:
  previous = {probeidx:-1,didx:-1,mag:'',vtype:'',trange:[-1d,-1d], $
              bgnd_remove:-1, bgnd_type:'', bgnd_npoints:-1d, bgnd_scale:-1d, $
              esa_remove:-1, sst_cal:-1, eclipse:-1}
              

  ;State structure
  state = {tlb:tlb, gui_id:gui_id, historywin:historywin, statusbar:statusbar, $
            tlb_title:tlb_title, $
            erangebase:erangebase2, $
            zminmaxBase:minmaxBase2, xyminmaxBase:xyminmaxBase2, $
            thetarangebase:thetarangeBase, zdirrangebase:zdirrangebase, $
            rangebase2d:subrangebase2d, orientationbase:orientationbase, $
;            displacementbase:displacementbase, $
            averagebase:averagebase, $
            slider:slider, $
            rotvel:rotvel, rotmag:rotmag, coordmag:coordmag, $
            velbase:veltype, magbase:magdata, times:ptr_new(), $
            distribution:make_array(4,/ptr), slices:ptr_new(), slices_counts:ptr_new(), $
            previous:previous, flags:flags, last:''}

  thm_ui_slice2d_methodsens, state, buttongeo, 1b
  thm_ui_slice2d_supportsens, state  

  centertlb, tlb
  widget_control, tlb, set_uvalue = state, /no_copy
  widget_control, tlb, /realize

  ;keep windows in X11 from snaping back to 
  ;center during tree widget events 
  if !d.NAME eq 'X' then begin
    widget_control, tlb, xoffset=0, yoffset=0
  endif

  xmanager, 'thm_ui_slice2d', tlb, /no_block

  heap_gc ; clean up memory before exit

  Return

end

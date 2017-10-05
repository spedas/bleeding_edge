pro stel3d_widget_timeslider_event, ev
compile_opt idl2
;  help, ev, /STRUCT
  widget_control, ev.top, GET_UVALUE=val
  widget_control, ev.id, GET_UVALUE=uval
  
  oConf = val['oConf']
  oData = val['oData']
  oTitle = val['oTitle']
  oColorbar = val['oColorbar']
  oScatter = val['oScatter']
  oMagVec = val['oMagVec']
  oVelVec = val['oVelVec']
  oISO1 = val['oISO1']
  oISO2 = val['oISO2']
  oVolume = val['oVolume']
  oWindow = val['oWindow']
  oXYImage = val['oXYImage'] 
  oYZImage = val['oYZImage']
  oXZImage = val['oXZImage']
  oXYContour = val['oXYContour']
  oYZContour = val['oYZContour']
  oXZContour = val['oXZContour']
  tSliderval = val['tSliderval']
 
 ;ToDo: Check 
  oConf->GetProperty, $
    ISO1_LEVEL=iso1_level,     $  ; isosurfaceの表示レベル[追加]
    ISO2_LEVEL=iso2_level,  $
    RANGE=nrange, $
    AXIS_UNIT=axis_unit, $
    UNIT=unit, $
    SLICE_XY=slice_xy, $  ; 2Dスライス面と場所XY面
    SLICE_YZ=slice_yz, $  ; 2Dスライス面と場所YZ面
    SLICE_XZ=slice_xz, $  ; 2Dスライス面と場所ZX面
    MAX_MAG_VEC=max_mag_vec, $
    MAX_VEL_VEC=max_vel_vec, $
    MAG_COORD=mag_coord
    
  ;print, 'Time Slider Event'
  if uval eq 'main:Spinsum' then begin
    ;Set Spin sum
    widget_control, ev.id, GET_VALUE=spinval
    oConf.SetProperty, SPINSUM=string(fix(spinval[0]))
  endif else begin
    ; Set New Time
    widget_control, ev.id, GET_VALUE=sval
    oConf.GetProperty, STEP=step
    srange = widget_info(ev.id, /SLIDER_MIN_MAX)
    
    if sval ge tSliderval+1 then begin
      if sval eq tSliderval+1 then tSliderval = tSliderval + step else tSliderval = sval
    endif else begin
      if sval eq tSliderval-1 then tSliderval = tSliderval - step else tSliderval = sval
    endelse
    if tSliderval lt 0 then tSliderval = 0
    if tSliderval gt srange[1] then tSliderval = srange[1]
    widget_control, ev.id, SET_VALUE=tSliderval
    val['tSliderval'] = tSliderval
    oConf.SetProperty, CURTIME=(oData.GetTimeArray())[tSliderval]
    ; Update Title
    oTitle.SetProperty, STRINGS=(oData.GetTimeArray())[tSliderval] +' : '+axis_unit
    widget_control, widget_info(ev.top, FIND_BY_UNAME='main:STARTTIME'), SET_VALUE=(oData.GetTimeArray())[tSliderval]
    widget_control, widget_info(ev.top, FIND_BY_UNAME='main:ENDTIME'), SET_VALUE=(oData.GetTimeArray())[tSliderval]
  endelse
  
  ; draw update
  stel3d_draw_update, ev.top, val

end
PRO xtplot_options_tplot_event, ev
  compile_opt idl2
  widget_control, ev.top, GET_UVALUE=wid

  code_exit = 0
  code_refresh = 1
  
  case ev.id of
    ;--------------------------------------------------------------------------------------
    ; TAB SWITCH
    ;--------------------------------------------------------------------------------------
    wid.baseTab: code_refresh = 0
    ;--------------------------------------------------------------------------------------
    ; AXES
    ;--------------------------------------------------------------------------------------
    wid.fldTmin: begin
      tlimit, ev.value, wid.str_trange[1]
      str_element,/add,wid,'str_trange',[ev.value,wid.str_trange[1]]
      code_refresh = 0
      end
    wid.fldTmax: begin
      tlimit, wid.str_trange[0], ev.value
      str_element,/add,wid,'str_trange',[wid.str_trange[0],ev.value]
      code_refresh = 0
      end
    wid.btnTfull: begin
      tlimit,/full
      get_timespan,tfull
      str_tfull = time_string(tfull)
      str_element,/add,wid,'str_trange',str_tfull
      widget_control,wid.fldTmin, SET_VALUE=str_tfull[0]
      widget_control,wid.fldTmax, SET_VALUE=str_tfull[1]
      code_refresh = 0
      end
    ;--------------------------------------------------------------------------------------
    ; FINALIZE
    ;--------------------------------------------------------------------------------------
    wid.btnClose: begin
      code_refresh = 0
      code_exit = 1
    end
    else:
  endcase
  
  if code_exit then begin
    widget_control, ev.top, /destroy
  endif else begin
    widget_control, ev.top, SET_UVALUE=wid
    if code_refresh then tplot
  endelse
END

PRO xtplot_options_tplot, group_leader=group_leader
  compile_opt idl2
  common tplot_com1, data_quants, tplot_vars , tplot_configs, current_config , foo1,foo2

  if xregistered('xtplot_options_tplot') ne 0 then return

  str_trange = time_string(tplot_vars.OPTIONS.trange)
  wid = {str_trange:str_trange}
  
  ; widget layout
  base = widget_base(TITLE='Tplot Options',/column)
    
    baseTab = widget_tab(base,/align_center)
      str_element,/add,wid,'baseTab',baseTab
      
      baseTabAxes = widget_base(baseTab,title='tlimit',/COLUMN)
      str_element,/add,wid,'fldTmin',cw_field(baseTabAxes, TITLE = "Tmin", VALUE=str_trange[0],/RETURN_EVENTS)
      str_element,/add,wid,'fldTmax',cw_field(baseTabAxes, TITLE = "Tmax", VALUE=str_trange[1],/RETURN_EVENTS)
      str_element,/add,wid,'btnTfull', widget_button(baseTabAxes,VALUE='full', TOOLTIP='Reset to full time range')
      
    baseExit = widget_base(base,/ROW)
      str_element,/add,wid,'btnClose',widget_button(baseExit,VALUE=' Close ')    
    
  widget_control, base, /REALIZE
  scr = get_screen_size()
  geo = widget_info(base,/geometry)
  widget_control, base, SET_UVALUE=wid, XOFFSET=scr[0]*0.5-geo.xsize*0.5, YOFFSET=scr[1]*0.5-geo.ysize*0.5
  
  xmanager, 'xtplot_options_tplot', base,GROUP_LEADER=group_leader
END





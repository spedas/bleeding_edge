; PREFERENCES WIDGET
; 
; First, a module (DATA, SITL or ORBIT) tries to uses default values of
; state.PREF.
;   
PRO eva_pref_event, event
  widget_control, event.top, GET_UVALUE=wid
    
  exitcode=0
  case event.id of
    wid.btnSave:  begin
      
      widget_control, wid.pfGen,                          GET_VALUE=pfState
      mms_config_write, pfState.pref
      cpwidth = pfState.pref.EVA_CPWIDTH 
      basepos = pfState.pref.EVA_BASEPOS
      ; There is no corresponding module for the Gen pref. But the values
      ; are passed on to eva_sitl and eva_data
      
      widget_control, wid.pfSitl,                          GET_VALUE=pfState
      str_element,/add,pfState,'PREF.EVA_CPWIDTH',cpwidth
      str_element,/add,pfState,'PREF.EVA_BASEPOS',basepos
      widget_control, widget_info(wid.gl,find='eva_sitl'), SET_VALUE=pfState.pref
      mms_config_write, pfState.pref
      
      widget_control, wid.pfData,                          GET_VALUE=pfState
      str_element,/add,pfState,'PREF.EVA_CPWIDTH',cpwidth
      str_element,/add,pfState,'PREF.EVA_BASEPOS',basepos
      widget_control, widget_info(wid.gl,find='eva_data'), SET_VALUE=pfState.pref
      mms_config_write, pfState.pref

      
      exitcode=1
      end
    wid.btnCancel:begin
      exitcode=1
      end
    else:
  endcase

  widget_control, event.top, SET_UVALUE=wid
  if exitcode then widget_control, event.top, /destroy
END


PRO eva_pref, GROUP_LEADER=group_leader
  xsize = 400
  ysize = 480
  xbtnsize = 80
  dimscr = get_screen_size()
  
  ; wid
  wid = {gl: group_leader}
  
  ; Base
  base = widget_base(TITLE='Preferences',$
    XSIZE=xsize,XOFFSET=dimscr[0]*0.5-xsize*0.5,YOFFSET=dimscr[1]*0.5-ysize*0.5,/column)
    
  ; Tabs
  baseTab = widget_tab(base, xsize=xsize)
    str_element,/add,wid,'pfData', eva_data_pref(baseTab,xsize=xsize,group_leader=group_leader); DATA MODULE
    str_element,/add,wid,'pfSitl', eva_sitl_pref(baseTab,xsize=xsize,group_leader=group_leader); SITL MODULE
    str_element,/add,wid,'pfSitl2', eva_sitl_pref2(baseTab,xsize=xsize,group_leader=group_leader); SITL MODULE
    str_element,/add,wid,'pfGen', eva_pref_gen(baseTab,xsize=xsize,group_leader=group_leader); GENERAL MODULE
    
;    str_element,/add,wid,'pfOrbit',eva_orbit_pref(baseTab,xsize=xsize,group_leader=group_leader); ORBIT MODULE
    
  
  ; Save & Cancel
  baseButton = widget_base(base,/row,/align_center)
  str_element,/add,wid,'btnSave', widget_button(baseButton,VALUE='Save',XSIZE=xbtnsize)
  str_element,/add,wid,'btnCancel', widget_button(baseButton,VALUE='Cancel',XSIZE=xbtnsize)
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid
  xmanager, 'eva_pref', base,  /NO_BLOCK, GROUP_LEADER=group_leader
  
END

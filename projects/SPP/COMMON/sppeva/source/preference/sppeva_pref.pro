; PREFERENCES WIDGET
;
PRO sppeva_pref_event, event
  widget_control, event.top, GET_UVALUE=wid

  exitcode=0
  case event.id of
    wid.btnSave:  begin
      ;--------------------------------
      ; SAVE CHANGES IN THE "USER" TAB
      ;--------------------------------
      widget_control, wid.pfUser, GET_VALUE=pfwid
      sppeva_pref_import, 'USER', pfwid.USER_COPY
      
      ;--------------------------------
      ; SAVE CHANGES IN THE "FIELD" TAB
      ;--------------------------------
      widget_control, wid.pfFild, GET_VALUE=pfwid
      sppeva_pref_import, 'FILD', pfwid.FILD_COPY
 
      ;--------------------------------
      ; SAVE CHANGES IN THE "GENERAL" TAB
      ;--------------------------------
      widget_control, wid.pfGene, GET_VALUE=pfwid
      sppeva_pref_import, 'GENE', pfwid.GENE_COPY
      
      ;---------------
      ; SAV
      ;---------------
      sppeva_user_values = !SPPEVA.USER
      sppeva_gene_values = !SPPEVA.GENE
      sppeva_fild_values = !SPPEVA.FILD
      save, sppeva_user_values, sppeva_gene_values, sppeva_fild_values, $
        filename='sppeva_setting.sav'
      if(strlen(!SPPEVA.GENE.ROOT_DATA_DIR) gt 0) then begin
        setenv,'ROOT_DATA_DIR='+!SPPEVA.GENE.ROOT_DATA_DIR
      endif
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


PRO sppeva_pref, GROUP_LEADER=group_leader
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
  str_element,/add,wid,'pfUser', sppeva_pref_user(baseTab,xsize=xsize,group_leader=group_leader)
  str_element,/add,wid,'pfGene',  sppeva_pref_gene(baseTab,xsize=xsize,group_leader=group_leader)
  str_element,/add,wid,'pfFild',  sppeva_pref_fild(baseTab,xsize=xsize,group_leader=group_leader)

  ; Save & Cancel
  lbl1 = widget_label(base,VALUE='The settings are saved locally in "sppeva_setting.sav".')
  baseButton = widget_base(base,/row,/align_center)
  str_element,/add,wid,'btnSave', widget_button(baseButton,VALUE='Save',XSIZE=xbtnsize)
  str_element,/add,wid,'btnCancel', widget_button(baseButton,VALUE='Cancel',XSIZE=xbtnsize)
  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid
  xmanager, 'sppeva_pref', base,  /NO_BLOCK, GROUP_LEADER=group_leader
END

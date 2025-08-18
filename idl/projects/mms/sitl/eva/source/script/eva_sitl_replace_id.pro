
PRO eva_sitl_replace_id_event, event
  @tplot_com
  compile_opt idl2
  widget_control, event.top, GET_UVALUE=wid

  codeexit = 0
  case event.id of
    wid.drpOld:begin
      print, wid.listIDuniq
      str_element,/add,wid,'target',wid.listIDuniq[event.INDEX]
      print, wid.listIDuniq[event.INDEX], ' is selected.'
      end
    wid.fldNew:begin
      widget_control, event.id, GET_VALUE=strNewID
      str_element,/add,wid,'strNewID',strNewID[0]
      end
    wid.btnValidate:begin
      val = mms_load_fom_validation()
      get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
      get_data,'mms_soca_fomstr',data=Dorg, lim=lorg,dl=dlorg
      mms_convert_fom_unix2tai, lmod.unix_FOMStr_mod, tai_FOMstr_mod; Modified FOM to be checked
      mms_convert_fom_unix2tai, lorg.unix_FOMStr_org, tai_FOMstr_org; Original FOM for reference
      header = eva_sitl_text_selection(lmod.unix_FOMstr_mod)
      vcase = 0
      r = eva_sitl_validate(tai_FOMstr_mod, tai_FOMstr_org, vcase=vcase, header=header, valstruct=val)
      end
    wid.btnReplace:begin
      get_data,'mms_stlm_fomstr',data=Dmod,lim=lmod,dl=dlmod
      sourceID = lmod.UNIX_FOMSTR_MOD.SOURCEID
      idx = where(strmatch(sourceID,wid.TARGET), ct)
      if ct gt 0 then begin
        sourceID[idx] = wid.strNewID
        str_element,/add,lmod,'UNIX_FOMSTR_MOD.SOURCEID',sourceID
        store_data,'mms_stlm_fomstr',data=Dmod,lim=lmod,dl=dlmod
      endif
      end
    wid.btnRevert:begin
      get_data,'mms_stlm_fomstr',data=Dmod,lim=lmod,dl=dlmod
      store_data,'mms_stlm_fomstr',data=Dmod,lim=wid.lmodorg,dl=dlmod
      end
    wid.btnClose:codeexit=1
    else:
  endcase

  if codeexit then begin
    widget_control, event.top,/destroy
  endif else begin
    widget_control, event.top, SET_UVALUE=wid
  endelse
END

PRO eva_sitl_replace_id

  ;-------------------
  ; INITIALIZE
  ;-------------------
  tn=tnames('mms_stlm_fomstr',ct)
  if ct eq 0 then begin
    msg = 'FOM structure not found. Please load some data first.'
    result = dialog_message(msg,/center)
    return
  endif
  tn=tnames('mms_soca_fomstr',ct)
  if ct eq 0 then begin
    msg = 'FOM structure not found. Please load some data first.'
    result = dialog_message(msg,/center)
    return
  endif
  get_data,'mms_stlm_fomstr',data=Dmod, lim=lmod,dl=dlmod
  s = lmod.unix_FOMstr_mod
  sourceID = s.SOURCEID
  listIDuniq = sourceID[UNIQ(sourceID, SORT(sourceID))]
  wid = {listIDuniq:listIDuniq, lmodorg:lmod, strNewID:eva_sourceid(), target:listIDuniq[0]}

  ;-----------------
  ; WIDGET BASE
  ;-----------------  
  xsize = 250
  ysize = 280

  scr_dim    = get_screen_size()
  xoffset = scr_dim[0]*0.5 - xsize*0.5 > 0.;-650.-286-50. > 0.
  yoffset = scr_dim[1]*0.5 - ysize*0.5

  base = widget_base(TITLE = 'REPLACE IDs',/COLUMN,xoffset=xoffset,yoffset=yoffset)
  str_element,/add,wid,'base',base
  
  str_element,/add,wid,'drpOld',widget_droplist(base,VALUE=listIDuniq,TITLE='Replace ')
  str_element,/add,wid,'fldNew',cw_field(base,VALUE=wid.strNewID,TITLE='with ',/ALL_EVENTS,XSIZE=20)

  baseButtons = widget_base(base,space=0,ypad=0,/ROW)
    str_element,/add,wid,'btnValidate',widget_button(baseButtons,VALUE=' Validate ')
    str_element,/add,wid,'btnReplace',widget_button(baseButtons,VALUE=' Replace ')
    lblSpace = widget_label(baseButtons,VALUE='   ')
    str_element,/add,wid,'btnRevert',widget_button(baseButtons,VALUE=' Revert ')
  str_element,/add,wid,'btnClose',widget_button(base,VALUE=' Close ')

  widget_control, base, /REALIZE
  widget_control, base, SET_UVALUE=wid

  xmanager, 'eva_sitl_replace_id', base, /no_block;, GROUP_LEADER=group_leader
END

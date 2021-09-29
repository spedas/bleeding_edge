
PRO sppeva_pref_gene_set_value, id, value ;In this case, value = activate
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ;eva_sitl_update_board, wid, value
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
END

FUNCTION sppeva_pref_gene_get_value, id
  compile_opt idl2
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY
  ;-----
  ret = wid
  ;-----
  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  return, ret
END

FUNCTION sppeva_pref_gene_event, event
  compile_opt idl2

  catch, error_status
  if error_status ne 0 then begin
    eva_error_message, error_status
    catch, /cancel
    return, { ID:event.handler, TOP:event.top, HANDLER:0L }
  endif

  parent=event.handler
  stash = WIDGET_INFO(parent, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=wid, /NO_COPY


  ;-----
  case event.id of
    wid.SPLITSIZE:begin
      widget_control, event.id, GET_VALUE=strNew
      wid.gene_copy.SPLIT_SIZE_IN_SEC = strNew
      end
    wid.ROOT_DATA_DIR:begin
      widget_control, event.id, GET_VALUE=strRootDir
      wid.gene_copy.ROOT_DATA_DIR = strRootDir
    end
    else:
  endcase
  ;-----

  WIDGET_CONTROL, stash, SET_UVALUE=wid, /NO_COPY
  RETURN, { ID:parent, TOP:event.top, HANDLER:0L }
END

;-----------------------------------------------------------------------------

FUNCTION sppeva_pref_gene, parent, GROUP_LEADER=group_leader, $
  UVALUE = uval, UNAME = uname, TAB_MODE = tab_mode, TITLE=title,XSIZE = xsize, YSIZE = ysize

  IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Must specify a parent for sppeva_pref_gen'
  IF NOT (KEYWORD_SET(uval))  THEN uval = 0
  IF NOT (KEYWORD_SET(uname))  THEN uname = 'sppeva_pref_gen'
  if not (keyword_set(title)) then title='  GENERAL  '

  wid = {gene_copy:!SPPEVA.GENE}
  
  ; ----- WIDGET LAYOUT -----
  geo = widget_info(parent,/geometry)
  if n_elements(xsize) eq 0 then xsize = geo.xsize
  base = WIDGET_BASE(parent, UVALUE = uval, UNAME = uname, TITLE=title,$
    EVENT_FUNC = "sppeva_pref_gene_event", $
    FUNC_GET_VALUE = "sppeva_pref_gene_get_value", $
    PRO_SET_VALUE = "sppeva_pref_gene_set_value",/column,$
    XSIZE = xsize, YSIZE = ysize,sensitive=1,/base_align_left)
  str_element,/add,wid,'base',base
  lbl2 = widget_label(base,VALUE=' ')
  str_element,/add,wid,'splitsize', cw_field(base,VALUE=!SPPEVA.GENE.SPLIT_SIZE_IN_SEC, TITLE='Split size in sec (default:600)',/ALL_EVENTS,xsize=20)
  lbl5 = widget_label(base,VALUE='--------------')
  lbl4 = widget_label(base,VALUE='The settings below can be configured in an idl_startup file')
  lbl3 = widget_label(base,VALUE='as well. The settings in the idl_startup file will override')
  lbl2 = widget_label(base,VALUE='the settings below.')
  str_element,/add,wid,'ROOT_DATA_DIR',cw_field(base,VALUE=!SPPEVA.GENE.ROOT_DATA_DIR,TITLE='ROOT_DATA_DIR',/ALL_EVENTS,xsize=40)
  
  WIDGET_CONTROL, WIDGET_INFO(base, /CHILD), SET_UVALUE=wid, /NO_COPY
  RETURN, base
END

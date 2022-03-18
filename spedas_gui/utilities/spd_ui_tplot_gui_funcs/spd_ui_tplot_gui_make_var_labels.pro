;+
;NAME:
;  spd_ui_tplot_gui_make_var_labels
;
;PURPOSE:
;  Integrates information from various sources to properly set variable labels in a tplot-like fashion
;
;CALLING SEQUENCE:
; spd_ui_tplot_gui_var_labels,panel,page,var_label=var_label,allnames=allnames,newnames=newnames
;
;INPUT:
;  panel: last panel in the label
;  page: page settings for the active window
;
;KEYWORDS:
;  varnames:  varnames to be added
;  allnames: list of names as added
;  newnames: names of variables in allnames after potential user rename
;
;OUTPUT:
;  mutates panel object
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2022-03-16 21:13:07 -0700 (Wed, 16 Mar 2022) $
;$LastChangedRevision: 30683 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_tplot_gui_funcs/spd_ui_tplot_gui_make_var_labels.pro $
;-------------------------------------------------------------------------------

function spd_ui_tplot_gui_make_var_labels_ytitle, dataObj
  ; Return the ytitle, if it exists
  compile_opt idl2

  result = ''
  CATCH, Error_status

  ;This statement begins the error handler:
  IF Error_status NE 0 THEN BEGIN
    CATCH, /CANCEL
    return, ''
  ENDIF

  dataObj->getProperty, DLIMITPTR=dlptr
  dl = *dlptr
  tdl = tag_names(dl)
  idx0 = WHERE(STRMATCH(tdl, 'ytitle', /FOLD_CASE), count)
  if count ge 1 then begin
    result = dl.ytitle
  endif

  return, result
end

;note var labels must be string type and cannot be pseudo variables
pro spd_ui_tplot_gui_make_var_labels,panel,page,varnames=varnames,allnames=allnames,newnames=newnames

  compile_opt idl2

  if ~is_struct(varnames) then begin
    return
  endif

  panel->getProperty,variables=variables
  if ~obj_valid(variables) || ~obj_isa(variables,'idl_container') then begin
    variables = obj_new('IDL_Container')
    panel->setProperty,variables=variables
  endif

  !spedas.windowstorage->getProperty,template=template
  if obj_Valid(template) then begin
    template->getProperty,variable=variableTemplate
  endif

  n = csvector(varnames,/l)

  for i = 0,n-1 do begin

    ;use data structure to avoid need to create temporary tplot variables
    vars = csvector(i,varnames,/r)

    for j = 0,n_elements(vars)-1 do begin

      ;account for possible name change during verification
      idx = where(vars[j] eq allnames,c)

      if c ne 1 then begin
        dprint,"Unexpected error while processing variable list"
        return
      endif

      dataGroup = !spedas.loadedData->getGroup(newnames[idx[0]])
      if ~obj_valid(dataGroup) then continue
      dataObjs = dataGroup->getDataObjects()

      if ~obj_valid(dataObjs[0]) then continue

      for k = 0,n_elements(dataObjs)-1 do begin
        dataObj = dataObjs[k]
        dataObj->getProperty,indepname=indepname,timename=timename,isTime=isTime,name=dependname
        if keyword_set(indepname) && !spedas.loadedData->isChild(indepname) then begin
          controlname = indepname
        endif else begin
          controlname = timename
        endelse

        if obj_valid(page) then begin
          page->getProperty,variables=varText
          varText = varText->copy()
        endif else begin
          varText = obj_new('spd_ui_text')
        endelse

        ; Use ytitle for text
        ytitle = spd_ui_tplot_gui_make_var_labels_ytitle(dataObj)
        if ytitle eq '' then begin
          varText->setProperty,value=dependname+' :'
        endif else begin
          varText->setProperty,value=ytitle
        endelse

        if obj_valid(variableTemplate) then begin
          newvarobj = variableTemplate->copy()
        endif else begin
          newvarobj = obj_new('spd_ui_variable')
        endelse

        newvarobj->setProperty,controlname=controlname,fieldname=dependname,text=varText,isTime=isTime

        variables->add,newvarobj
      endfor
    endfor
  endfor
end

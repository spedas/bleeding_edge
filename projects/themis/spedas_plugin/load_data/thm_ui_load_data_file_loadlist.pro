;+ 
;NAME:
; thm_ui_load_data_file_loadlist.pro
;
;PURPOSE:
; ROUTINE IS DEPRECATED.  WAS MAINTAINING COPIES OF SELECTION THAT WERE ALREADY MAINTAINED ELSEWHERE.
;
; Controls selection of loaded data from "Loaded Data" list.  Called by
; thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_loadlist, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;HISTORY:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-09 14:56:06 -0700 (Thu, 09 Apr 2015) $
;$LastChangedRevision: 17278 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_loadlist.pro $
;-
pro thm_ui_load_data_file_loadlist, state, event

  Compile_Opt idl2, hidden

  widget_control,event.id,get_value=value
  val = value->getValue()
  nval = n_elements(val)
  if size(val,/type) eq 10 then begin
    data_sel = ''
    for i = 0, nval-1 do begin
      data_sel = [data_sel, (*val[i]).groupname]
      
      ; create message for timerange of single data quantity
      if nval eq 1 then begin
        
        dataNames =  state.loadedData->getall(/parent, /times)
        data_sel_ind = where(data_sel[1] eq dataNames)
        data_sel_t0 = dataNames[data_sel_ind + 1]
        data_sel_t1 = dataNames[data_sel_ind + 2]
        
        state.statusText->Update, 'Time range for ' + data_sel[1] + ': ' + $
                            data_sel_t0 + ' to ' + data_sel_t1
      
      endif ;else state.statusText->Update,''
    endfor
    
    if ptr_valid(state.data_sel) then ptr_free, state.data_sel
    state.data_sel = ptr_new(data_sel)
  endif

;; Pre-tree widget code  
;  if event.clicks eq 1 then begin
;    pindex = widget_info(state.loadlist, /list_select)
;    pindex = pindex+1
;    val_data = state.loadedData->getall()
;    newnames = val_data[pindex-1]
;    if ptr_valid(state.data_sel) then ptr_free, state.data_sel
;    state.data_sel = ptr_new(newnames)
;    ;history_ext = spd_ui_multichoice_history('varnames = ', newnames)
;;    h = spd_ui_multichoice_history('varnames = ', newnames)
;;    state.historyWin->Update, 'LOAD DATA: ' + h
;  endif else begin
;    pindex = widget_info(state.loadlist, /list_select)
;    pindex = pindex+1
;    val_data = state.loadeddata->getall()
;    if ptr_valid(state.data_sel) then ptr_free, state.data_sel
;    state.data_sel = ptr_new(newnames)
;  endelse
  RETURN
END

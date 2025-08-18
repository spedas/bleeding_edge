;+ 
;NAME:
; thm_ui_load_data_file_del.pro
;
;PURPOSE:
; Controls deleting of loaded data from "Loaded Data" list.  Called by
; thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_del, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-09 13:39:19 -0700 (Thu, 09 Apr 2015) $
;$LastChangedRevision: 17268 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_del.pro $
;-
pro thm_ui_load_data_file_del, state

  Compile_Opt idl2, hidden
  
  sel = state.loadList->getValue()

  if ptr_valid(sel[0]) then begin
    result = dialog_message('Are you sure you want to delete the selected data from the GUI?', $
        /question, /center, title='Load Data: Delete GUI data?')
    
    if result eq 'Yes' then begin
        
        for i=0, n_elements(sel)-1 do begin
          if ~state.loadedData->remove((*sel[i]).groupname) then begin
            msg = "Problem deleting : " + (*sel[i]).groupname
            state.statusText->Update, msg
            state.historyWin->Update, 'LOAD DATA: ' + msg
            return
          endif else begin
            state.callSequence->adddeletecall,(*sel[i]).groupname
          endelse
        endfor
        msg = 'Selected data deleted.'
        state.statusText->Update, msg
        state.historyWin->Update, 'LOAD DATA: ' + msg
    endif
  endif else begin
    msg='No data selected. Not deleting anything.'
    state.statusText->Update, msg
    state.historyWin->Update, 'LOAD DATA: ' + msg
  endelse
 
  RETURN
END

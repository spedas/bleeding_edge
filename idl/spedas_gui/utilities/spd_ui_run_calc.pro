;+ 
;NAME:
; spd_ui_run_calc
;
;PURPOSE:
; Function that interprets program for spd_ui_calculate
;
;CALLING SEQUENCE:
; spd_ui_run_calc,programtext,loadeddata,historywin,statusbar,error=error
;
;INPUT:
; programText: array of strings, text of program
; loadeddata: the loaded data object
; historywin: the historywin object
; statusbar: the statusbar object
;
;OUTPUT:
; error=error: set to named variable, will be 0 on success, will be set to error struct returned by calc.pro on failure
;
;HISTORY:
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-05-27 16:29:10 -0700 (Tue, 27 May 2014) $
;$LastChangedRevision: 15236 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_run_calc.pro $
;
;---------------------------------------------------------------------------------


pro spd_ui_run_calc,programtext,loadeddata,historywin,statusbar,gui_id,error=error,last_line=last_line,replay=replay,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,calc_prompt_obj=calc_prompt_obj

  compile_opt hidden,idl2
  
  pi = !DPI
  e = exp(1)
  
  error = 0
  last_line = -1  ;return last completed error free line so that we can include successfully completed lines in the GUI document
   
  ;list of names so that we can delete any newly created names
  tn_before = tnames()
  
  for i = 0,n_elements(programtext)-1 do begin
  
    ;widget_control,state.programLabel,set_value="Calculating line: " + strtrim(string(i),2)
    
    statusBar->update,'Calculating line: ' + strtrim(string(i),2)
    historyWin->update,'Calculating line: ' + strtrim(string(i),2)
    
    if keyword_set(programtext[i]) then begin
      calc,programtext[i],gui_data_obj=loadedData,error=error,historywin=historywin,statusbar=statusbar,gui_id=gui_id,overwrite_selections=overwrite_selections,overwrite_count=overwrite_count,replay=replay,calc_prompt_obj=calc_prompt_obj
    endif
    
    if keyword_set(error) then begin    
      break  
    endif
 
    last_line = i
  
  endfor

 
  ;list of names after processing
  spd_ui_cleanup_tplot,tn_before,del_vars=to_delete
  if to_delete[0] ne '' then begin
    store_data,to_delete,/delete
  endif
  
end

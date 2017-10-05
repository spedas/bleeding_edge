;+
;
;  Name: SPD_UI_LOAD_SPEDAS_CDF
;  
;  Purpose: Loads data from a CDF chosen by user. Note that only CDFs that conform to SPEDAS standards can be opened. 
;  CDFs that do not conform may produce unhelpful error messages. 
;  
;  Inputs: The info structure from the main gui
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_load_spedas_cdf.pro $
;-
pro spd_ui_load_spedas_cdf,info

  compile_opt idl2
  
  catch,Error_status

  if (Error_status NE 0) then begin
    statusmsg = !ERROR_STATE.MSG
    result=dialog_message('Error attempting to load CDF. File may not conform to SPEDAS standards. See History for more details.', $
                            /info,/center, title='Load SPEDAS CDF')
    info.historywin->Update,'Error attempting to load CDF: '
    info.historywin->Update,statusmsg
    catch,/cancel
    return
  endif

  if info.marking ne 0 || info.rubberbanding ne 0 then begin
    return
  endif
  
  existing_tvar = tnames()
  
  info.ctrl = 0
 
  fileName = Dialog_Pickfile(Title='Load SPEDAS CDF', $
    Filter='*.cdf', Dialog_Parent=info.master,file=filestring,path=path,/must_exist,/fix_filter)
  IF(Is_String(fileName)) THEN BEGIN
    init_time=systime(/sec)
    cdf2tplot, file=fileName , get_support_data=1
    tplotvars = tnames(create_time=create_times)
    new_vars_ind = where(create_times gt init_time, n_new_vars_ind)
    if n_new_vars_ind gt 0 then begin
      tplot_gui, tplotvars[new_vars_ind], /no_draw
      
     ; delete any new tplot variables (but not ones that overwrote existing variables)
     if n_elements(existing_tvar) eq 1 then existing_tvar = [existing_tvar]
     if n_elements(tplotvars) eq 1 then tplotvars = [tplotvars]
     tvar_to_delete = ssl_set_complement(existing_tvar, tplotvars)
     store_data, delete=tvar_to_delete
    endif else begin
      statusmsg = 'Unable to load data from file '+fileName+'. File may not conform to SPEDAS standards.'
      result=dialog_message(statusmsg, $
                            /info,/center, title='Load SPEDAS CDF')
      info.statusBar->Update, statusmsg
      info.historywin->Update,statusmsg
    endelse
  ENDIF ELSE BEGIN
    info.statusBar->Update, 'Invalid Filename'
  ENDELSE
  
end

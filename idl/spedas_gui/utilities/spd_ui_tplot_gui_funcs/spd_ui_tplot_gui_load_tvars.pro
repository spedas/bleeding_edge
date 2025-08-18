;+ 
;NAME:  
;  spd_ui_tplot_gui_load_tvars
;  
;PURPOSE:
;  Verifies input tplot variables for tplot_gui.  This is actually the trickiest part of the whole process
;  
;CALLING SEQUENCE:
; spd_ui_tplot_gui_validate_tvars,in_names,out_names=out_names
;  
;INPUT:
;  in_names:  Input names supplied by user.
;  
;Keywords:
;(Input):
;  no_verify: value of the no_verify keyword supplied by user(optional)
;  gui_id: Use a different widget_id from the !spedas.guiID (optional)
;(Output):
;  out_names: csvector containing lists of validated names for plots
;  all_names: All the non-pseudo variables that will be used for verification
;  limits: csvector containing variable specific settings, somewhat collated in the case of pseudo variables, 
;  dlimits: csvector containing defaultish variable specific settings, somewhat collated in the case of pseudo variables
;  
;
;SEE ALSO:
;  ssl_general/misc/csvector.pro
;  (Used to generate linked list, so that temporary tplot variables aren't needed)
;
;  06/06/2011: lphilpott, added option for user to rename variable before loading if a variable with that name already exists.
;  11/04/2011: lphilpott, moved spd_ui_tplot_gui_load_tvars_with_new_name to spd_ui_load_tvars_with_new_name - now it is also used by spd_ui_manage_data.
;                         Stopped it from looping when you click 'X' in the rename prompt dialogue.
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-28 13:17:10 -0700 (Tue, 28 Apr 2015) $
;$LastChangedRevision: 17440 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_tplot_gui_funcs/spd_ui_tplot_gui_load_tvars.pro $
;--------------------------------------------------------------------------------

; Helper procedure to load a variable with a new user specified name to avoid conflict with an existing variable
; 'name' should be a valid tplot variable name that is already in use
; 'newname' is the name to load the variable under instead
; fail = 0 if variable is successfully loaded under new name
;pro spd_ui_tplot_gui_load_tvars_with_new_name, name, newname=newname, fail=fail
;
;  compile_opt idl2, hidden
;  fail = 1
;  guiNames = !spedas.loadedData->GetAll(/Parent)
;  tempint = 0
;  tempname = name+'_temp_'+strtrim(systime(/julian),1)+'_'+strtrim(tempint,1)
;  while in_set(tempname, guiNames) do begin
;    tempint ++
;    tempname = name +'_temp_'+strtrim(systime(/julian),1)+'_'+strtrim(tempint,1)
;  endwhile
;  ; Rename existing variable with temp name
;  !spedas.loadedData->SetDataInfo,name,newname=tempname,fail=fail
;  if fail then return
;  ; Load new variable
;  if  ~!spedas.loadedData->add(name) then begin
;    dprint,"Problem adding: " + varsToRename[i] + " to GUI"
;  endif
;  ; Rename new variable with user specified name
;  !spedas.loadedData->SetDataInfo,name,newname=newname,fail=fail
;  if fail then return
;  ; Rename original variable with its original name
;  !spedas.loadedData->SetDataInfo,tempname, newname=name, fail=fail
;  
;end
;NB: this routine is very similar to spd_ui_manage_data_import (in spd_ui_manage_data). If you 
; need to fix a bug here you may need to fix it there too.
pro spd_ui_tplot_gui_load_tvars,in_names,no_verify=no_verify,out_names=out_names,all_names=all_names,gui_id=gui_id

  compile_opt idl2
    
  ;just in case
  undefine,out_names
  undefine,all_names
  undefine,limits
  undefine,dlimits
  
  if undefined(gui_id) then begin
    gui_id = !spedas.guiId
  endif
  
  ; make sure indexes are converted array of tplot variable names
  varnames = tnames(in_names,nd,/all)
  
  if nd eq 0 then begin
     return
  endif
    
  if keyword_set(no_verify) then begin
    clobber = 'yestoall'
  endif else begin
    clobber = ''
  endelse
    
 
  ; add tplot variables to loadedData object
  for i=0L,nd-1 do begin
  
    ; get pre-existing gui variable names
    guiNames = !spedas.loadedData->GetAll(/Parent)
    if size(guiNames, /type) ne 7 then guiNames=''
  
    ; check if pseudovariable
    get_data, varnames[i], data=d, dlimits=pseudo_dl, limits=pseudo_l
    if ~keyword_set(d) then begin
          ok = error_message('The variable '+varnames[i]+' does not appear to contain any data. Variable not loaded.', $
                    /center, title='Error in Load TVars')
          continue
    endif
    dSize = size(d, /type)

    if dSize eq 7 then begin
    ;load tplot pseudovariable
    
      ;extract_tags, pseudo_dl, pseudo_l
      
      subNames = tnames(d, sub_nd, ind=sub_ind, /all)
      undefine,valid_sub
 
      for j=0L,sub_nd-1 do begin
      ; load each component of pseudovariable
        ;make sure dlimits from pseudovar are inherited by component variables
        get_data, subNames[j], dlimits=sub_dl, limits=sub_l,data=d
        extract_tags, sub_dl, pseudo_dl
        extract_tags, sub_l, pseudo_l
        dSizeSub = size(d, /type)
        if dSizeSub eq 7 then begin
          ok = error_message('It looks like you attempted to load a pseudovariable containing a pseudovariable. Unfortunately that case is not handled by this procedure.', $
                    /center, title='Error in Load TVars')
          continue
        endif
        subvarexists = in_set(subNames[j], guiNames)
        if subvarexists then begin
          if (clobber ne 'yestoall' AND clobber ne 'notoall') then begin
            prompttext = 'The variable ' + strupcase(subNames[j]) + ' already exists in the GUI.  Do you want to ' + $
              'overwrite it with the new variable?'+ssl_newline()+' '+ssl_newline()+$
              'Click "No" to load the variable ' + strupcase(subNames[j]) + ' under a new name.' + ssl_newline()+$
              'Click "Cancel" to stop the load and continue with the existing '+ strupcase(subNames[j]) +'.'
            clobber = spd_ui_prompt_widget(gui_id,obj_new(),!spedas.historyWin,promptText=promptText,$
              /no,/yes,/allno,/allyes,/cancel, title='LOAD DATA: Variable already exists.', defaultvalue='cancel', frame_attr=8)
         
          endif 
          if clobber eq 'yes' OR clobber eq 'yestoall' then begin
            h = 'TPLOT_GUI: ' + strupcase(subNames[j]) + ' will be overwritten.'
            !spedas.historyWin->Update, h
            ;tmp=!spedas.loadedData->Remove(newname) I'm not sure what this line was for.
          endif
          if (clobber eq 'notoall') then begin
            subVarsToRename = array_concat(subNames[j], subVarsToRename)
          endif else if (clobber eq 'no') then begin
            spd_ui_rename_variable,gui_id, subNames[j], !spedas.loadedData, $
                       !spedas.windowStorage, !spedas.historywin, $
                       success=success,newnames=newname
            if ~success then begin
              dprint,'Data rename and load canceled.'
              !spedas.historyWin->update,'Data rename and load canceled.'
              continue
            endif else begin
              spd_ui_load_tvars_with_new_name, subNames[j], newname=newname, fail=fail
              if fail then begin
                ok = error_message('Error renaming variable ' + subNames[j], $
                    /center, title='Error in Load TVars',traceback=0)
                continue
              endif
              subNames[j]=newname
            endelse
          endif else if (clobber eq 'cancel') then begin
            h = 'LOAD DATA: ' + strupcase(subNames[j]) + $
                ' not loaded to prevent overwrite of existing data.'
            !spedas.historyWin->Update, h
          endif else if ~!spedas.loadedData->addData(subNames[j],d,limit=sub_l,dlimit=sub_dl) then begin
            dprint,"Problem adding: " + subNames[j] + " to GUI" 
            continue       
          endif
        endif else if ~!spedas.loadedData->addData(subNames[j],d,limit=sub_l,dlimit=sub_dl) then begin
            dprint,"Problem adding: " + subNames[j] + " to GUI"      
            continue  
        endif
        if (clobber ne 'notoall') && (clobber ne 'cancel') then begin
          valid_sub = array_concat(subNames[j],valid_sub)   
        endif
      endfor
      ; Handle renaming of any pseudo var components.
      if n_elements(subVarsToRename) ne 0 then begin
        spd_ui_rename_variable,gui_id, subVarsToRename, !spedas.loadedData, $
                       !spedas.windowStorage, !spedas.historywin, $
                       success=success,newnames=newsubnames
        if ~success then begin
          dprint,'Data rename and load canceled.'
          !spedas.historyWin->update,'Data rename and load canceled.'
        endif else begin
          for i=0L,n_elements(subVarsToRename)-1 do begin
            get_data, subVarsToRename[i], dlimits=sub_dl, limits=sub_l,data=d
            extract_tags, sub_dl, pseudo_dl
            extract_tags, sub_l, pseudo_l
            spd_ui_load_tvars_with_new_name, subVarsToRename[i], newname=newsubnames[i], fail=fail
            if fail then begin
              ok = error_message('Error renaming variable ' + subVarsToRename[i], $
                    /center, title='Error in Load TVars',traceback=0)
              continue
            endif else if ~!spedas.loadedData->addData(newsubnames[i],d,limit=sub_l,dlimit=sub_dl) then begin; Not sure if this is necessary, but for consistency with other cases above it is included.
              dprint,"Problem adding: " + newsubnames[i] + "data to GUI" 
              continue       
            endif
            subVarsToRename[i]=newsubnames[i]
            valid_sub = array_concat(subVarsToRename[i],valid_sub) 
          endfor
        endelse
      endif
      if n_elements(valid_sub) gt 0 then begin
        all_names = array_concat(valid_sub,all_names)
        out_names = csvector(valid_sub,out_names)        
      endif
  
    endif else begin
    ; load standard tplot variable
      varexists = in_set(varnames[i], guiNames)
      if varexists then begin
        if (clobber ne 'yestoall' AND clobber ne 'notoall') then begin
          prompttext = 'The variable ' + strupcase(varnames[i]) + ' already exists in the GUI. Do you want to ' + $
            'overwrite it with the new variable?'+ssl_newline()+' '+ssl_newline()+$
            'Click "No" to load the variable ' + strupcase(varnames[i]) + ' under a new name.' + ssl_newline()+$
            'Click "Cancel" to stop the load and continue with the existing '+ strupcase(varnames[i]) +'.'
          clobber = spd_ui_prompt_widget(gui_id,obj_new(),!spedas.historyWin,promptText=promptText,$
            /no,/yes,/allno,/allyes,/cancel, title='LOAD DATA: Variable already exists.', defaultvalue='cancel', frame_attr=8)
    
        endif
      
        if clobber eq 'yes' OR clobber eq 'yestoall' then begin
          h = 'TPLOT_GUI: ' + strupcase(varnames[i]) + ' will be overwritten.'
          !spedas.historyWin->Update, h
        endif
        if (clobber eq 'notoall') then begin
          varsToRename = array_concat(varnames[i], varsToRename)
        endif else if (clobber eq 'no') then begin
          spd_ui_rename_variable,gui_id, varnames[i], !spedas.loadedData, $
                       !spedas.windowStorage, !spedas.historywin, $
                       success=success,newnames=newname
          if ~success then begin
            dprint,'Data rename and load canceled.'
            !spedas.historyWin->update,'Data rename and load canceled.'
            continue
          endif else begin
            spd_ui_load_tvars_with_new_name, varnames[i], newname=newname, fail=fail
            if fail then begin
              ok = error_message('Error renaming variable ' + varnames[i], $
                    /center, title='Error in Load TVars', traceback=0)
              continue
            endif
            varnames[i]=newname
          endelse
        endif else if (clobber eq 'cancel') then begin
          h = 'LOAD DATA: ' + strupcase(varnames[i]) + $
            ' not loaded to prevent overwrite of existing data.'
          !spedas.historyWin->Update, h
        endif else if ~!spedas.loadedData->add(varnames[i]) then begin; adds the data for yes and yestoall
          dprint,"Problem adding: " + varnames[i] + " to GUI"
          continue
        endif
      ; if variable does not already exist:  
      endif else if  ~!spedas.loadedData->add(varnames[i]) then begin
          dprint,"Problem adding: " + varnames[i] + " to GUI"
          continue
      endif
      if (clobber ne 'notoall') && (clobber ne 'cancel') then begin
        all_names = array_concat(varnames[i],all_names)
        out_names = csvector(varnames[i],out_names)
      endif
    endelse
  endfor 
  if n_elements(varsToRename) ne 0 then begin
    spd_ui_rename_variable,gui_id, varsToRename, !spedas.loadedData, $
                       !spedas.windowStorage, !spedas.historywin, $
                       success=success,newnames=newnames
    if ~success then begin
      dprint,'Data rename and load canceled.'
      !spedas.historyWin->update,'Data rename and load canceled.'
    endif else begin
      for i=0L,n_elements(varsToRename)-1 do begin
        spd_ui_load_tvars_with_new_name, varsToRename[i], newname=newnames[i], fail=fail
        if fail then begin
          ok = error_message('Error renaming variable ' + varsToRename[i], $
                    /center, title='Error in Load TVars', traceback=0)
          continue
        endif
        varsToRename[i]=newnames[i]
        all_names = array_concat(varsToRename[i],all_names)
        out_names = csvector(varsToRename[i],out_names)
      endfor
    endelse
  endif
end

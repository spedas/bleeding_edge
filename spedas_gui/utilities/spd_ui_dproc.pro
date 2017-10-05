;+ 
;NAME:
; spd_ui_dproc
;PURPOSE:
; handles data processing requests
;CALLING SEQUENCE:
; spd_ui_dproc, info, uname
;INPUT:
; info = the info structure for the calling widget, the loadeddata
;        object, statusbar object and historywin object need to have
;        been initialized.
; uname = the string value for the data processing task that is to be
;        done. Good values are:  ['subavg', 'submed', 'smooth', 'blkavg',
;        'clip','deflag','degap','spike','deriv','pwrspc','wave',
;        'hpfilt']
;KEYWORDS:
; plugin_structure = If the requested operation is a plugin call then this should be
;                    a structure containing the plugin name and the plugin procedure
;                    to be called (these are set on widget creation in spd_ui_plugin_menu).
; ext_statusbar = the default is to output messages to the main GUI
;                 statusbar. If ext_statusbar is a valid object, then
;                 updates go here
; group_leader = widget ID of the dproc panel's group leader
; ptree = pointer to copy data tree
;
;OUTPUT:
; Returns 1 for successful output, 0 for unsuccessful, otherwise, 
; tasks are preformed, active data are updated, messages are updated.
; 
;NOTES:
;  If you add any operations,  be sure to put code in place
;  so that we can recall the operation when a spedas document is loaded without data.
;
;HISTORY:
; 20-oct-2008, jmm, jimm@ssl.berkeley.edu
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-24 18:45:02 -0700 (Fri, 24 Apr 2015) $
;$LastChangedRevision: 17429 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_dproc.pro $


;This routine simplifies some of the recall code
function call_dproc, dp_task, dp_pars, names_out = names_out, no_setactive = no_setactive, $
                     hwin = hwin, sbar = sbar, call_sequence = call_sequence,$
                     loadedData = loadedData, gui_id = gui_id, process_vars = process_vars, $
                     dpr_extra = _extra

  compile_opt idl2,hidden

  ;First get the active data names:
  If(is_string(process_vars)) Then in_vars = process_vars $ ;Use process_vars if you do not want to do all active data
  Else in_vars = loadedData->getactive(/parent) ;all you want is parents
  If(is_string(in_vars) Eq 0) Then Begin
    spd_ui_message, 'No active data; returning', sb=sbar, hw=hwin
    return, otp
  Endif
  
  otp = loadedData->dproc(dp_task, dp_pars,callSequence=call_sequence, names_out = names_out, in_vars=in_vars, $
                   no_setactive = no_setactive, hwin = hwin, sbar = sbar, gui_id = gui_id)
   
  return,otp

end


Function spd_ui_dproc, info, $
                       uname, $
                       plugin_structure=plugin_structure, $
                       group_leader = group_leader, $
                       ext_statusbar = ext_statusbar, $
                       ptree = ptree

;Initialize output
  otp = 0b

  err0 = 0
  catch, err0
  If(err0 Ne 0) Then Begin
    catch, /cancel
    ok = error_message(traceback = 1, /noname, title = 'Error in Data Processing: ')
    Return, 0b
  Endif

;Fall hard if the info structure doesn't exist here
  If(is_struct(info) Eq 0) Then message, 'Invalid info structure?'

  hwin = info.historywin
  If(obj_valid(ext_statusbar)) Then sbar = ext_statusbar $
  Else sbar = info.statusbar

  ;verify uname is present/string
  if ~is_string(uname,/blank) Then Begin
    spd_ui_message, 'Error processing dproc even; widget has no user name', sb=sbar, hw=hwin 
    return, otp
  endif

  ;get lower case uname without spaces
  un = strcompress(/remove_all, strlowcase(uname))

  info.windowStorage->getProperty,callSequence=call_sequence

  ;Get active data
  active_data = info.loadedData->getactive(/parent)

  if ~is_string(active_data[0]) then begin
    spd_ui_message, 'No active data.  Returning to Data Processing window.', sb=sbar, hw=hwin
    return, otp
  endif

  If(keyword_set(group_leader)) Then guiid = group_leader[0] Else guiid = info.master
  
  ;Long case statement
  Case un Of
    'plugin': begin
      ;double check that structure containing plugin/procedure names is present
      if ~is_struct(plugin_structure) then begin
        spd_ui_message, 'Invalidly formated plugin; missing widget structure', sb=sbar, hw=hwin
        return, opt
      endif

      ; open the plugin dialog
      values = call_function(plugin_structure.procedure, $
                             gui_id = guiid, $
                             history_window = hwin, $
                             status_bar = sbar, $
                             loaded_data = info.loadeddata, $
                             plugin_structure=plugin_structure)
      
      if values.ok then begin
        ; user pressed OK in the plugin dialog
        otp = call_dproc(un, values, hwin=info.historyWin, sbar=sbar, call_sequence=call_sequence, loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = plugin_structure.name
    end
    'split':begin
      otp = call_dproc(un, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    end
    'join':begin
      values = spd_ui_join_variables_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = 'Join Variables'
    end
    'subavg': otp = call_dproc(un,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    'submed': otp = call_dproc(un,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
    'deriv': begin
      values = spd_ui_time_derivative_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = 'Time Derivative'
    end
    'spike': begin
      values = spd_ui_clean_spikes_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values,hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = 'Clean Spikes'
    end
    'pwrspc': Begin
      overwrite_selections = 0
      popt = spd_ui_pwrspc_options(guiid, info.loadtr, info.historywin, sbar)

      if popt.success then begin
    
        spd_ui_pwrspc, popt, active_data, info.loadedData, info.historywin, $
                           sbar, guiId, fail=fail, overwrite_selections = overwrite_selections

        if ~keyword_set(fail) then begin
          call_sequence->addPwrSpecOp,popt,active_data,overwrite_selections
        endif

      endif else canceled = 'Power Spectrum' 
    End
    'smooth': Begin
      values = spd_ui_smooth_data_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else canceled = 'Smooth'
    End
    'blkavg': Begin

      datap = ptr_new(info.loadeddata)
      values = spd_ui_block_ave_options(guiid, sbar, info.historywin, datap)

      if values.ok then begin
        if obj_valid(values.trange) then str_element,values,'trange', $
          [values.trange->getStartTime(),values.trange->getEndTime()],/add_replace
        otp = call_dproc(un, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else canceled = 'Block Average'

    End
    'clip':Begin

      values = spd_ui_clip_data_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un,values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else canceled = 'Clip Data'
    End

    'deflag': Begin

      values = spd_ui_deflag_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = 'Deflag'
    End

    'degap':Begin

      values = spd_ui_degap_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid)
      endif else canceled = 'Degap'
    End
    'wave':Begin
    ;get options for each variable, this is done because the defaults for
    ;wavelets depend on dt
       active_data = info.loadedData->getactive(/parent)
; create new time range object here
       tr_obj = obj_new('SPD_UI_TIME_RANGE')
       ok = tr_obj->SetStartTime(info.loadtr->getstarttime())
       ok = tr_obj->setendtime(info.loadtr->getendtime())
       For i=0, n_elements(active_data)-1 Do Begin
          dpar = spd_ui_wavelet_options(guiid, info.loadeddata, tr_obj, $
                                        info.historywin, sbar, active_data[i])
          msg = ''
          If(is_struct(dpar) Eq 0 || dpar.success Eq 0) Then Begin
             canceled = 'Wavelet'
          Endif Else Begin
             otp = call_dproc(un, dpar, hwin=info.historyWin, sbar=sbar, $
                              call_sequence=call_sequence, $
                              loadedData=info.loadedData, process_vars = active_data[i], $
                              gui_id=guiid)  
          Endelse
          if msg ne '' then begin
             spd_ui_message, msg, sb=sbar, hw=hwin
          endif
       Endfor
       If(obj_valid(tr_obj)) Then obj_destroy, tr_obj
    End
    'hpfilt':Begin
      values = spd_ui_high_pass_options(guiid, sbar, info.historywin)
      if values.ok then begin
        otp = call_dproc(un, values, hwin=info.historyWin,sbar=sbar,call_sequence=call_sequence,loadedData=info.loadedData, gui_id=guiid) 
      endif else canceled = 'High Pass Filter'
    End
    'interpol':Begin

      datap = ptr_new(info.loadeddata)

      ;get interpolate options
      result = spd_ui_interpol_options(guiid,info.historywin, sbar, datap, ptree = ptree)

      ;this is probably unnecessary
      if ~is_struct(result) then break

      if result.ok then begin
       
        ;easier to serialize array than object
        if obj_valid(result.trange) then str_element,result,'trange', $
          [result.trange->getStartTime(),result.trange->getEndTime()],/add_replace
        
      
        spd_ui_interpolate, result,active_data, info.loadedData, info.historywin, $
                                          sbar, fail=fail, guiid=guiid, cadence_selections=cadence_selections,$
                                          overwrite_selections=overwrite_selections
        if fail eq 0 then begin
          call_sequence->addInterpOp,result,active_data,cadence_selections,overwrite_selections
        endif
                                            
      endif else cancled = 'Interpolate'

    End

    else: begin
      spd_ui_message, 'Invalid widget indentifier; unable to determine requested operation', sb=sbar, hw=hwin
      return, opt
    end

  Endcase

  ;If operation was canceled inform user here
  if is_string(canceled,/blank) then begin
    spd_ui_message, canceled+' operation canceled', sb=sbar, hw=hwin, /dontshow
  endif

  ;Update the draw object to refresh any plots
  info.drawobject->update, info.windowstorage, info.loadeddata
  info.drawobject->draw
  info.scrollbar->update
  
  Return, otp

End


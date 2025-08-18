;+
;NAME:
; spd_ui_loaded_data::dproc
;
;PURPOSE:
; extracts tplot variables from active data, performs data processing
; tasks, creates new variables, optionally sets those variables to
; active variables
;
;CALLING SEQUENCE:
; success = loaded_data_obj -> dproc(dp_task, dp_pars,callSequence, names_out=names_out, no_setactive=no_setactive)
;
;INPUT:
; dp_task = a string variable specifying the task to be carried
;           out. The options are ['subavg', 'submed', 'smooth',
;           'blkavg','clip','deflag','degap','spike','deriv',
;           'pwrspc','wave','hpfilt']
; dp_pars = an anonymous structure containing the input parameters for
; the task, this will be unpacked in this routine and the parameters
; are passed through. Note that, since this is only called from the
; thm_GUI_new routine, there is no error checking for
; content, it is expected that the calling routine passes through the
; proper parameters in each case.
;
; callSequence = Object to store previous dproc operations for replay
;
;OUTPUT:
; success = a byte, 0b if the process was unsuccessful or cancelled,
;           1b if the process was completed
;
;KEYWORDS:
; names_out = the tplot names of the created data variables
; no_setactive = if set, the new variables will no be set to active at
;                the end of the process.
; hwin, sbar = history window and status bar objects for updates
; gui_id = the id of the calling widget - to pass into warning pop-ups
;
;HISTORY:
; 16-oct-2008, jmm, jimm@ssl.berkeley.edu
; switched output from message to byte, 29-oct-2008,jmm
; 12-Dec-2008,prc Fixed bug where dproc was not reading data stored in
; loaded data,but instead was reading non-gui-data.
; Fixed bug where data produced by dproc was not inheriting any meta-data.
; 23-jan-2009, jmm, deletes any tplot variables that are created
;                   during processing, added catch, so that deletion
;                   of tplot variables is done if an error bonks a
;                   process.
; 10-Feb-2009, jmm, Added hwin, sbar keywords
; 24-Apr-2015, af, updating plugins, reformatting code
;
;$LastChangedBy: jimmpc1 $
;$LastChangedDate: 2020-09-28 14:33:06 -0700 (Mon, 28 Sep 2020) $
;$LastChangedRevision: 29192 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_loaded_data__dproc.pro $
Function spd_ui_loaded_data::dproc, dp_task, dp_pars,callSequence=callSequence,replay=replay,in_vars=in_vars, names_out = names_out, $
                           no_setactive = no_setactive, hwin = hwin, sbar = sbar, gui_id = gui_id, $
;when replaying data, need to remember user interaction responses if we're gonna get it right
                           overwrite_selections=overwrite_selections,degap_selections=degap_selections,blkavg_selections=blkavg_selections,$
                           smooth_selections=smooth_selections, hpf_selections=hpf_selections,$
                           _extra = _extra

compile_opt idl2, hidden



;Catch errors during processing
;  -allows dproc window to persist in case of error?
;------------------------------------------------
err = 0
catch, err
If(err Ne 0) Then Begin
  catch, /cancel
  Help, /Last_Message, Output=error
  if obj_valid(hwin) then hwin->update, error
  out_msg = 'Warning: An error occured during processing.  Check the history window for details.'
  ok = error_message(traceback = 1, /noname, title = 'Error in Data Processing: ',/center)
  if is_string(tnames_in) then begin
    spd_ui_cleanup_tplot, tnames_in, del_vars=new_names
    store_data, new_names, /delete
  endif
  return, 0b
Endif


;Initialize tracking variables
;------------------------------------------------
overwrite_selection =''
degap_selection=''
blkavg_selection=''
smooth_selection=''
hpf_selection=''

overwrite_count = 0
degap_count = 0
blkavg_count = 0
smooth_count = 0
hpf_count = 0
  
if ~keyword_set(replay) then begin
  overwrite_selections=''
  degap_selections=''
  blkavg_selections=''
  smooth_selections=''
  hpf_selections=''
endif

if ~is_string(in_vars) then begin
  return,0b
endif

task = strtrim(strlowcase(dp_task), 2)

;store all current tplot variable names
;  -new variables created while processing data will be removed later
tnames_in = tnames()

;create a display object to house the status bar and history windows
;  -this object will be passed to the underlying analysis routines
;   to allow them to report messages to the gui via dprint
display_object = obj_new('spd_ui_dprint_display', statusbar=sbar, historywin=hwin)


;Export active data to tplot and verify
;  -all metadata should be included in tplot var's dlimits structure
;------------------------------------------------
for i=0, n_elements(in_vars)-1 do begin

  tvar = self->getTvarData(in_vars[i])
  
  if is_string(tvar) then begin
    exported = array_concat(tvar,exported)
  endif else begin
    spd_ui_message, 'Failed to export '+in_vars[i]+' to tplot', sb=sbar, hw=hwin
  Endelse

endfor

;check that something exported
if undefined(exported) then begin
  spd_ui_message, 'Failed to export all active data to tplot', sb=sbar, hw=hwin
  return, 0b
endif


;Abstract operation so that a single loop can handle all cases
;  -join and plugin operations process all variables simultaneously
;  -all other operations currently take single variable inputs 
;------------------------------------------------
if task eq 'join' or task eq 'plugin' then begin
  operation = {task: task, input: exported}
endif else begin
  operation = replicate( {task:task, input:''}, n_elements(exported) )
  operation.input = exported
endelse


;Loop over operations
;------------------------------------------------
For j = 0, n_elements(operation)-1 Do Begin


  canceled = 0b  ; set/reset canceled flag
  skipped = 0b  ; set/reset skipped flag

  ;copy current task's input
  input = operation[j].input

  ;ensure output from last loop is cleared
  undefine, nn ;new names
  undefine, sn ;support names


  ;Process the data
  ;  -call appropriate routine to operate on exported tplot variable(s)
  ;------------------------------------------------
  Case operation[j].task Of

    ;plugins
    ;------------------
    'plugin': begin
        if ~tag_exist(dp_pars, 'dproc_routine') then begin
          dprint, dlevel = 0, 'Error, the dproc_routine tag must be set in the structure returned by the plugin window.'
          return, -1
        endif
        
        if tag_exist(dp_pars, 'keywords') then begin
          dproc_keywords = dp_pars.keywords
        endif
              
        call_procedure, dp_pars.dproc_routine, input, $
                                               output_names=nn, $
                                               support_names=sn, $
                                               status_bar=sbar, $
                                               history_window=hwin, $
                                               _extra = dproc_keywords
    end
    
    ;split variable
    ;------------------
    'split': Begin
        split_vec, input, names_out = nn, inset='_split', display_object=display_object
    End
    
    ;join variables
    ;------------------
    'join': Begin
        join_vec, input, dp_pars.new_name[0], display_object=display_object, fail=jfail
        if keyword_set(jfail) then begin
          spd_ui_message, 'Could not join selected variables.', sb=sbar, hw=hwin
        endif else begin
          nn = dp_pars.new_name
        endelse
    End
    
    ;subtract average
    ;------------------
    'subavg': Begin
        tsub_average, input, nn, new_name = (input+'-d')[0], display_object=display_object
        nn = tnames(input+'-d')
    End
    
    ;subtract median
    ;------------------
    'submed': Begin
        tsub_average, input, nn, new_name = (input+'-m')[0], /median
        nn = tnames(input+'-m')
    End
    
    ;time derivative
    ;------------------
    'deriv': Begin
        get_data, input, ttt
        If(n_elements(temporary(ttt)) Gt 3) Then Begin
           deriv_data, input, newname = input+dp_pars.suffix[0], display_object=display_object, $
                       _extra={nsmooth:( dp_pars.setswidth ? dp_pars.swidth:0b)}
           nn = tnames(input+dp_pars.suffix)
        Endif Else Begin
           spd_ui_message,'Unable to get time derivative for '+input+'; not enough time elements.',sb=sbar, hw=hwin
           canceled = 1b
        Endelse
    End
    
    ;clean spikes
    ;------------------
    'spike': Begin
        clean_spikes, input, new_name = input+dp_pars.suffix[0], display_object=display_object, $
                      nsmooth = dp_pars.swidth[0], $
                      thresh = dp_pars.thresh[0]
        nn = tnames(input+dp_pars.suffix)
    End
    
    ;smooth data
    ;------------------
    'smooth': Begin
        get_data, input, t
        noktimes =  n_elements(t)
        if noktimes gt 1 then begin ; operation not valid on single time element
            av_dt = median(t[1:*]-t)
            If(av_dt Gt dp_pars.dt) then begin
                if smooth_selection ne 'yestoall' && smooth_selection ne 'notoall' Then Begin
                    smooth_selection=''
                    if ~keyword_set(replay) then begin
                        lbl = ['Note that the median value of the time resolution for '+input+' is:'+strcompress(string(av_dt))+' sec.', $
                               'The value that you have chosen for the averaging time resolution is smaller: '+$
                               strcompress(string(dp_pars.dt))+' sec.', $
                               'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                                                    
                        smooth_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI SMOOTH TEST',/yes,/no,/allyes,/allno, frame_attr=8)
                        smooth_selections = array_concat_wrapper(smooth_selection,smooth_selections)
                    endif else begin
                        if smooth_count ge n_elements(smooth_selections) then begin
                            spd_ui_message, "ERROR:Discrepancy in spedas document, may have lead to a document load error", sb=sbar, hw=hwin
                            smooth_selection = "yestoall"
                        endif else begin
                            smooth_selection = smooth_selections[smooth_count]
                        endelse
                    endelse
                endif
                smooth_count++
            Endif
            If (av_dt le dp_pars.dt[0] || (smooth_selection ne 'notoall' && smooth_selection ne 'no')) Then Begin
                dt = dp_pars.dt[0]
                _extra = {forward:dp_pars.dttype[1], $
                          backward:dp_pars.dttype[2], $
                          no_time_interp:dp_pars.opts[0], $
                          true_t_integration:dp_pars.opts[1], $
                          smooth_nans:dp_pars.opts[2]}
                if dp_pars.setICad then str_element, _extra, 'interp_resolution', dp_pars.icad, /add_replace
                If(dt Lt 1.0) Then dtchar = strcompress(/remove_all, dt) $
                Else dtchar = strcompress(/remove_all, fix(dt))
                tsmooth_in_time, input, dt, newname = input+dp_pars.suffix[0], display_object=display_object, _extra=_extra, $
                  interactive_varname=input,/interactive_warning,warning_result=warning_result
                if n_elements(warning_result) gt 0 && warning_result eq 1 then begin
                    nn = tnames(input+dp_pars.suffix)
                endif
            Endif Else Begin
                spd_ui_message,'Smooth process for: '+input+' cancelled.', sb=sbar, hw=hwin
                canceled = 1b ;prevent variable from being added later
            Endelse
        endif else begin
            spd_ui_message,'Unable to smooth '+input+' not enough elements in time range.', sb=sbar, hw=hwin
            canceled = 1b
        endelse
    End
    
    ;block average
    ;------------------
    'blkavg': Begin
    ;need another sanity test
      get_data, input, t
      ;test trange here
      if dp_pars.limit Eq 1 then begin
         oktimes =  where(t Gt dp_pars.trange[0] And t Le dp_pars.trange[1],  noktimes)
       endif else noktimes =  n_elements(t)
      
      if noktimes gt 1 then begin ; operation not valid on single time element
        av_dt = median(t[1:*]-t)
        
        If(av_dt Gt dp_pars.dt) then begin
          if blkavg_selection ne 'yestoall' && blkavg_selection ne 'notoall' Then Begin
            blkavg_selection=''
            if ~keyword_set(replay) then begin
              lbl = ['Note that the median value of the time resolution for '+input+' is:'+strcompress(string(av_dt))+' sec.', $
                     'The value that you have chosen for the averaging time resolution is smaller: '+$
                     strcompress(string(dp_pars.dt))+' sec.', $
                     'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
          
              blkavg_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI BLK_AVG TEST',/yes,/no,/allyes,/allno, frame_attr=8)
              blkavg_selections = array_concat_wrapper(blkavg_selection,blkavg_selections)
            endif else begin
              if blkavg_count ge n_elements(blkavg_selections) then begin
                spd_ui_message, "ERROR:Discrepancy in spedas document, may have lead to a document load error", sb=sbar, hw=hwin
                blkavg_selection = "yestoall"
              endif else begin
                blkavg_selection = blkavg_selections[blkavg_count]
              endelse
            endelse
          endif
          
          blkavg_count++
        Endif
        If  (av_dt le dp_pars.dt || (blkavg_selection ne 'notoall' && blkavg_selection ne 'no')) Then Begin
            dt = dp_pars.dt[0]
            avg_data, input, dt, newname = input+dp_pars.suffix[0], display_object=display_object, $
                      _extra = {trange:( dp_pars.limit ? dp_pars.trange:0b)}
            nn = tnames(input+dp_pars.suffix)
        Endif Else Begin
            spd_ui_message,'Block Average process for: '+input+' cancelled.', sb=sbar, hw=hwin
            canceled = 1b ;prevent variable from being added later
        Endelse
      endif else begin
        spd_ui_message,'Unable to block average '+input+' not enough elements in time range.', sb=sbar, hw=hwin
        canceled = 1b
      endelse
    End
    
    ;clip y axis
    ;------------------
    'clip': Begin
        tclip, input, dp_pars.minc[0], dp_pars.maxc[0], newname = input+dp_pars.suffix[0], display_object=display_object, $
               _extra = {clip_adjacent: dp_pars.opts[0], $
                         flag: (dp_pars.opts[1] ? dp_pars.flag:0b)}
        nn = tnames(input+dp_pars.suffix)
    End
    
    ;deflag / remove flags
    ;------------------
    'deflag': Begin
;       tdeflag, input, (dp_pars.method[0] ? 'repeat':'linear'), $
       If(dp_pars.method[1] Eq 1) Then dflag_method = 'linear' $
       Else If(dp_pars.method[2] Eq 1) Then dflag_method = 'replace' $
       Else dflag_method = 'repeat'
       tdeflag, input, dflag_method, $
                newname = input+dp_pars.suffix[0], display_object=display_object, $
                _extra = {flag: (dp_pars.opts[0] ? dp_pars.flag:0b), $
                          maxgap: (dp_pars.opts[1] ? dp_pars.maxgap:0b), $
                          fillval:(dp_pars.opts[2] ? dp_pars.fillval:0b)}
       nn = tnames(input+dp_pars.suffix)
    End
    
    ;degap / remove time gaps
    ;------------------
    'degap': Begin
    ;need another sanity test
      get_data, input, t
      
      if n_elements(t) gt 1 then begin ; operation not valid on single time element
        dt = t[1:*]-t[0:n_elements(t)-2]
        av_dt = median(dt)
        max_dt = max(dt)
        
        ;filter variables who no dt larger than threshold+margin (seems to be how xdegap works)
        if (dp_pars.dt[0] + dp_pars.margin[0]) gt max_dt then begin
          spd_ui_message,'No gaps below threshold in '+input+'.', sb=sbar, hw=hwin
          canceled = 1b ;prevent variable from being added later
          break
        endif
              
        If(av_dt Gt dp_pars.dt) then begin
          if degap_selection ne 'yestoall' && degap_selection ne 'notoall' Then Begin
            degap_selection=''
            if ~keyword_set(replay) then begin
              lbl = ['Note that the median value of the time resolution for '+input+' is:'+strcompress(string(av_dt))+' sec.', $
                     'The value that you have chosen for the degap time resolution is smaller: '+$
                     strcompress(string(dp_pars.dt))+' sec.', $
                     'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                     
              degap_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI DEGAP TEST',/yes,/no,/allyes,/allno, frame_attr=8) 
              degap_selections = array_concat_wrapper(degap_selection,degap_selections)
            endif else begin
              if degap_count ge n_elements(degap_selections) then begin
                spd_ui_message, "ERROR:Discrepancy in spedas document, may have lead to a document load error", sb=sbar, hw=hwin
                degap_selection = "yestoall"
              endif else begin
                degap_selection = degap_selections[degap_count]
              endelse
            endelse
          endif
          
          degap_count++
        Endif
              
        If (av_dt le dp_pars.dt || (degap_selection ne 'notoall' && degap_selection ne 'no')) Then Begin
            if dp_pars.opts[0] then str_element,_extra,'flag',dp_pars.flag, /add_replace
            if dp_pars.opts[1] then str_element,_extra,'maxgap',dp_pars.maxgap, /add_replace
            tdegap, input, dt = dp_pars.dt[0], $
                    margin = dp_pars.margin[0], $
                    ;maxgap = dp_pars.maxgap[0], $
                    newname = input+dp_pars.suffix[0], $
                    display_object=display_object, $
                    _extra = _extra
            nn = tnames(input+dp_pars.suffix)

        Endif Else Begin
            spd_ui_message,'Degap process for: '+input+' cancelled.', sb=sbar, hw=hwin
            canceled = 1b ;prevent variable from being added later
        Endelse
      endif else begin
        spd_ui_message,'Unable to process '+input+' not enough elements', sb=sbar, hw=hwin
        canceled = 1b
      endelse
        
    End
    
    ;wavelet transform
    ;------------------
    'wave': Begin
        get_data, input, t
        sstx = where(t Ge dp_pars.trange[0] And $
                     t Lt dp_pars.trange[1], nsstx)
        If(nsstx Gt 0) Then Begin
           spd_ui_message,'Processing Wavelet for: '+input, sb=sbar, hw=hwin
           ;Here just increase maxpoints to be larger than nsstx, the memory
           ;check should do enough so that the user knows when he has memory
           ;issues, jmm 2015-01-20
           spd_ui_wavelet, input, nn, dp_pars.trange, $
                           maxpoints=nsstx+16, $
                           temp_names = temp_names, $
                           display_object=display_object, prange=dp_pars.prange
           if is_string(temp_names) then begin
              store_data, temp_names, /delete
           endif
           options, nn, spec=1, /default
        Endif Else Begin
           spd_ui_message, 'Wavelet process for: '+input+' cancelled.', sb=sbar, hw=hwin
           canceled = 1b ;prevent variable from being added later
        Endelse
    End
    
    ;high pass filter
    ;------------------
    'hpfilt': Begin
        get_data, input, t
        noktimes =  n_elements(t)
        if noktimes gt 1 then begin ; operation not valid on single time element
            av_dt = median(t[1:*]-t)
            If(av_dt Gt dp_pars.dt) then begin
                if hpf_selection ne 'yestoall' && hpf_selection ne 'notoall' Then Begin
                    hpf_selection=''
                    if ~keyword_set(replay) then begin
                        lbl = ['Note that the median value of the time resolution for '+input+' is:'+strcompress(string(av_dt))+' sec.', $
                               'The value that you have chosen for the averaging time resolution is smaller: '+$
                               strcompress(string(dp_pars.dt))+' sec.', $
                               'This will have non-intuitive and possibly non-plottable results. Do you want to continue?']
                        
                        hpf_selection = spd_ui_prompt_widget(gui_id,sbar,hwin,prompt=strjoin(lbl,ssl_newline()),title='SPEDAS GUI HPFILTER TEST',/yes,/no,/allyes,/allno, frame_attr=8)
                        hpf_selections = array_concat_wrapper(hpf_selection,hpf_selections)
                    endif else begin
                        if hpf_count ge n_elements(hpf_selections) then begin
                            spd_ui_message, "ERROR:Discrepancy in spedas document, may have lead to a document load error", sb=sbar, hw=hwin
                            hpf_selection = "yestoall"
                        endif else begin
                            hpf_selection = hpf_selections[hpf_count]
                        endelse
                    endelse
                endif
                hpf_count++
            Endif
            If (av_dt le dp_pars.dt[0] || (hpf_selection ne 'notoall' && hpf_selection ne 'no')) Then Begin
                dt = dp_pars.dt[0]
                thigh_pass_filter, input, dt, newname = input+dp_pars.suffix[0], display_object=display_object, $
                  /interactive_warning,warning_result=warning_result, $
                  _extra = {interp_resolution: (dp_pars.seticad ? dp_pars.icad:0b)}
                if n_elements(warning_result) gt 0 && warning_result eq 0 then break
                nn = tnames(input+dp_pars.suffix)
            Endif Else Begin
                spd_ui_message,'High Pass Filter process for: '+input+' cancelled.', sb=sbar, hw=hwin
                canceled = 1b ;prevent variable from being added later
            Endelse
        endif else begin
            spd_ui_message,'Unable to High Pass filter '+input+' not enough elements in time range.', sb=sbar, hw=hwin
            canceled = 1b
        endelse
    End
    else: 
  Endcase ; ------------- end of requested task --------------

  
    
  ;Add output from processing routine to the GUI
  ;------------------------------------------------
  if is_string(nn) and ~canceled Then Begin

    for k = 0, n_elements(nn)-1 do begin
      
      spd_ui_check_overwrite_data,nn[k],self,gui_id,sbar,hwin,overwrite_selection,overwrite_count,$
                           replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then continue   
           
      ;add tplot variable to the gui
      ;  -this should properly capture metadata, if not then then it should be fixed elsewhere rather than kludged here
      add_success = self->add(nn[k])
        
      msg = add_success ? 'Added variable: ' : 'Failed to add variable: '
      spd_ui_message, msg+nn[k], sb=sbar, hw=hwin
      
      if ~add_success then continue

      ;add output variables to list of valid outputs
      names_out = array_concat(nn[k],names_out)
      
      ;add support variables to list of valid support vars (excluded from deletion later)
      if is_string(sn) then begin
        support_names = array_concat(sn, support_names)
      endif

    endfor

  endif else begin

    ;notify user if no valid output was found
    spd_ui_message, strjoin(input,', ')+' not processed', sb=sbar, hw=hwin
    skipped = 1b

  endelse

  
  if canceled or skipped then oops = 1b ; set flag to notify user later
  if double(!version.release) lt 8.0d then heap_gc ;clean-up memory


Endfor ; --------- end of loop over active data ----------



;if output names exist then at least one opperation was successful
success = is_string(names_out)


;set any output as the new active data
if success && ~keyword_set(no_setactive) then begin
  self->clearallactive
  for j = 0, n_elements(names_out)-1 do begin
    self->setactive, names_out[j]
  endfor
endif


;add this call to the call sequence 
if success && ~keyword_set(replay) then begin
  callSequence->addDprocOp,dp_task,in_vars,params=dp_pars,overwrite_selections,degap_selections,blkavg_selections
endif


;dump any tplot variables that were not previously present
;  -exclude explicitly designated support dat from plugins
spd_ui_cleanup_tplot, tnames_in, del_vars=new_names
if is_string(support_names) then begin
  new_names = ssl_set_complement(support_names, new_names)
endif
store_data, new_names, /delete


;notify user if any quantities were excluded (this should be the last output message)
if keyword_set(oops) then begin
  spd_ui_message, 'Finished.  Some quantities were not processed.  '+ $
                  '(Scroll back in status bar or check history window for details)', $
                  sb=sbar, hw=hwin
endif


return, success


End


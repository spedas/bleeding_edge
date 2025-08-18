;+ 
;NAME:
; thm_ui_dproc
;PURPOSE:
; A widget interface for calling tplot from the themis_w widget,
; currently of limited usefulness, but expandable
;CALLING SEQUENCE:
; thm_ui_dproc, master_widget_id
;INPUT:
; master_widget_id = the id number of the widget that calls this
;OUTPUT:
; none, there are buttons to push for plotting, setting limits, not
; sure what else yet...
;HISTORY:
; 06-may-2008, cg, added check to validate data, any active data that
;                  has dimensions ge 3 cannot be processed
;                  added data check for despike, time deriv, wavelet, 
;                  powerspec, active data that has a y component > 6 
;                  cannot be processed
;                  and finally, rearranged widgets to allow for a long
;                  narrow message window
; 28-mar-2008, cg, added filename dialog box to ascii save option,
;                  and passed file name to tplot_ascii
; 14-dec-2006, jmm, jimm@ssl.berkeley.edu
; 13-feb-2007, jmm, fixed problem with !p.background resetting in
; set_plot commands
; 12-mar-2007, jmm, Added wavelet button
; 2-apr-2007, jmm, Added pwrspc options
; 5-jun-2007, jmm, rewritten
; 12-jul-2007, jmm, added a message widget, for invalid user input
;                   errors, grays out all buttons while processing
; 31-jul-2007, jmm, changed time limits to 'set time limits'
; 17-mar-2008, jmm, changed smooth option to input seconds, not npts
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_dproc.pro $
;
;-
Pro thm_ui_dproc_event, event

  @tplot_com

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state)) Then Begin
      widget_control, state.messw, set_val = 'Error--See history'
      cw = state.cw
      For j = 0, n_elements(state.button_arr)-1 Do $
        widget_control, state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    Endif Else Begin
      widget_control, event.top, get_uval = state, /no_copy
      If(is_struct(state)) Then Begin
        widget_control, state.messw, set_val = 'Error--See history'
        cw = state.cw
        For j = 0, n_elements(state.button_arr)-1 Do $
          widget_control, state.button_arr[j], sensitive = 1
        widget_control, event.top, set_uval = state, /no_copy
      Endif Else cw = -1
    Endelse
    If(widget_valid(cw)) Then Begin
      If(is_struct(wstate)) Then widget_control, cw, set_uval = wstate
      thm_ui_update_history, cw, [';*** FYI', ';'+err_msg]
      thm_ui_update_progress, cw, 'Error--See history'
    Endif
    thm_ui_error
    Return
  Endif

;start here
  widget_control, event.id, get_uval = uval  
  If(uval Eq 'EXIT') Then Begin
    widget_control, event.top, /destroy
  Endif Else If(uval Eq 'TLIMIT') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    cw = state.cw & messw = state.messw & button_arr = state.button_arr
    widget_control, event.top, set_uval = state, /no_copy
    widget_control, cw, get_uval = wstate, /no_copy
    If(ptr_valid(wstate.active_vnames)) Then Begin
      tvn = *wstate.active_vnames
    Endif Else tvn = ''
    widget_control, cw, set_uval = wstate, /no_copy
    If(is_string(tvn)) Then Begin
      For j = 0, n_elements(button_arr)-1 Do $
        widget_control, button_arr[j], sensitive = 0
      thm_ui_update_progress, message_wid = messw, cw, 'Choosing Time Limits for Processing'
      thm_ui_set_tlimits, event.top
      For j = 0, n_elements(button_arr)-1 Do $
        widget_control, button_arr[j], sensitive = 1
    Endif Else Begin
      thm_ui_update_progress, message_wid = messw, cw, 'No Active Dataset, Nothing happened'
    Endelse
  Endif Else If(uval Eq 'RESTORE') Then Begin
    widget_control, event.top, get_uval = state, /no_copy
    cw = state.cw & messw = state.messw & button_arr = state.button_arr
    widget_control, event.top, set_uval = state, /no_copy
    For j = 0, n_elements(button_arr)-1 Do widget_control, button_arr[j], sensitive = 0
    widget_control, messw, set_val = ''
    fff = dialog_pickfile(title = 'Choose Filename To Restore Data:', $
                          filter = '*.tplot')
    If(is_string(fff)) Then Begin
      history_ext = 'tplot_restore, filenames = '+$
        ''''+fff+''''+', /get_tvars'
      thm_ui_update_progress, message_wid = messw, cw, 'Restoring Files: '+fff
      tplot_restore, filenames = fff, /get_tvars, restored_varnames = vn_new
      history_ext = [history_ext, $
                     thm_ui_multichoice_history('varnames = ', vn_new)]
      thm_ui_update_history, cw, history_ext
      thm_ui_update_progress, message_wid = messw, cw, 'Restored Files: '+fff
      thm_ui_update_data_all, cw, vn_new
    Endif Else Begin
      thm_ui_update_progress, message_wid = messw, cw, 'Invalid Filename: '+fff
    Endelse
    For j = 0, n_elements(button_arr)-1 Do widget_control, button_arr[j], sensitive = 1
  Endif Else Begin
;Get parameters needed then put states back into widgets
    widget_control, event.top, get_uval = state, /no_copy
    cw = state.cw & messw = state.messw & button_arr = state.button_arr
    widget_control, state.cw, get_uval = wstate, /no_copy
    st_time = wstate.pstate.st_time & en_time = wstate.pstate.en_time
    If(ptr_valid(wstate.active_vnames)) Then Begin
      tvn = *wstate.active_vnames
    Endif Else tvn = ''
    widget_control, state.cw, set_uval = wstate, /no_copy
    widget_control, event.top, set_uval = state, /no_copy
    If(is_string(tvn)) Then Begin
;Grey out all but the exit button
      For j = 0, n_elements(button_arr)-1 Do widget_control, button_arr[j], sensitive = 0
      widget_control, messw, set_val = ''
;initialize new variable array
      vn_new = tvn
 
      Case uval Of
;subtracts the mean and creates new variables for plotting
        'SUBAVG':Begin
          For j = 0, n_elements(tvn)-1 Do Begin
            get_data, tvn[j], data=d
            s=size(d.y, /dimensions)
            if n_elements(s) ge 3 then Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Unable to subtract average.'
            endif else Begin 
;history of this is not easy...
               history_ext = ['new_vars = strarr(n_elements(varnames))', $
                         'For j = 0, n_elements(varnames) -1 Do $', $
                         '  tsub_average, varnames[j], new_varname', $
                         '  new_vars[j] = new_varname', $
                         'varnames = new_vars']
              thm_ui_update_history, cw, history_ext
              thm_ui_update_progress, message_wid = messw, cw, 'Subtracting Average Values for '+tvn(j)
              tsub_average, tvn[j], nvn
              thm_ui_update_progress, message_wid = messw, cw, 'Done Subtracting Average Values for '+tvn(j)
              If(is_string(nvn)) Then vn_new[j] = nvn Else Begin
                help, /last_message, output = err_msg
                thm_ui_update_progress, message_wid = messw, cw, err_msg[0]
                thm_ui_update_history, cw, ';'+err_msg[0]
              Endelse
            endelse
          Endfor
        End
;subtracts the mean and creates new variables for plotting
        'SUBMED':Begin
          history_ext = ['new_vars = strarr(n_elements(varnames))', $
                         'For j = 0, n_elements(varnames) -1 Do $', $
                         '  tsub_average, varnames[j], new_varname, /median', $
                         '  new_vars[j] = new_varname', $
                         'varnames = new_vars']
          thm_ui_update_history, cw, history_ext
          thm_ui_update_progress, message_wid = messw, cw, 'Subtracting Median Values:'
          For j = 0, n_elements(tvn)-1 Do Begin
            get_data, tvn[j], data=d
            s=size(d.y, /dimensions)
            if n_elements(s) ge 3 then Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Unable to subtract median.'
            endif else Begin 
              history_ext = ['new_vars = strarr(n_elements(varnames))', $
                         'For j = 0, n_elements(varnames) -1 Do $', $
                         '  tsub_average, varnames[j], new_varname, /median', $
                         '  new_vars[j] = new_varname', $
                         'varnames = new_vars']
              thm_ui_update_history, cw, history_ext
              thm_ui_update_progress, message_wid = messw, cw, 'Subtracting Median Values for '+tvn(j)
              tsub_average, tvn[j], nvn, /median
              thm_ui_update_progress, message_wid = messw, cw, 'Done Subtracting Median Values for '+tvn(j)
              If(is_string(nvn)) Then vn_new[j] = nvn Else Begin
                help, /last_message, output = err_msg
                thm_ui_update_progress, message_wid = messw, cw, err_msg[0]
                thm_ui_update_history, cw, ';'+err_msg[0]
              Endelse
            endelse
          Endfor
        End
        'SMOOTH':Begin
;Get the smoothing parameter
          smooth_res = thm_ui_npar(['Smoothing Resolution in seconds'], ['61'], $
                                   title='Smooth Data')
          If(smooth_res[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endif Else Begin
            smooth_res = smooth_res[0]
            smr = strcompress(smooth_res, /remove_all)
            smooth_res = double(smooth_res)
            If(smooth_res Gt 0) Then Begin
              vn_new=tvn+'_sm_'+smr
              for j=0, n_elements(tvn)-1 do Begin
                get_data, tvn[j], data=d
                s=size(d.y, /dimensions)
                if n_elements(s) ge 3 then Begin
                   thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Unable to smooth data.'
                   vn_new=tvn
                endif else Begin 
                  history_ext = ['width = '+smr, $
                             'new_vars = varnames+''_sm_'+smr+'''', $
                             'For j = 0, n_elements(new_vars)-1 Do $', $
                             '  tsmooth_in_time, varnames[j], width, newname = new_vars[j]', $
                             'varnames = new_vars']
                  thm_ui_update_history, cw, history_ext
                  thm_ui_update_progress, message_wid = messw, cw, 'Smoothing '+tvn(j)
                  tsmooth_in_time, tvn[j], smooth_res, newname = vn_new[j]
                  thm_ui_update_progress, message_wid = messw, cw, 'Done Smoothing '+tvn(j)
               Endelse
             endfor
           endif else begin
              thm_ui_update_progress, message_wid = messw, cw, 'Invalid Smoothing Parameter'
           Endelse 
         endelse    
        End
        'AVG':Begin
;Get the time_resolution
          time_res = thm_ui_npar(['Time Resolution (sec)'], ['60'], $
                                 title='Block Average')
          time_res = time_res[0]
          smr = strcompress(time_res, /remove_all)
          If(time_res[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endif Else Begin
            for j = 0, n_elements(tvn)-1 do Begin
              get_data, tvn[j], data = d
              s = size(d.y, /dimensions)
              if n_elements(s) ge 3 then Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Unable to average.'
              endif else Begin 
                time_res = float(time_res)
                If(time_res Gt 0) Then Begin
                  vn = tvn[j]+'_av_'+smr
                  if j eq 0 then vn_new = [vn] else vn_new = [vn_new, vn]  
                  history_ext = ['time_res = '+smr, $
                                 'new_vars = varnames+''_av_'+smr+'''', $
                                 'For j = 0, n_elements(new_vars)-1 Do $', $
                                 ' avg_data, varnames[j], time_res, newname = new_vars[j]', $
                                 'varnames = new_vars']
                  thm_ui_update_history, cw, history_ext
                  thm_ui_update_progress, message_wid = messw, cw, 'Averaging '+tvn[j]
                  avg_data, tvn[j], time_res, newname = vn_new[j]
                  thm_ui_update_progress, message_wid = messw, cw, 'Done Averaging '+tvn[j]
                Endif Else Begin
                  thm_ui_update_progress, message_wid = messw, cw, 'Invalid Time Resolution'
                Endelse
              endelse
            endfor
          Endelse
       End
        'DERIV':Begin
          vn_n=' '
          vn_new=' '
          for j=0, n_elements(tvn)-1 do Begin
            get_data, tvn[j], data=d
            s=size(d.y, /dimensions)
            if n_elements(s) ge 3 then Begin
               thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Time derivative not done.'
               vn_new=tvn(j)
            endif else Begin
                if (n_elements(s) gt 1 && s[1] gt 6) then begin
                  thm_ui_update_progress, message_wid = messw, cw, 'Variable '+tvn(j)+' has > 6 components. Time derivative not taken.'                  
                  vn_new=tvn(j)
                endif else Begin
                  history_ext = ['new_vars = varnames+''_ddt''+', $
                               'deriv_data, varnames', $
                               'varnames = new_vars']
                  thm_ui_update_history, cw, history_ext
                  thm_ui_update_progress, message_wid = messw, cw, 'Taking Time derivative for '+tvn[j]
                  vn = string(tvn[j]+'_ddt')
                  deriv_data, tvn[j], newname=vn 
                  get_data, vn, data=d
                  if size(d, /type) ne 8 then Begin
                     thm_ui_update_progress, message_wid = messw, cw, 'Unable to take time derivative for '+tvn[j] 
                  endif else Begin
                  print, vn_n
                     thm_ui_update_progress, message_wid = messw, cw, 'Done taking time derivative for '+tvn[j]
                     vn_n=[vn_n,vn]
                  endelse
               endelse
              endelse
          endfor
          if strlen(vn_n(0)) lt 3 then Begin
             if (n_elements(vn_n) gt 1) then vn_new=vn_n(1:*) else vn_new=tvn
          endif else Begin
             vn_new=vn_n
          endelse
        End
        'SPIKE':Begin
          vn_new=' '
          vn_n=' '
          ;vn_new = tvn+'_dspk'
          history_ext = ['new_vars = varnames+''_dspk''', $
                         'For j = 0, n_elements(new_vars)-1 Do $', $
                         ' clean_spikes, varnames[j], new_name = new_vars[j]', $
                         'varnames = new_vars']
          thm_ui_update_history, cw, history_ext
          thm_ui_update_progress, message_wid = messw, cw, 'Despiking Data:'
          For j = 0, n_elements(tvn)-1 Do Begin
            get_data, tvn[j], data=d
            s=size(d.y, /dimensions)
            if n_elements(s) ge 3 then Begin
               thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Spikes not removed.'
            endif else Begin           
              if (n_elements(s) gt 1 && s[1] gt 6) then Begin
                 thm_ui_update_progress, message_wid = messw, cw, 'Variable '+tvn(j)+' has > 6 components. Spikes not removed.'                  
              endif else Begin
                   history_ext = ['new_vars = varnames+''_dspk''', $
                         'For j = 0, n_elements(new_vars)-1 Do $', $
                         ' clean_spikes, varnames[j], new_name = new_vars[j]', $
                         'varnames = new_vars']
                  thm_ui_update_history, cw, history_ext
                  thm_ui_update_progress, message_wid = messw, cw, 'Despiking '+tvn(j)
                  vn = tvn[j]+'_dspk'
                  clean_spikes, tvn[j], new_name = vn 
                  thm_ui_update_progress, message_wid = messw, cw, 'Done Despiking '+tvn(j)
                  vn_n=[vn_n, vn]
                endelse
              endelse
          endfor
          if strlen(vn_n(0)) lt 3 then Begin
             if (n_elements(vn_n) gt 1) then vn_new=vn_n(1:*) else vn_new=tvn
          endif else Begin
             vn_new=vn_n
          endelse
        End
        'CLIP':Begin
          xxx = thm_ui_npar(['Max', 'Min']+' for clipping', ['20.0', '-20.0'],$
                 title='Max/Min for Clipping')
          If(xxx[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endif Else Begin
            amin = min(float(xxx)) & amax = max(float(xxx))
            vn_new = tvn+'_clip'
            for j=0, n_elements(tvn)-1 do Begin
              get_data, tvn[j], data=d
              s=size(d.y, /dimensions)
              if n_elements(s) ge 3 then Begin
                 thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Data not clipped.'
                 vn_new=tvn
              endif else Begin                       
                thm_ui_update_progress, message_wid = messw, cw, 'Clipping '+tvn(j)
                history_ext = ['new_vars = varnames+''_clip''', $
                           'tclip, varnames, '+xxx[0]+', '+xxx[1]+$
                           ', newname = new_vars', 'varnames = new_vars']
                thm_ui_update_history, cw, history_ext
                tclip, tvn[j], amin, amax, newname = vn_new[j]
                thm_ui_update_progress, message_wid = messw, cw, 'Done Clipping '+tvn(j)
              endelse
            endfor
          Endelse
        End
        'DEFLAG':Begin
         xxx = thm_ui_npar(['Choose a Deflag Method: Repeat (Last Value) or Linear (Interpolate) '], [''], radio_array=['Repeat', 'Linear'], $
                           radio_value='Repeat', title='Deflag')
          If(is_string(xxx)) Then Begin
            If(xxx[0] Eq 'Cancelled') Then Begin
              thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
            Endif Else Begin
              method = strtrim(strlowcase(xxx[1]), 2)
              If(method Eq 'linear' Or method Eq 'repeat') Then Begin
                vn_new = tvn+'_deflag'
                for j=0,n_elements(tvn)-1 do Begin
                  get_data, tvn[j], data=d
                  s=size(d.y, /dimensions)
                  if n_elements(s) ge 3 then Begin
                     thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Data not deflagged.'
                     vn_new=tvn
                  endif else Begin                       
                    history_ext = ['new_vars = varnames+''_deflag''', $
                               'tdeflag, varnames, '+method+', newname = new_vars', $
                               'varnames = new_vars']
                    thm_ui_update_history, cw, history_ext
                    thm_ui_update_progress, message_wid = messw, cw, 'Deflagging '+tvn(j)
                    tdeflag, tvn, method, newname = vn_new
                    thm_ui_update_progress, message_wid = messw, cw, 'Done Deflagging '+tvn(j)
                  endelse
                endfor
              Endif Else Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Invalid Method Input'
              Endelse
            Endelse
          Endif Else Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Invalid Method Input'
          Endelse
        End
;degap button
        'DEGAP':Begin
          vn_n=' '
          xxx = thm_ui_npar(['Time Interval (sec)', $
                             'Margin (sec)', 'max gapsize (sec)']+$
                            ' for degap', $
                            ['1.0', '0.25', '10000'], $
                            title='Degap')
          If(xxx[0] Eq 'Cancelled') Then Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endif Else Begin
            dtx = double(xxx[0])
            mrx = double(xxx[1])
            maxgapx = double(xxx[2])
            If(dtx Gt 0 And mrx Ge 0 And maxgapx Gt 0) Then Begin
              xxx = strcompress(xxx, /remove_all)
              vn_new = tvn+'_degap'
              for j=0,n_elements(tvn)-1 do Begin
                get_data, tvn[j], data=d
                s=size(d.y, /dimensions)
                if n_elements(s) ge 3 then Begin
                   thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Data not degapped.'
                   vn_new=tvn
                endif else Begin                       
                   history_ext = ['new_vars = varnames+''_degap''', $
                             'tdegap, varnames, newname = new_vars, dt = '+$
                             xxx[0]+', margin = '+xxx[1]+', maxgap = '+xxx[2], $
                             'varnames = new_vars']
                   thm_ui_update_history, cw, history_ext
                   thm_ui_update_progress, message_wid = messw, cw, 'Degapping '+tvn(j)
                   tdegap, tvn(j), dt = dtx, margin = mrx, maxgap = maxgapx, newname = vn_new(j)
                   If(is_string(vn_new(j))) Then Begin
                      thm_ui_update_progress, message_wid = messw, cw, 'Done Degapping '+tvn(j)
                      get_data, vn_new(j), data=d
                      if size(d, /type) ne 8 then Begin
                         vn_new(j)=tvn(j)
                         thm_ui_update_progress, message_wid = messw, cw, 'No gaps found for '+tvn(j)
                      endif else Begin   
                         vn_n=[vn_n, vn_new(j)]
                         thm_ui_update_progress, message_wid = messw, cw, 'Done degapping '+tvn(j)
                      endelse                         
                   Endif Else Begin
                      thm_ui_update_progress, message_wid = messw, cw, 'Degapping Unsuccessful, No New Variables'
                      vn_new=tvn
                   Endelse
                 endelse
               endfor
               if n_elements(vn_n) gt 1 then vn_new=vn_n(1:*)
            Endif Else Begin
              emess = 'dt ='+strcompress(string(dtx))+$
                ',margin ='+strcompress(string(mrx))+$
                ',maxgap ='+strcompress(string(maxgapx))
              thm_ui_update_progress, message_wid = messw, cw, 'Invalid Parameters input: '+emess
            Endelse
          Endelse
        End
;wavelet transform?
        'WV':Begin
          vn_new=' '
          vn_n=' '
          for j=0,n_elements(tvn)-1 Do Begin
            get_data, tvn[j], data=d
            s=size(d.y, /dimensions)
             if n_elements(s) ge 3 then Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Wavelet Transform not completed.'
             endif else Begin
                if (n_elements(s) gt 1 && s[1] gt 6) then Begin
                   thm_ui_update_progress, message_wid = messw, cw, 'Y Variable '+tvn(j)+' has > 6 components. Wavelet Transform not completed.'                  
                endif else Begin
                  history_ext = ['thm_ui_wavelet, varnames, new_vars, ['+ $
                         ''''+time_string(st_time)+''''+','+''''+ $
                         time_string(en_time)+''''+']',  'varnames = new_vars']
                  thm_ui_update_history, cw, history_ext
                  thm_ui_update_progress, message_wid = messw, cw, 'Performing wavelet transform on '+tvn(j)
                  thm_ui_wavelet, tvn(j), vn, [st_time, en_time], gui_id = cw, messw_id = messw
                  vn_n = [vn_n, vn]
                  If(is_string(vn_n)) Then ext = string('Wavelet transform finished successfully for '+tvn(j)) $
                  Else ext = 'Unsuccessful'
                  thm_ui_update_progress, message_wid = messw, cw, 'Wavelet Transform: '+ext
              endelse
            endelse
          endfor
          if strlen(vn_n(0)) lt 3 then Begin
             if (n_elements(vn_n) gt 1) then vn_new=vn_n(1:*) else vn_new=tvn
          endif else Begin
             vn_new=vn_n
          endelse       
        End
;Dynamic Power Spectrum?
        'DPWRSPC':Begin
          vn_new=' '
          vn_n=' '
          for j=0,n_elements(tvn)-1 do Begin
             get_data, tvn[j], data=d
             s=size(d.y, /dimensions)
             if n_elements(s) ge 3 then Begin
                thm_ui_update_progress, message_wid = messw, cw, 'Dimensions for '+tvn(j)+' are > 2. Power Spectrum not created.'
             endif else Begin
                if (n_elements(s) gt 1 && s[1] gt 6) then Begin
                  thm_ui_update_progress, message_wid = messw, cw, 'Variable '+tvn(j)+' has > 6 components. Power Spectrum not created.'                  
                endif else Begin
                   history_ext = ['thm_ui_pwrspec, varnames, new_vars, ['+ $
                         ''''+time_string(st_time)+''''+','+''''+ $
                         time_string(en_time)+''''+'], /dynamic',  'varnames = new_vars']
                   thm_ui_update_history, cw, history_ext
                   thm_ui_update_progress, message_wid = messw, cw, 'Creating Dynamic Power Spectrum for '+tvn(j)
                   thm_ui_pwrspc, tvn(j), vn, [st_time, en_time], /dynamic
                   vn_n = [vn_n, vn]
                   thm_ui_update_progress, message_wid = messw, cw, 'Finished Dynamic Power Spectrum for '+tvn(j)
                endelse
             endelse
          endfor
          if strlen(vn_n(0)) lt 3 then Begin
             if (n_elements(vn_n) gt 1) then vn_new=vn_n(1:*) else vn_new=tvn
          endif else Begin
             vn_new=vn_n
          endelse         
        End
        'DELETE':Begin
          history_ext = 'store_data, varnames, /delete'
          stop
          result = yesno_widget_fn('Delete Data', list=['Do you really want to delete this data?',tvn])
          if result eq 1 then Begin
            thm_ui_update_history, cw, history_ext
            thm_ui_update_progress, message_wid = messw, cw, 'Deleting Data'
            store_data, tvn, /delete
            thm_ui_update_progress, message_wid = messw, cw, 'Done Deleting Data'
            widget_control, cw, get_uval = wstate, /no_copy
            If(ptr_valid(wstate.active_vnames)) Then $
              ptr_free, wstate.active_vnames6
            widget_control, cw, set_uval = wstate, /no_copy
          endif
        End
        'SAVE': Begin
          xt = time_string(systime(/sec))
          ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
            '_'+strmid(xt,11,2)+strmid(xt,14,2)+strmid(xt,17,2)
          fff = 'themis_saved_'+ttt
          fff = dialog_pickfile(title = 'Filename For Saved Data:', $
                                filter = '*.tplot', file = fff)
          If(is_string(fff)) Then Begin
            history_ext = 'tplot_save, varnames, filename = '+''''+fff+''''
            thm_ui_update_history, cw, history_ext
            thm_ui_update_progress, message_wid = messw, cw, 'Saving Data'
            tplot_save, tvn, filename = fff
            thm_ui_update_progress, message_wid = messw, cw, 'Saved Data in File: '+fff
          Endif Else Begin
            thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endelse
        End
        'SAVEASCII': Begin
          xt = time_string(systime(/sec))
          ttt = strmid(xt, 0, 4)+strmid(xt, 5, 2)+strmid(xt, 8, 2)+$
            '_'+strmid(xt,11,2)+strmid(xt,14,2)+strmid(xt,17,2)
          fff = 'themis_saved_ascii_'+ttt
          fff = dialog_pickfile(title = 'Root Name For Saved ASCII data:', $
                                filter = '*.txt', file = fff)
          If(is_string(fff)) Then Begin
   	      	history_ext = 'tplot_ascii, varnames, trange = [' + $
            ''''+time_string(st_time)+''''+', '+ $
            ''''+time_string(en_time)+''''+']'
            thm_ui_update_history, cw, history_ext
            thm_ui_update_progress, message_wid = messw, cw, 'Saving Data in ASCII file'
            thm_ui_update_progress, message_wid = messw, cw, 'File Name is: '+fff
            tplot_ascii, tvn, trange = [st_time, en_time], fname = fff, /header
            thm_ui_update_progress, message_wid = messw, cw, 'Finished Saving Data'
          Endif Else Begin
          	thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
          Endelse
        End
        'RENAME': Begin
          ntvn = n_elements(tvn)
          For j = 0, ntvn-1 Do Begin
            pj = thm_ui_par('New Name for variable:'+tvn[j], tvn[j])
            If(pj[0] Eq 'Cancelled') Then Begin
              thm_ui_update_progress, message_wid = messw, cw, 'Operation Cancelled'
            Endif Else Begin
              history_ext = ['store_data,'+''''+tvn[j]+''''+$
                             ', newname ='+''''+pj+'''']
              thm_ui_update_history, cw, history_ext
              thm_ui_update_progress, message_wid = messw, cw, 'Renaming Data'
              pj = strcompress(/remove_all, pj)
              If(pj Ne tvn[j]) Then Begin
                store_data, tvn[j], newname = pj
                thm_ui_update_progress, message_wid = messw, cw, 'Renamed: '+tvn[j]+' to '+pj
              Endif Else Begin
                thm_ui_update_progress, message_wid = messw, cw, $
                  'New name: '+pj+' is the same'
              Endelse
              vn_new[j] = pj
            Endelse
          Endfor
        End
      Endcase

      thm_ui_update_data_all, cw, vn_new
;Set all buttons back to active
      For j = 0, n_elements(button_arr)-1 Do widget_control, button_arr[j], sensitive = 1
    Endif Else Begin
      thm_ui_update_progress, message_wid = messw, cw, 'No Active Dataset, Nothing happened'
    Endelse
    widget_control, event.top, set_uval = state, /no_copy
  Endelse

  Return
End

Pro thm_ui_dproc, gui_id


;build master widget
  master = widget_base(/col, title = 'THEMIS: Data Processing ', $
                             scr_xsize = 465, group_leader = gui_id)
  bmaster = widget_base(master, /row, /align_left, frame = 5) 
  pmaster = widget_base(master, /col, /align_left)                      
;button widgets 
  buttons = widget_base(bmaster, /col, /align_left, xpad=8)
  buttons2 = widget_base(bmaster, /col, /align_left, xpad=8)  
  buttons1 = widget_base(bmaster, /col, /align_left, xpad=8)

;average subtraction button
  subavgbut = widget_button(buttons, val = ' Subtract Average', $
                            uval = 'SUBAVG', scr_xsize = 120)
;median subtraction button
  submedbut = widget_button(buttons, val = ' Subtract Median', $
                            uval = 'SUBMED', scr_xsize = 120)
;tsmooth2 button
  smoothbut = widget_button(buttons, val = ' Smooth Data', uval = 'SMOOTH', $
                            scr_xsize = 120)
;average button
  avgbut = widget_button(buttons, val = ' Block Average', uval = 'AVG', $
                         scr_xsize = 120)
;clip button
  clipbut = widget_button(buttons, val = ' Clip', uval = 'CLIP', $
                         scr_xsize = 120)
;dflag button
  deflagbut = widget_button(buttons, val = ' Deflag', uval = 'DEFLAG', $
                            scr_xsize = 120)
;degap button
  degapbut = widget_button(buttons2, val = ' Degap', uval = 'DEGAP', $
                         scr_xsize = 120)
;dspike button
  spikebut = widget_button(buttons2, val = ' Clean Spikes', uval = 'SPIKE', $
                         scr_xsize = 120)
;deriv button
  derivbut = widget_button(buttons2, val = ' Time Derivative', uval = 'DERIV', $
                         scr_xsize = 120)
;wavelet button
  wavebut = widget_button(buttons2, val = ' Wavelet Transform', uval = 'WV', $
                         scr_xsize = 120)
;power_spectrum button
;  pwrbut = widget_button(buttons, val = ' Power Spectrum', uval = 'PWRSPC', $
;                         scr_xsize = 120)
;dynamic power_spectrum button
  dpwrbut = widget_button(buttons2, val = ' Dpwrspec', $
                          uval = 'DPWRSPC', scr_xsize = 120)


;tlimit button
  tlimitbut = widget_button(buttons2, val = ' Set Time limits ', $
                            uval = 'TLIMIT', /align_center, scr_xsize = 120)

;rename button
  renamebut = widget_button(buttons1, val = ' Rename ', uval = 'RENAME', $
                          scr_xsize = 120)
;save button
  savebut = widget_button(buttons1, val = ' Save ', uval = 'SAVE', $
                          scr_xsize = 120)
;restore button
  restorebut = widget_button(buttons1, val = ' Restore ', uval = 'RESTORE', $
                          scr_xsize = 120)
;save ascii button
  asavebut = widget_button(buttons1, val = ' Save Ascii ', uval = 'SAVEASCII', $
                          scr_xsize = 120)
;delete button
  deletebut = widget_button(buttons1, val = ' Delete ', uval = 'DELETE', $
                            scr_xsize = 120)
;exit button
  exitbut = widget_button(buttons1, val = ' Close ', uval = 'EXIT', $
                          scr_xsize = 120)

;message widget
  messw = widget_text(pmaster, value = '', xsize = 70, ysize = 5, /scroll)

  cw = gui_id
  widget_control, cw, get_uval = wstate, /no_copy
  wstate.proc_id = master
  widget_control, cw, set_uval = wstate, /no_copy

; State structure
  state = {master:master, cw:cw, messw:messw, $
           button_arr:[subavgbut, submedbut, smoothbut, avgbut, clipbut, $
                       deflagbut, degapbut, spikebut, derivbut, wavebut, $
                       dpwrbut, tlimitbut, renamebut, savebut, restorebut, $
                       asavebut, deletebut, exitbut]}

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_dproc', master, /no_block

  Return
End

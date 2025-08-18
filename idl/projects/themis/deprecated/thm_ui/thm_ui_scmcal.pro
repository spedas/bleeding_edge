;+ 
;NAME:
; thm_ui_scmcal
;PURPOSE:
; A widget for choosing data for the THEMIS data analysis GUI
; This was specifically built for SCM data and displays additional
; user inputs for configuration settings
;CALLING SEQUENCE:
; thm_ui_scmcal, gui_id, instr_in0
;INPUT:
; gui_id - gui id number for the main panel
; instr_in0 - instrument name
;OUTPUT:
; cal_params - structure of SCM calibration parameters
;HISTORY:
;AUTHOR: Cindy Goethel
;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-14 10:40:21 -0700 (Thu, 14 Jun 2012) $
;$LastChangedRevision: 10557 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_scmcal.pro $ cal_base
;-

; is_numeric is in a separate file
;function is_numeric,s
;  return,stregex(strtrim(s,2),'^[-+]?(([0-9]+\.?[0-9]*)|([0-9]*\.?[0-9]+))([EeDd][-+]?[0-9]+)?$') eq 0
;end

Pro thm_ui_scmcal_refresh, state 
  Common thm_ui_scmcal0_private, cp_orig, cp_default, cp_current

  ;set the widgets for each parameter
  widget_control, state.widget_ids.mk_text, set_value=cp_current.mk
  widget_control, state.widget_ids.nk_text, set_value=cp_current.nk
  if cp_current.despin eq 1 then $
     widget_control, state.widget_ids.on_despinbutton, /set_button else $
     widget_control, state.widget_ids.off_despinbutton, /set_button 
  widget_control, state.widget_ids.nspin_text, set_value=cp_current.nspins
  index=where(cp_current.cleanup_type eq state.cleanup_values)
  widget_control, state.widget_ids.cleanup_droplist, set_droplist_select=index
  index=where(cp_current.cleanup_author eq state.cauthor_values)
  widget_control, state.widget_ids.cauthor_droplist, set_droplist_select=index
  widget_control, state.widget_ids.wdur1s_text, set_value=cp_current.win_dur_1s
  widget_control, state.widget_ids.wdurst_text, set_value=cp_current.win_dur_st
  if cp_current.dfbb eq 1 then $
     widget_control, state.widget_ids.on_dfbbbutton, /set_button else $
     widget_control, state.widget_ids.off_dfbbbutton, /set_button 
  if cp_current.dfbdf eq 1 then $
     widget_control, state.widget_ids.on_dfbdfbutton, /set_button else $
     widget_control, state.widget_ids.off_dfbdfbutton, /set_button 
  if cp_current.ag eq 1 then $
     widget_control, state.widget_ids.on_agbutton, /set_button else $
     widget_control, state.widget_ids.off_agbutton, /set_button 
  index=where(cp_current.coord_sys eq state.coord_values)
  widget_control, state.widget_ids.coord_droplist, set_droplist_select=index
  widget_control, state.widget_ids.dtrend_text, set_value=cp_current.det_freq
  widget_control, state.widget_ids.lfreq_text, set_value=cp_current.low_freq
  widget_control, state.widget_ids.min_text, set_value=cp_current.freq_min
  widget_control, state.widget_ids.max_text, set_value=cp_current.freq_max
  index=where(cp_current.psteps eq state.process_values)
  widget_control, state.widget_ids.process_droplist, set_droplist_select=index
  index=where(cp_current.edge eq state.edge_values)
  widget_control, state.widget_ids.edge_droplist, set_droplist_select=index
  index=where(cp_current.verbose eq state.verbose_values)
  widget_control, state.widget_ids.verbose_droplist, set_droplist_select=index
  if cp_current.download eq 1 then $
     widget_control, state.widget_ids.on_dlbutton, /set_button else $
     widget_control, state.widget_ids.off_dlbutton, /set_button 
  widget_control, state.widget_ids.insuffix_text, set_value=cp_current.in_suffix
  widget_control, state.widget_ids.outsuffix_text, set_value=cp_current.out_suffix
  widget_control, state.widget_ids.dircal_text, set_value=cp_current.cal_dir

end

Pro thm_ui_choose_dtype_scm_event, event
  Common dtypw, dtyp10, dtyp20, station0, astation0, probe0
  Common dtypw_info, stations, astations, probes, dlist1, dlist2, $
    dlist1_all, dlist2_all, dtyp1, dtyp2
  Common thm_ui_scmcal0_private, cp_orig, cp_default, cp_current

  ;first handle all the errors and checks
  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state)) Then Begin
      cw = state.cw
      widget_control, event.top, set_uval = state, /no_copy
    Endif Else Begin
      widget_control, event.top, get_uval = state, /no_copy
      If(is_struct(state)) Then Begin
        cw = state.cw
        widget_control, event.top, set_uval = state, /no_copy
      Endif Else cw = -1
    Endelse
    If(widget_valid(cw)) Then Begin
      If(is_struct(wstate)) Then Begin
        For j = 0, n_elements(wstate.button_arr)-1 Do widget_control, $
          wstate.button_arr[j], sensitive = 1
        widget_control, cw, set_uval = wstate, /no_copy
      Endif Else Begin
        widget_control, cw, get_uval = wstate, /no_copy
        For j = 0, n_elements(wstate.button_arr)-1 Do widget_control, $
          wstate.button_arr[j], sensitive = 1
        widget_control, cw, set_uval = wstate, /no_copy
      Endelse
      thm_ui_update_history, cw, [';*** FYI', ';'+err_msg]
      thm_ui_update_progress, cw, 'Error--See history'
    Endif
    thm_ui_error
    Return
  Endif

  ;If the 'X' is hit...
  If(TAG_NAMES(event, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST') Then Begin
    If(is_struct(state) Eq 0) Then $
      widget_control, event.top, get_uval = state, /no_copy
    cw = state.cw
    widget_control, event.top, set_uval = state, /no_copy
    If(is_struct(wstate)) Then $
      widget_control, cw, set_uval = wstate, /no_copy
    widget_control, cw, get_uval = wstate, /no_copy
    For j = 0, n_elements(wstate.button_arr)-1 Do widget_control, $
      wstate.button_arr[j], sensitive = 1
    If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
    If(ptr_valid(dtyp2)) Then ptr_free, dtyp2
    widget_control, cw, set_uval = wstate, /no_copy
    widget_control, event.top, /destroy
    thm_ui_update_progress, cw, 'Unexpected Exit from Choose_dtype Widget'
    thm_ui_update_history, cw, ';Unexpected Exit from Choose_dtype Widget'
    Return
  Endif
  
  ;what happened?
  widget_control, event.id, get_uval = uval

  Case uval Of
    'EXIT': widget_control, event.top, /destroy
    'CLEAR_PRST':Begin
      widget_control, event.top, get_uval = state, /no_copy
      widget_control, state.cw, get_uval = wstate, /no_copy
      If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
        If(ptr_valid(wstate.astation)) Then ptr_free, wstate.astation
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = 'asi_station = '+''''+''''
        widget_control, state.messwp, set_val = 'No Chosen Asi_station'
        thm_ui_update_history, state.cw, h
      Endif Else If(state.instr Eq 'gmag') Then Begin
        If(ptr_valid(wstate.station)) Then ptr_free, wstate.station
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = 'gmag_station = '+''''+''''
        widget_control, state.messwp, set_val = 'No Chosen Gmag_station'
        thm_ui_update_history, state.cw, h
      Endif Else Begin
        If(ptr_valid(wstate.probe)) Then ptr_free, wstate.probe      
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = 'probe = '+''''+''''
        widget_control, state.messwp, set_val = 'No Chosen Probe'
        thm_ui_update_history, state.cw, h
      Endelse
      widget_control, event.top, set_uval = state, /no_copy
    End
    'CLEAR_DTYP':Begin
      widget_control, event.top, get_uval = state, /no_copy
      ptr_free, dtyp1
      ptr_free, dtyp2
      widget_control, state.moddata_text, set_val=''
      widget_control, state.messw, set_val = 'No Chosen data types'        
      widget_control, event.top, set_uval = state, /no_copy
    End
    'PRST':Begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.prstlist, /list_select)
      all_chosen = where(pindex Eq 0, nall)
      If(state.instr Eq 'asi' Or state.instr Eq 'ask') Then Begin
        If(nall Gt 0) Then astation0 = astations[1:*] $
        Else astation0 = astations[pindex]
        widget_control, state.cw, get_uval = wstate, /no_copy
        If(ptr_valid(wstate.astation)) Then ptr_free, wstate.astation
        wstate.astation = ptr_new(astation0)
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = thm_ui_multichoice_history('asi_station = ', astation0)
        widget_control, state.messwp, set_val = h          
        thm_ui_update_history, state.cw, h
      Endif Else If(state.instr Eq 'gmag') Then Begin
        If(nall Gt 0) Then station0 = stations[1:*] $
        Else station0 = stations[pindex]
        widget_control, state.cw, get_uval = wstate, /no_copy
        If(ptr_valid(wstate.station)) Then ptr_free, wstate.station
        wstate.station = ptr_new(station0)
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = thm_ui_multichoice_history('gmag_station = ', station0)
        widget_control, state.messwp, set_val = h
        thm_ui_update_history, state.cw, h
      Endif Else Begin
        If(nall Gt 0) Then probe0 = probes[1:*] $
        Else probe0 = probes[pindex]
        widget_control, state.cw, get_uval = wstate, /no_copy
        If(ptr_valid(wstate.probe)) Then ptr_free, wstate.probe
        wstate.probe = ptr_new(probe0)
        widget_control, state.cw, set_uval = wstate, /no_copy
        h = thm_ui_multichoice_history('probe = ', probe0)
        widget_control, state.messwp, set_val = h
        thm_ui_update_history, state.cw, h
      Endelse
      widget_control, event.top, set_uval = state, /no_copy
    End
    'DTYP1':Begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.dtyp1list, /list_select)
      all_chosen = where(pindex Eq 0, nall)
      If(dlist1[0] Ne 'None') Then Begin
        If(nall Gt 0) Then dtyp10 = dlist1[1:*] $
        Else dtyp10 = dlist1[pindex]
        If(state.instr Eq 'esa_pkt') Then Begin
          dtype = strmid(dtyp10, 0, 3)
        Endif Else dtype = dtyp10
        if dtype(0) eq 'scf' then cp_current.mk='8'
        if dtype(0) eq 'scp' then cp_current.mk='4'
        if dtype(0) eq 'scw' then cp_current.mk='1'
        widget_control, state.widget_ids.mk_text, set_value=cp_current.mk
        dtype = state.instr+'/'+dtype+'/l1'
        dtype = strcompress(strlowcase(dtype), /remove_all)
        If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
        dtyp1 = ptr_new(dtype)
        If(ptr_valid(dtyp2)) Then Begin
          If(is_string(*dtyp2)) Then dtype = [dtype, *dtyp2]
        Endif
        h = thm_ui_multichoice_history('Chosen dtypes: ', dtype)
        cal_dtype=''
        if n_elements(dtype) le 1 then Begin
          cal_dtype = strmid(dtype,4,3)
        endif else Begin $
          cal_dtype(0)=strmid(dtype(0),4,3)
          for i=1,n_elements(dtype)-1 do cal_dtype = cal_dtype+', '+strmid(dtype(i),4,3)
        endelse
        h = thm_ui_multichoice_history('Chosen dtypes: ', dtype)
        widget_control, state.moddata_text, set_val = cal_dtype  
        widget_control, state.messw, set_val = h  
      Endif
      widget_control, event.top, set_uval = state, /no_copy
    End
    'DTYP2':Begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.dtyp2list, /list_select)
      all_chosen = where(pindex Eq 0, nall)
      If(dlist2[0] Ne 'None') Then Begin
        If(nall Gt 0) Then dtyp20 = dlist2[1:*] $
        Else dtyp20 = dlist2[pindex]
        dtype = dtyp20
        dtype = state.instr+'/'+dtype+'/l2'
        dtype = strcompress(strlowcase(dtype), /remove_all)
        If(ptr_valid(dtyp2)) Then ptr_free, dtyp2
        dtyp2 = ptr_new(dtype)
        If(ptr_valid(dtyp1)) Then Begin
          If(is_string(*dtyp1)) Then dtype = [*dtyp1, dtype]
        Endif
        h = thm_ui_multichoice_history('Chosen dtypes: ', dtype)
        widget_control, state.messw, set_val = h          
      Endif
      widget_control, event.top, set_uval = state, /no_copy
    End
    'STRTEXT':Begin
      widget_control, event.top, get_uval = state, /no_copy
      widget_control, event.id, get_val = temp_string
      If(temp_string Eq '*') Then Begin
        dlist1 = dlist1_all
        dlist2 = dlist2_all
      Endif Else Begin
        dlist1 = dlist1_all
        dlist2 = dlist2_all
        ts = strcompress(temp_string, /remove_all)
        x1 = strmatch(dlist1, ts, /fold_case)
        tx1 = where(x1 Ne 0, ntx1)
        If(ntx1 Eq 0) Then dlist1 = 'None' $
        Else Begin
          y1 = where(dlist1[tx1] Eq '*')
          If(y1[0] Ne -1) Then dlist1 = dlist1[tx1] $
          Else dlist1 = ['*', dlist1[tx1]]
        Endelse
        ts = strcompress(temp_string, /remove_all)
        x2 = strmatch(dlist2, ts, /fold_case)
        tx2 = where(x2 Ne 0, ntx2)
        If(ntx2 Eq 0) Then dlist2 = 'None' $
        Else Begin
          y2 = where(dlist2[tx2] Eq '*')
          If(y2[0] Ne -1) Then dlist2 = dlist2[tx2] $
          Else dlist2 = ['*', dlist2[tx2]]
        Endelse
      Endelse
      ;reset the values of the datalists
      widget_control, state.dtyp1list, set_val = dlist1
      widget_control, state.dtyp2list, set_val = dlist2
      widget_control, event.top, set_uval = state, /no_copy
    End
    ; now for all the calibration widgets
    'NK': Begin
       widget_control, event.id, get_val=nk
       if (nk ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(nk)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
                'Error - nk value must be numeric'
         endif else Begin
           if (fix(nk) gt 0) then Begin
              cp_current.nk = nk
           endif else Begin
              thm_ui_update_progress, state.cw, message_wid=state.messw, $
                'Error - nk must be greater than 0'
           endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy         
       endif
    end
    'MK': Begin
       widget_control, event.id, get_val=mk
       if (mk ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(mk)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
                'Error - mk value must be numeric'
         endif else Begin
           if (fix(mk) gt 0) then Begin
              cp_current.mk = mk
           endif else Begin
              thm_ui_update_progress, state.cw, message_wid=state.messw, $
                'Error - mk value must be greater than 0'
           endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy         
       endif
    end
    'DESPINON': Begin
       cp_current.despin = 1
     end
    'DESPINOFF': Begin
       cp_current.despin = 0
     end
    'NSPIN': Begin
       widget_control, event.id, get_val=nspin
       if (nspin ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(nspin)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - nspin value must be numeric.'
         endif else Begin
           if fix(nspin) gt 0 then Begin
             cp_current.nspins = nspin
           endif else Begin
             thm_ui_update_progress, state.cw, message_wid=state.messw, $
             'Error - nspin value must be greater than 0.'
           endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'CLEANUP': Begin
       widget_control, event.id
       widget_control, event.top, get_uval = state, /no_copy
       cp_current.cleanup_type= state.cleanup_values(event.index)
       widget_control, event.top, set_uval = state, /no_copy
     end
    'CAUTHOR': Begin
       widget_control, event.id
       widget_control, event.top, get_uval = state, /no_copy
       cp_current.cleanup_author=state.cauthor_values(event.index)
       widget_control, event.top, set_uval = state, /no_copy       
     end
    'WDUR1S': Begin
       widget_control, event.id, get_val=dur
       if (dur ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(dur)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - wind_dur_1s value must be numeric'
         endif else Begin
            if float(dur) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - wind_dur_1s must be positive'
            endif else Begin
              cp_current.win_dur_1s = dur
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'WDURST': Begin
       widget_control, event.id, get_val=dur
       if (dur ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(dur)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - wind_dur_st value must be numeric'
         endif else Begin
            if float(dur) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - wind_dur_st must be positive'
            endif else Begin
              cp_current.win_dur_st = dur
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'DFBBON': Begin
       cp_current.dfbb = 1
     end
    'DFBBOFF': Begin
       cp_current.dfbb = 0
     end
    'DFBDFON': Begin
       cp_current.dfbdf = 1
     end
    'DFBDFOFF': Begin
       cp_current.dfbdf = 0
     end
    'AGON': Begin
       cp_current.ag = 1
     end
    'AGOFF': Begin
       cp_current.ag = 0
     end
    'COORD': Begin
       widget_control, event.id
       widget_control, event.top, get_uval = state, /no_copy
       cp_current.coord_sys=state.coord_values(event.index)
       widget_control, event.top, set_uval = state, /no_copy
     end
    'DTREND': Begin
       widget_control, event.id, get_val=fdet
       if (fdet ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(fdet)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - det_freq value must be numeric'
         endif else Begin
            if float(fdet) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - det_freq must be positive'
            endif else Begin
              cp_current.det_freq = fdet
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'LFREQ': Begin
       widget_control, event.id, get_val=lfreq
       if (lfreq ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(lfreq)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - low_freq value must be numeric'
         endif else Begin
            if float(lfreq) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - low_freq must be positive'
            endif else Begin
              cp_current.low_freq = lfreq
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'MINF': Begin
       widget_control, event.id, get_val=min
       if (min ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(min)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - min_freq value must be numeric'
         endif else Begin
            if float(min) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - min_freq must be positive'
            endif else Begin
              cp_current.freq_min = min
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'MAXF': Begin
       widget_control, event.id, get_val=max
       if (max ne '') then Begin
         widget_control, event.top, get_uval = state, /no_copy
         result=is_numeric(max)
         if result eq 0 then Begin
            thm_ui_update_progress, state.cw, message_wid=state.messw, $
            'Error - max_freq value must be numeric'
         endif else Begin
            if float(max) lt 0.0 then Begin
               thm_ui_update_progress, state.cw, message_wid=state.messw, $
               'Error - max_freq must be positive'
            endif else Begin
              cp_current.freq_max = max
            endelse
         endelse
         widget_control, event.top, set_uval = state, /no_copy
       endif
     end
    'PSTEP': Begin
       widget_control, event.id
       cp_current.psteps=event.index
     end     
    'EDGE': Begin
       widget_control, event.id
       widget_control, event.top, get_uval = state, /no_copy
       cp_current.edge=state.edge_values(event.index)
       widget_control, event.top, set_uval = state, /no_copy
     end     
    'VERBOSE': Begin
       widget_control, event.id
       cp_current.verbose=event.index
     end     
    'DOWNLDON': Begin
       cp_current.download = 1
     end
    'DOWNLDOFF': Begin
       cp_current.download = 0
     end
    'INSUFF': Begin
       widget_control, event.id, get_val=in_suffix
       cp_current.in_suffix = in_suffix
     end 
    'OUTSUFF': Begin
       widget_control, event.id, get_val=out_suffix
       cp_current.out_suffix = out_suffix
     end 
    'CALDIR': Begin
       widget_control, event.id, get_val=cal_dir
       cp_current.cal_dir = cal_dir
     end      
    'RESET': Begin
       cp_current = cp_default
       widget_control, event.id
       widget_control, event.top, get_uval = state, /no_copy
       thm_ui_scmcal_refresh, state
       widget_control, event.top, set_uval = state, /no_copy
     end
    'HELP': Begin
       thm_ui_scmcal_help
     end   
    'CANCEL': Begin
       cp_current=cp_orig
       widget_control, event.top, /destroy
     end   
  Endcase
  help, /struc, cp_current
Return
End

Pro thm_ui_choose_dtype_scm, gui_id, instr_in0

  Common dtypw, dtyp10, dtyp20, station0, astation0, probe0
  Common dtypw_info, stations, astations, probes, dlist1, dlist2, $
    dlist1_all, dlist2_all, dtyp1, dtyp2
  Common thm_ui_scmcal0_private, cp_orig, cp_default, cp_current

  arrx = 'Nothing Here'
  dtyp10 = '' & dtyp20 = '' & station0 = '' & astation0 = ''
  probe0 = '' & instr0 = ''

  If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
  dtyp1 = ptr_new(dtyp1)
  If(ptr_valid(dtyp2)) Then ptr_free, dtyp2
  dtyp2 = ptr_new(dtyp2)
  instr_in = strlowcase(instr_in0)

  ;Get valid datatypes, probes, etc for different data types
  dlist = thm_ui_valid_dtype(instr_in, ilist, llist)
  fl = 'THEMIS Probe'
  probes = ['*', 'a', 'b', 'c', 'd', 'e']
  probes_ext = ['*', 'A (P5)',  'B (P1)',  'C (P2)',  'D (P3)', 'E (P4)']
  prst_val = probes_ext
  xx1 = where(llist Eq 'l1', nxx1)
  If(nxx1 Gt 0) Then Begin
    dlist1_all = ['*', dlist[xx1]] 
    If(instr_in Eq 'fbk') Then Begin
      dlist1_all = ['*', 'fb1', 'fb2', 'fbh']
    Endif
  Endif Else dlist1_all = 'None'
  xx2 = where(llist Eq 'l2', nxx2)
  If(nxx2 Gt 0) Then dlist2_all = ['*', dlist[xx2]] Else dlist2_all = 'None'
  dlist1 = dlist1_all
  dlist2 = dlist2_all

  ;Set up the widget
  tlb = widget_base(/col, title = 'THEMIS: '+$
                      strupcase(instr_in)+': DATA INPUT OPTIONS', $
                      group_leader = gui_id, /tlb_kill_request_events)

  ;Create the 5 base areas for this widget
  list_base = widget_base(tlb, /row, frame=3, /align_center)
  string_base = widget_base(tlb, /col, frame = 3, /align_center)
  cal_base = widget_base(tlb, /col, /align_center)
  button_base = widget_base(tlb, /row, /align_center)
  progress_base = widget_base(tlb, /row, /align_center)

  ;THEMIS Probe list
  probe_base = widget_base(list_base, /col, /align_center)
  flabel = widget_label(probe_base, value = fl)
  prstid = widget_base(probe_base, /row, /align_center)
  prstlist = widget_list(prstid, value = prst_val, xsiz = 8, $
                         ysiz = 10, uval = 'PRST', /mult)
  ;Data level 1 list
  data1_base = widget_base(list_base, /col, /align_center)
  flabel = widget_label(data1_base, value = 'Level 1 Data Quantity')
  dtyp1id = widget_base(data1_base, /row, /align_center)
  dtyp1list = widget_list(dtyp1id, value = dlist1, xsiz = 16, $
                         ysiz = 10, uval = 'DTYP1', /mult)
  ;Data level 2 list
  data2_base = widget_base(list_base, /col, /align_center)
  flabel = widget_label(data2_base, value = 'Level 2 Data Quantity')
  dtyp2id = widget_base(data2_base, /row, /align_center)
  dtyp2list = widget_list(dtyp2id, value = dlist2, xsiz = 16, $
                         ysiz = 10, uval = 'DTYP2', /mult)
                         
  ;input string and clear buttons
  string_button_base=widget_base(string_base, /row, /align_center)
  flabel = widget_label(string_button_base, value = 'String to Match  ')
  strtextw = widget_text(string_button_base, value = '*', $
                         xsiz = 12, $
                         ysiz = 1, uval = 'STRTEXT', $
                         /editable, /all_events)
  space_text=widget_label(string_button_base, value= '    ')
  clearbut1 = widget_button(string_button_base, val = ' Clear Probe/Station ', $
                            uval = 'CLEAR_PRST', /align_center)
  space_text=widget_label(string_button_base, value= '    ')
  clearbut2 = widget_button(string_button_base, val = '   Clear Data Type   ', $
                            uval = 'CLEAR_DTYP', /align_center)

  ; message window
  string_message_base=widget_base(string_base, /col)
  messwp_base=widget_base(string_message_base, /row)
  messwp_label=widget_label(messwp_base, value='Probe: ')
  messwp = widget_text(messwp_base, val = 'No Probe/Station Chosen',$
                       xsize = 62, ysize = 1)
  dmesswp_base=widget_base(string_message_base, /row)
  dmesswp_label=widget_label(dmesswp_base, value='Data:   ')
  dmesswp = widget_text(dmesswp_base, val = 'No Data Chosen',$
                       xsize = 62, ysize = 1)
 
  ;Calibration widget                      
  cal_main_base = widget_base(cal_base, /col, frame=3)
  cal_label_base = widget_base(cal_main_base, /row)
  cal_param_base = widget_base(cal_main_base, /row)
  cal_button_base = widget_base(cal_main_base, /row, /align_center)

  modify_data_base1 = widget_base(cal_label_base, /row, /align_center)
  moddata_label = widget_label(modify_data_base1, value='                                               Modifying Calibration Parameters for: ', /align_center)
  moddata_text = widget_text(modify_data_base1, value=' ', xsize=10)
    
  ;now define the specific widget bases to hold all the parameters
  column1_base = widget_base(cal_param_base, /col)
  column2_base = widget_base(cal_param_base, /col)
                           
  mk_master = widget_base(column1_base, /row)
  mk_label = widget_label(mk_master, value = 'mk (def.- scf 8, scp 4, scw 1): ')
  mk_text = widget_text(mk_master, /edit, val= '', xsize=7, uval='MK',/all_events)

  nk_master = widget_base(column1_base, /row)
  nk_label = widget_label(nk_master, value = 'nk (if set, overrides mk):          ')
  nk_text = widget_text(nk_master, /edit, val= '', xsize=7, uval='NK', /all_events)
                                 
  despin_base = widget_base(column1_base, /row)
  despin_label = widget_label(despin_base, value='Despin:                                  ')
  despin_buttonbase = widget_base(despin_base, /exclusive, /row, uval="DSPIN")
  on_despinbutton = widget_button(despin_buttonbase, value='On', uval='DESPINON')
  off_despinbutton = widget_button(despin_buttonbase, value='Off', uval='DESPINOFF')
  widget_control, on_despinbutton, /set_button
 
  nspin_master = widget_base(column1_base, /row)
  nspin_label = widget_label(nspin_master, value = 'Number Spins to Fit:                ')
  nspin_text = widget_text(nspin_master, /edit, val= '1', uval='NSPIN', xsize=7, /all_events)
        
  cleanup_base = widget_base(column1_base, /row)
  cleanup_label = widget_label(cleanup_base, value='Clean Up:                                ')
  cleanup_values = ['None', 'Spin', 'Full']
  cleanup_droplist = widget_droplist(cleanup_base, value=cleanup_values, uval='CLEANUP', /align_center)
  
  cauthor_base = widget_base(column1_base, /row)
  cauthor_label = widget_label(cauthor_base, value='CleanUp Author:                      ')
  cauthor_values = ['ole', 'ccc']
  cauthor_droplist = widget_droplist(cauthor_base, value=cauthor_values, uval='CAUTHOR', /align_center)
  
  wdur1s_base = widget_base(column1_base, /row)
  wdur1s_label = widget_label(wdur1s_base, value = 'Window Duration 8/32Hz:       ')
  wdur1s_text = widget_text(wdur1s_base, /edit, val= '1.0', uval='WDUR1S', xsize=7, /all_events) 

  wdurst_base = widget_base(column1_base, /row)
  wdurst_label = widget_label(wdurst_base, value = 'Window Duration Spintone:     ')
  wdurst_text = widget_text(wdurst_base, /edit, val= '1.0', uval='WDURST', xsize=7, /all_events) 

  dfbb_base = widget_base(column1_base, /row)
  dfbb_label = widget_label(dfbb_base, value='DFB Buterworth Filter:           ')
  dfbb_buttonbase = widget_base(dfbb_base, /exclusive, /row)
  on_dfbbbutton = widget_button(dfbb_buttonbase, value='On', uval='DFBBON')
  off_dfbbbutton = widget_button(dfbb_buttonbase, value='Off', uval='DFBBOFF')
  widget_control, on_dfbbbutton, /set_button

  dfbdf_base = widget_base(column1_base, /row)
  dfbdf_label = widget_label(dfbdf_base, value='DFB Digital Filter:                  ')
  dfbdf_buttonbase = widget_base(dfbdf_base, /exclusive, /row)
  on_dfbdfbutton = widget_button(dfbdf_buttonbase, value='On', uval='DFBDFON')
  off_dfbdfbutton = widget_button(dfbdf_buttonbase, value='Off', uval='DFBDFOFF')
  widget_control, on_dfbdfbutton, /set_button
  
  ag_base = widget_base(column1_base, /row)
  ag_label = widget_label(ag_base, value='Correct for Antenna Gain:     ')
  ag_buttonbase = widget_base(ag_base, /exclusive, /row)
  on_agbutton = widget_button(ag_buttonbase, value='On', uval='AGON')
  off_agbutton = widget_button(ag_buttonbase, value='Off', uval='AGOFF')
  widget_control, on_agbutton, /set_button

  coord_base = widget_base(column1_base, /row)
  coord_label = widget_label(coord_base, value='Coordinate System:                 ')
  coord_values = ['DSL', 'SSL', 'GSE', 'GEI', 'GSM', 'SPG']
  coord_droplist = widget_droplist(coord_base, value=coord_values, uval='COORD', /align_center)
 
  dtrend_base = widget_base(column2_base, /row)
  dtrend_label = widget_label(dtrend_base, value = 'Detrend Frequency (Hz):        ')
  dtrend_text = widget_text(dtrend_base, /edit, val= '0.0', uval='DTREND', xsize=7, /all_events) 

  lfreq_base = widget_base(column2_base, /row)
  lfreq_label = widget_label(lfreq_base, value = 'Low Frequency cut-off (Hz):   ')
  lfreq_text = widget_text(lfreq_base, /edit, val= '0.1', uval='LFREQ', xsize=7, /all_events) 

  freq_master = widget_base(column2_base, /row)
  flabel_master = widget_base(freq_master, /col, /align_center)
  freq_label = widget_label(flabel_master, value = 'Filter Frequency (Hz): ')
  fstring_master = widget_base(freq_master, /col,frame=3)
  min_master = widget_base(fstring_master, /row)
  min_label = widget_label(min_master, value = 'Min  ')
  min_text = widget_text(min_master, /edit, val='0.1', $
                           xsize = 7, /all_events, uval='MINF')
  max_master = widget_base(fstring_master, /row)
  max_label = widget_label(max_master, value = 'Max ')
  max_text = widget_text(max_master, /edit, val='1.0', $
                           xsize = 7, /all_events, uval='MAXF')
  
  process_values = ['0','1','2','3','4','5'] 
  process_master = widget_base(column2_base, /row)
  process_label = widget_label(process_master, value='Number Processing Steps:      ')
  process_droplist = widget_droplist(process_master, value=process_values, $
                                     uval='PSTEP', /align_center)
  widget_control, process_droplist, set_droplist_select=5
  
  edge_values = ['Zero', 'Wrap', 'Truncate'] 
  edge_master = widget_base(column2_base, /row)
  edge_label = widget_label(edge_master, value='Edge Handling:                       ')
  edge_droplist = widget_droplist(edge_master, value=edge_values, uval='EDGE', /align_center)

  verbose_values = ['0','1','2','3','4','5','6','7','8','9','10'] 
  verbose_master = widget_base(column2_base, /row)
  verbose_label = widget_label(verbose_master, value='Verbose Level:                        ')
  verbose_droplist = widget_droplist(verbose_master, value=verbose_values, $
                                     uval='VERBOSE', /align_center)

  download_base = widget_base(column2_base, /row)
  download_label = widget_label(download_base, value='Download Calibration Files:    ')
  download_buttonbase = widget_base(download_base, /exclusive, /row)
  on_dlbutton = widget_button(download_buttonbase, value='On', uval='DOWNLDON')
  off_dlbutton = widget_button(download_buttonbase, value='Off', uval='DOWNLDOFF')
  widget_control, on_dlbutton, /set_button

  insuffix_base = widget_base(column2_base, /row)
  insuffix_label = widget_label(insuffix_base, value = 'Input Data Suffix:             ')
  insuffix_text = widget_text(insuffix_base, /edit, val= ' ', xsize=18, uval='INSUFF', /all_events) 

  outsuffix_base = widget_base(column2_base, /row)
  outsuffix_label = widget_label(outsuffix_base, value = 'Out Data Suffix:               ')
  outsuffix_text = widget_text(outsuffix_base, /edit, val= ' ', xsize=18, uval='OUTSUFF', /all_events) 

  dircal_base = widget_base(column2_base, /row)
  dircal_label = widget_label(dircal_base, value = 'Calibration Directory:        ')
  dircal_text = widget_text(dircal_base, /edit, val= ' ', uval='CALDIR', xsize=18, /all_events) 

  ;define the help, reset, and default buttons for the calibration parameters
  help_button = widget_button(cal_button_base, value= '        Help        ', uval='HELP')
  reset_button = widget_button(cal_button_base, value= '        Reset        ', uval='RESET')
  
  ; define all the control buttons at the bottom of the panel
  cancel_button = widget_button(button_base, value= '       Cancel       ', uval='CANCEL')
  accept_button = widget_button(button_base, value= '  Accept and Close  ', uval='EXIT')
                       
  ;message windows
  messw = widget_text(progress_base, val = 'No dtypes chosen', $
                      xsize = 80, ysize = 1, /scroll)

  ;widget_array
  widget_ids={mk_text:mk_text, nk_text:nk_text, $
              on_despinbutton:on_despinbutton, $
              off_despinbutton:off_despinbutton, $
              nspin_text:nspin_text, cleanup_droplist:cleanup_droplist,$
              cauthor_droplist:cauthor_droplist, wdur1s_text:wdur1s_text,$
              wdurst_text:wdurst_text, on_dfbbbutton:on_dfbbbutton, $ 
              off_dfbbbutton:off_dfbbbutton, on_dfbdfbutton:on_dfbdfbutton, $
              off_dfbdfbutton:off_dfbdfbutton, on_agbutton:on_agbutton, $
              off_agbutton:off_agbutton, $
              coord_droplist:coord_droplist, $
              dtrend_text:dtrend_text, lfreq_text:lfreq_text, $
              min_text:min_text, max_text:max_text, $
              process_droplist:process_droplist, edge_droplist:edge_droplist, $
              verbose_droplist:verbose_droplist, on_dlbutton:on_dlbutton, $
              off_dlbutton:off_dlbutton, insuffix_text:insuffix_text, $
              outsuffix_text:outsuffix_text, dircal_text:dircal_text} 
                
  ;state structures
  state = {cw:gui_id, dtypw_id:tlb, prstlist:prstlist, dtyp1list:dtyp1list, $
           dtyp2list:dtyp2list, instr:instr_in, messw:messw, messwp:messwp, $
           cleanup_values:cleanup_values, cauthor_values:cauthor_values, $
           process_values:process_values, edge_values:edge_values, $
           moddata_text:moddata_text, verbose_values:verbose_values, $
           coord_values:coord_values, widget_ids:widget_ids}
           
  ;set state structure and realize
  widget_control, tlb, set_uval = state, /no_copy
  widget_control, tlb, /realize
  xmanager, 'thm_ui_choose_dtype_scm', tlb

  ;Now you are done, and can put the data types in the main widget
  widget_control, gui_id, get_uval = wstate, /no_copy
  ;Clear out the dtyp_1 list
  If(ptr_valid(wstate.dtyp_1)) Then ptr_free, wstate.dtyp_1
  wstate.dtyp_1 = ptr_new()
  dtype = ''
  If(ptr_valid(dtyp1)) Then Begin
    If(is_string(*dtyp1)) Then dtype = *dtyp1
  Endif
  If(ptr_valid(dtyp2)) Then Begin
    If(is_string(*dtyp2)) Then Begin
      If(is_string(dtype)) Then dtype = [dtype, *dtyp2] $
      Else dtype = *dtyp2
    Endif
  Endif

  If(is_string(dtype)) Then wstate.dtyp_1 = ptr_new(dtype)
  widget_control, gui_id, set_uval = wstate, /no_copy

End

function thm_ui_scmcal, tlb, instr_in0
common thm_ui_scmcal0_private, cp_orig, cp_default, cp_current

  cp_default = {nk:'', mk:'', despin:1, nspins:'1',$
                cleanup_type:'None', cleanup_author:'ole', win_dur_1s:'1.0', $
                win_dur_st:'1.0', dfbb:1, dfbdf:1, ag:1, det_freq:'0', $
                low_freq:'0.1', freq_min:'0.1', freq_max:'1.0', psteps:5, $
                edge:'Zero', download:1, cal_dir:'', in_suffix:'', $ 
                out_suffix:'', coord_sys:'DSL', verbose:0}
                
  cp_orig = cp_default
  cp_current = cp_default

  thm_ui_choose_dtype_scm, tlb, instr_in0
  return, cp_current
   
end
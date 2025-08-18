;+
;NAME:
; thm_ui_summplot
;PURPOSE:
; This widget prompts the user for a choice of probe, and then Calls
; the thm_gen_overplot routine.
;HISTORY:
; 21-jun-2007, jmm, jimm@ssl.berkeley.edu
; 31-jul-2007, jmm, resets active data in correct order after plotting
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_summplot.pro $
;-
Pro thm_ui_summplot_event, event

  @tplot_com

  err_xxx = 0
  catch, err_xxx
  If(err_xxx Ne 0) Then Begin
    catch, /cancel
    help, /last_message, output = err_msg
    For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
    If(is_struct(state)) Then Begin
      cw = state.cw
      For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 1
      widget_control, event.top, set_uval = state, /no_copy
    Endif Else Begin
      widget_control, event.top, get_uval = state, /no_copy
      If(is_struct(state)) Then Begin
        cw = state.cw
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 1
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
  Endif Else Begin
    ptypp = strmid(uval, 0, 1)
    Case ptypp Of
      'P':Begin
        probe = strcompress(/remove_all, strlowcase(strmid(uval, 6)))
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 0
        cw = state.cw
        widget_control, event.top, set_uval = state, /no_copy
        widget_control, cw, get_uval = wstate, /no_copy
        t0 = wstate.st_time & t1 = wstate.en_time
        widget_control, cw, set_uval = wstate, /no_copy
        If(t0 Eq 0 Or t1 Eq 0) Then Begin
          thm_ui_update_progress, cw, 'Please Choose a Time Range'
        Endif Else Begin
          thm_ui_update_progress, cw, 'Creating Overview Plot, Probe: '+probe
;You need a start time, and a duration in hours
          n_hours = ceil((t1-t0)/3600.0d0)
          history_ext = 'thm_gen_overplot, probe='+''''+probe+''''+$
            ', date ='+''''+time_string(t0)+''''+', dur = '+$
            strtrim(string(n_hours), 2)+', /hours, /dont_delete_data'
          thm_ui_update_history, cw, history_ext
          thm_gen_overplot, probe = probe, date = t0, dur = n_hours, $
            /hours, /dont_delete_data
          tvn0 = strsplit(tplot_vars.options.datanames,' ',/extract)
          history_ext = thm_ui_multichoice_history('varnames = ', tvn0)
          tvn = tvn0
          thm_ui_update_data_all, cw, tvn
;kludge? to reset the active data in the order that it's plotted in
;case someone wants to replot it
          widget_control, cw, get_uval = wstate, /no_copy
          ptr_free, wstate.active_vnames
          wstate.active_vnames = ptr_new(tvn0)
          widget_control, cw, set_uval = wstate, /no_copy
          thm_ui_update_progress, cw, 'Finished Overview Plot, Probe: '+probe
        Endelse
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 1
        widget_control, event.top, set_uval = state, /no_copy
      End
      'I':Begin
        instr = strcompress(/remove_all, strlowcase(strmid(uval, 6)))        
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 0
        cw = state.cw
        widget_control, event.top, set_uval = state, /no_copy
        widget_control, cw, get_uval = wstate, /no_copy
        t0 = wstate.st_time & t1 = wstate.en_time
        widget_control, cw, set_uval = wstate, /no_copy
        If(t0 Eq 0 Or t1 Eq 0) Then Begin
          thm_ui_update_progress, cw, 'Please Choose a Time Range'
        Endif Else Begin
          thm_ui_update_progress, cw, 'Creating Overview Plot, Instrument: '+instr
          date = time_string(t0, precision = -3)
          Case instr Of
            'fgm':Begin
              thm_fgm_overviews, date, /nopng, /dont_delete_data
              history_ext = 'thm_fgm_overviews, '+''''+date+''''+', /nopng, /dont_delete_data'
              thm_ui_update_history, cw, history_ext
;Reset the active data in the order that it's plotted
              tvn0 = strsplit(tplot_vars.options.datanames, ' ', /extract)
              history_ext = thm_ui_multichoice_history('varnames = ', tvn0)
              tvn = tvn0
              thm_ui_update_data_all, cw, tvn
              widget_control, cw, get_uval = wstate, /no_copy
              ptr_free, wstate.active_vnames
              wstate.active_vnames = ptr_new(tvn0)
              widget_control, cw, set_uval = wstate, /no_copy
              thm_ui_update_progress, cw, 'Finished Overview Plot, Instrument: '+instr
            End
            Else: Begin
              thm_ui_update_progress, cw, 'Overview Plot, Instrument: '+instr+' Not Implemented'
            End
          Endcase
        Endelse
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 1
        widget_control, event.top, set_uval = state, /no_copy
      End
      'G':Begin
        instr = strcompress(/remove_all, strlowcase(strmid(uval, 6)))        
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 0
        cw = state.cw
        widget_control, event.top, set_uval = state, /no_copy
        widget_control, cw, get_uval = wstate, /no_copy
        t0 = wstate.st_time & t1 = wstate.en_time
        widget_control, cw, set_uval = wstate, /no_copy
        If(t0 Eq 0 Or t1 Eq 0) Then Begin
          thm_ui_update_progress, cw, 'Please Choose a Time Range'
        Endif Else Begin
          Case instr Of
            'gmag':Begin
              thm_ui_update_progress, cw, 'Creating GMAG Overview Plot'
;You need a start time, and a duration in fractional days
              fdays = (t1-t0)/(24.0d0*3600.0d0)
              history_ext = 'thm_gmag_stackplot, '+''''+time_string(t0)+''''+', '+$
                strtrim(string(fdays), 2)
              thm_ui_update_history, cw, history_ext
              thm_gmag_stackplot, t0, fdays
              tvn0 = ['BH', 'BD', 'BZ']
              history_ext = thm_ui_multichoice_history('varnames = ', tvn0)
              tvn = tvn0
              thm_ui_update_data_all, cw, tvn
              widget_control, cw, get_uval = wstate, /no_copy
              ptr_free, wstate.active_vnames
              wstate.active_vnames = ptr_new(tvn0)
              widget_control, cw, set_uval = wstate, /no_copy
              thm_ui_update_progress, cw, 'Finished GMAG Overview Plot'
            End
            Else:Begin
              thm_ui_update_progress, cw, 'Overview Plot, '+instr+' Not Implemented'
            End
          Endcase
        Endelse
        widget_control, event.top, get_uval = state, /no_copy
        For j = 0, n_elements(state.button_arr)-1 Do widget_control, state.button_arr[j], sensitive = 1
        widget_control, event.top, set_uval = state, /no_copy
      End
    Endcase
  Endelse
  Return
End

Pro thm_ui_summplot, gui_id
  
  master = widget_base(title = 'THEMIS: Overview Plots', $
                       group_leader = gui_id, /col)
  probes = ['a', 'b', 'c', 'd', 'e']
  probes_ext = ['A (P5)',  'B (P1)',  'C (P2)',  'D (P3)', 'E (P4)']
  nprobes = n_elements(probes_ext)
  instruments = ['ESA', 'FGM', 'SST']
  ninstr = n_elements(instruments)
  gbtypes = ['GMAG']
  ngb = n_elements(gbtypes)
  plbut_arr = lonarr(nprobes+ninstr+ngb)
  
  x1 = widget_base(master, /col, /align_center)
  x2 = widget_base(master, /col, /align_center)
  x3 = widget_base(master, /col, /align_center)

;Single probe overviews
  top1 = widget_base(x1, /col, frame = 5, /align_center)
  label = widget_label(top1, value = 'Single Probe Overviews     ')
  For j = 0, nprobes-1 Do Begin
    plbut_arr[j] = widget_button(top1, val = 'THEMIS '+probes_ext[j], $
                                 uval = 'PPLOT_'+strupcase(probes[j]), scr_xsize = 200)
  Endfor
;Single instrument overviews
  top2 = widget_base(x2, /col, frame = 5, /align_center)
  label = widget_label(top2, value = 'Single Instrument Overviews')
  For j = 0, ninstr-1 Do Begin
    j5 = j+nprobes
    plbut_arr[j5] = widget_button(top2, val = 'THEMIS '+instruments[j], $
                                  uval = 'IPLOT_'+strupcase(instruments[j]), scr_xsize = 200)
  Endfor
;Ground-based overviews
  top3 = widget_base(x3, /col, frame = 5, /align_center)
  label = widget_label(top3, value = 'Ground-based Data Overviews')
  For j = 0, ngb-1 Do Begin
    j5 = j+nprobes+ninstr
    plbut_arr[j5] = widget_button(top3, val = 'THEMIS '+gbtypes[j], $
                                  uval = 'GPLOT_'+strupcase(gbtypes[j]), scr_xsize = 200)
  Endfor

;exit button
  exbut = widget_button(master, val = ' Close ', uval = 'EXIT', $
                        /align_center, scr_xsize = 050)

;set summplot_id in main GUI state
  widget_control, gui_id, get_uval = wstate, /no_copy
  wstate.summp_id = master
  widget_control, gui_id, set_uval = wstate, /no_copy
  
  state = {cw:gui_id, button_arr:[plbut_arr, exbut]}

  widget_control, master, set_uval = state, /no_copy
  widget_control, master, /realize
  xmanager, 'thm_ui_summplot', master, /no_block
  

Return
End

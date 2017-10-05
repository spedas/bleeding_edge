;+
;NAME:
; thm_ui_choose_dtype
;PURPOSE:
; A widget for choosing data for the THEMIS data analysis GUI
;CALLING SEQUENCE:
; thm_ui_choose_dtype, instr, dtyp, station, astation, probe
;INPUT:
; instr = the instrument,  one of ['asi', 'ask', 'esa_pkt', $
;           'efi', 'fbk', 'fft', 'fgm', $
;           'fit', 'gmag', 'mom', 'scm', 'sst', 'state']
;OUTPUT:
; dtyp = the output datatype, a string of instr/datatype/datalevel,
;        e.g., 'state/spinras/l1'
; station = the ground station(s) if gmag data was chosen
; astation = the ground station(s) if asi data was chosen
; probe = the spacecraft if spacecraft data was chosen
;HISTORY:
; jmm, jimm@ssl.berkeley.edu 1-may-2007
; jmm, Changed the probe list to reflect probe assigments:
;      A (P5), B (P1), C (P2), D (P3) and E (P4)
;       14-jun-2007
; jmm, correctly handles level 1 and level 2 datatypes, 11-jul-2007
; jmm, really correctly handles level 1 and 2 data types, by using a
;      common block to handle them
; jmm, changed default behavior of windows, when an invalid string is
;      used, then the available data types are set to 'None',
;      31-jul-2007
; jmm, Changed call to thm_ui_valid_dtype to
;      reflect new version, 11-apr-2008
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_choose_dtype.pro $
;-
Pro thm_ui_choose_dtype_event, event
  Common dtypw, dtyp10, dtyp20, station0, astation0, probe0
  Common dtypw_info, stations, astations, probes, dlist1, dlist2, $
    dlist1_all, dlist2_all, dtyp1, dtyp2

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
;  what happened?
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
;      widget_control, state.cw, get_uval = wstate, /no_copy
;      If(ptr_valid(wstate.dtyp)) Then dtyp_all = *wstate.dtyp
;      widget_control, state.cw, set_uval = wstate, /no_copy
;      h = thm_ui_multichoice_history('dtyp =', dtyp_all)
;      thm_ui_update_history, state.cw, h
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
        dtype = state.instr+'/'+dtype+'/l1'
        dtype = strcompress(strlowcase(dtype), /remove_all)
        If(ptr_valid(dtyp1)) Then ptr_free, dtyp1
        dtyp1 = ptr_new(dtype)
        If(ptr_valid(dtyp2)) Then Begin
          If(is_string(*dtyp2)) Then dtype = [dtype, *dtyp2]
        Endif
        h = thm_ui_multichoice_history('Chosen dtypes: ', dtype)
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
  Endcase

Return
End
Pro thm_ui_choose_dtype, gui_id, instr_in0

  Common dtypw, dtyp10, dtyp20, station0, astation0, probe0
  Common dtypw_info, stations, astations, probes, dlist1, dlist2, $
    dlist1_all, dlist2_all, dtyp1, dtyp2

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
  If(instr_in Eq 'asi' Or instr_in Eq 'ask') Then Begin
    fl = 'All-Sky Ground Station'
    If(is_string(astations) Eq 0) Then Begin
      thm_load_asi, /valid_names, site = asi_stations
      astations = ['*', asi_stations]
      astations = strlowcase(strcompress(/remove_all, astations))
    Endif
    prst_val = astations
    dlist1_all = ['*', dlist]
    dlist2_all = 'None'
  Endif Else If(instr_in Eq 'gmag') Then Begin
    fl = 'GMAG Ground Station'
    If(is_string(stations) Eq 0) Then Begin
      thm_load_gmag, /valid_names, site = gmag_stations
      stations = ['*', gmag_stations]
      stations = strlowcase(strcompress(/remove_all, stations))
    Endif
    prst_val = stations
    dlist1_all = 'None'
    dlist2_all = ['*', dlist]
  Endif Else Begin
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
  Endelse
  dlist1 = dlist1_all & dlist2 = dlist2_all
;Set up the widget
  thmds = widget_base(/col, title = 'THEMIS Science Software: '+$
                      strupcase(instr_in)+': DATA INPUT OPTIONS', $
                      group_leader = gui_id, /tlb_kill_request_events)
;Three list widgets, probe/station, level1 quantities, level2
;quantities, One text widget for an input string
;The lists are on top?
  listsw = widget_base(thmds, /row, frame = 5, /align_center)
;The string choice input is on the bottom, also list data types...
  strsw0 = widget_base(thmds, /col, frame = 5, /align_center)
;Probe
  prstw = widget_base(listsw, /col, frame = 5, /align_center)
  flabel = widget_label(prstw, value = fl)
  prstid = widget_base(prstw, /row, /align_center, /frame)
  prstlist = widget_list(prstid, value = prst_val, xsiz = 8, $
                         ysiz = 20, uval = 'PRST', /mult)
;level 1 dtypes
  dtyp1w = widget_base(listsw, /col, frame = 5, /align_center)
  flabel = widget_label(dtyp1w, value = 'Level 1 Data Quantity')
  dtyp1id = widget_base(dtyp1w, /row, /align_center, /frame)
  dtyp1list = widget_list(dtyp1id, value = dlist1, xsiz = 16, $
                         ysiz = 20, uval = 'DTYP1', /mult)
;level2 dtypes
  dtyp2w = widget_base(listsw, /col, frame = 5, /align_center)
  flabel = widget_label(dtyp2w, value = 'Level 2 Data Quantity')
  dtyp2id = widget_base(dtyp2w, /row, /align_center, /frame)
  dtyp2list = widget_list(dtyp2id, value = dlist2, xsiz = 16, $
                         ysiz = 20, uval = 'DTYP2', /mult)
;input string button
  strsw = widget_base(strsw0, /row, /align_center)
  flabel = widget_label(strsw, value = 'String to Match')
  strtextw = widget_text(strsw, value = '*', $
                         xsiz = 12, $
                         ysiz = 1, uval = 'STRTEXT', $
                         /editable, /all_events)
;clear buttons
  clearbut1 = widget_button(strsw, val = ' Clear Probe/Station ', $
                            uval = 'CLEAR_PRST', /align_center)
  clearbut2 = widget_button(strsw, val = ' Clear Data Type ', $
                            uval = 'CLEAR_DTYP', /align_center)
;exit button
  exbut = widget_button(strsw, val = ' Accept and Close ', $
                        uval = 'EXIT', /align_center)
;messagw widget
  messw = widget_text(strsw0, val = 'No dtypes chosen', $
                      xsize = 80, ysize = 1, /scroll)
  messwp = widget_text(strsw0, val = 'No Probe/Station Chosen',$
                       xsize = 80, ysize = 1)
;state structure
  state = {cw:gui_id, dtypw_id:thmds, prstlist:prstlist, dtyp1list:dtyp1list, $
           dtyp2list:dtyp2list, instr:instr_in, messw:messw, messwp:messwp}
  widget_control, thmds, set_uval = state, /no_copy

;  realize
  widget_control, thmds, /realize
  xmanager, 'thm_ui_choose_dtype', thmds

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

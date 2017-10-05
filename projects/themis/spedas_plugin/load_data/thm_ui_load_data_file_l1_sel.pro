;+ 
;NAME:
; thm_ui_load_data_file_l1_sel.pro
;
;PURPOSE:
; Controls actions that occur when selecting items in Level 1 box.  Called by
; thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_l1_sel, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;HISTORY:
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-11-05 10:38:06 -0800 (Thu, 05 Nov 2015) $
;$LastChangedRevision: 19267 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_l1_sel.pro $
;-
pro thm_ui_load_data_file_l1_sel, state

  Compile_Opt idl2, hidden
  
  dlist1 = *state.dlist1
  dlist2 = *state.dlist2
  ;dtyp1 = *state.dtyp1
  ;dtyp2 = *state.dtyp2
  pindex = widget_info(state.level1list, /list_select)
  if ~array_equal(pindex, -1, /no_typeconv) then begin
    all_chosen = where(pindex Eq 0, nall)
    If(dlist1[0] Ne 'None') Then Begin
      If(nall Gt 0) Then dtyp10 = dlist1[1:*] Else dtyp10 = dlist1[pindex]
      if (state.instr eq 'gmag') then begin ;gmag stations are saved in state.station
        if ptr_valid(state.station) then ptr_free, state.station
        state.station = ptr_new(dtyp10)
        dtype = dtyp10
      endif else If(state.instr Eq 'esa_pkt') Then Begin
        dtype = strmid(dtyp10, 0, 3)
      Endif Else dtype = dtyp10
      dtype = state.instr+'/'+dtype+'/l1'
      dtype = strcompress(strlowcase(dtype), /remove_all)
      If(ptr_valid(state.dtyp1)) Then ptr_free, state.dtyp1
      state.dtyp1 = ptr_new(dtype)
      dtyp1 = dtype
      If(ptr_valid(state.dtyp2)) Then Begin
        If(is_string(*state.dtyp2)) Then dtype = [dtype, *state.dtyp2]
      Endif
      if (ptr_valid(state.dtyp)) then ptr_free, state.dtyp
      state.dtyp = ptr_new(dtype)
    Endif
  endif else begin
  
   If(ptr_valid(state.dtyp1)) Then ptr_free, state.dtyp1
;   state.dtyp1 = ptr_new('')
;   dtype = *state.dtyp1
   if ptr_valid(state.dtyp2) then begin
     if (is_string(*state.dtyp2)) then dtype = *state.dtyp2
   endif
   
   if ptr_valid(state.dtyp) then ptr_free, state.dtyp
   state.dtyp = ptr_new(dtype)
     
  endelse
  
;  if is_string(*state.dtyp) then begin
  if ptr_valid(state.dtyp) then begin
    if (is_string(*state.dtyp) AND ~array_equal(*state.dtyp, 'None', /no_typeconv)) then begin
      if is_string(dtype) then begin
        h = spd_ui_multichoice_history('Chosen dtypes: ', dtype)
      endif else begin
        h = 'No chosen L1 data types'
      endelse
    endif else begin
      ptr_free, state.dtyp
      h = 'No chosen L1 data types'
    endelse
  endif else h = 'No chosen L1 data types'
  state.statusText->Update, h
  state.historyWin->Update, 'LOAD DATA: ' + h
  
END

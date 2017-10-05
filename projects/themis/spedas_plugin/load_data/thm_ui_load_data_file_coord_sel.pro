;+
;NAME:
; thm_ui_load_data_file_coord_sel.pro
;
;PURPOSE:
; Controls actions that occur when Output Coordinates menu is selected.  Called
; by thm_ui_load_data_file event handler.
;
;CALLING SEQUENCE:
; thm_ui_load_data_file_coord_sel, state
;
;INPUT:
; state     State structure
;
;OUTPUT:
; None
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-09 14:56:06 -0700 (Thu, 09 Apr 2015) $
;$LastChangedRevision: 17278 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spedas_plugin/load_data/thm_ui_load_data_file_coord_sel.pro $
;-

pro thm_ui_load_data_file_coord_sel, state

  Compile_Opt idl2, hidden

  ; find which level 2 data was selected (if any)
  dlist2 = *state.dlist2
  pindex = widget_info(state.level2list, /list_select)
  all_chosen = where(pindex Eq 0, nall)
  selection_list = -1
  if ~array_equal(pindex, -1, /no_typeconv) then begin
    If (dlist2[0] Ne 'None') Then Begin
      selection_list = dlist2[pindex]
    endif
  endif
  coutCoord1 = ''
  if (state.outCoord ne 'N/A') then coutCoord1 = state.outCoord
  if strlen(coutCoord1) gt 0 then coutCoord1 = "_" + coutCoord1
  coutCoord1len = strlen(coutCoord1)

  ; show the new list for level 2 data
  outCoord = widget_info(state.coordDroplist, /combobox_gettext)
  state.outCoord = strlowcase(strcompress(outCoord, /remove_all))

  h = 'Selected Output Coordinates: ' + state.outCoord
  state.statusText->Update, h
  state.historyWin->Update, 'LOAD DATA: ' + h

  ; reset Level 2 datatype list based on coord type
  thm_ui_load_data_file_itype_sel, state, /from_coord_sel

  ; now check if the old selections are in the new list
  ; if they are, select them again
  dlist2_new = *state.dlist2
  pindex_new = widget_info(state.level2list, /list_select)
  if (dlist2[0] Ne 'None') and (dlist2_new[0] Ne 'None') Then Begin
    if (all_chosen eq 0) then begin
      widget_control, state.level2list, set_list_select=0
    endif else if ~array_equal(pindex, -1, /no_typeconv) then begin
      pindex2 = [-1]
      if coutCoord1 eq state.outCoord then begin
        pindex2 = pindex
      endif else begin
        ; replace old coords with new, for example "_gse" with "_dsl"
        for i = 0, n_elements(selection_list)-1 do begin
          leni = strlen(selection_list[i])
          if (leni ge coutCoord1len) then begin
            if (strmid(selection_list[i], leni-coutCoord1len, coutCoord1len) eq coutCoord1) then begin
              selection_list[i] = strmid(selection_list[i], 0, leni-coutCoord1len) + "_" + state.outCoord
            endif
          endif
          pindex2 = [pindex2,where(dlist2_new eq selection_list[i])]
        endfor
      endelse
      widget_control, state.level2list, set_list_select=pindex2
    endif
  endif
  thm_ui_load_data_file_l2_sel, state

END

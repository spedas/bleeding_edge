;+ 
;NAME:
; spd_ui_do_nudge
;
;PURPOSE:
; Abstracted nudge data operation
;
;
;CALLING SEQUENCE:
; spd_ui_do_nudge,
;
;INPUT:
;  gui_id = widget id of the widget that called this program
;  info = the info structure of the Main GUI
;OUTPUT:
;  fail=fail
;HISTORY:
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-29 13:24:31 -0700 (Wed, 29 Apr 2015) $
;$LastChangedRevision: 17451 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_do_nudge.pro $
;
;---------------------------------------------------------------------------------

pro spd_ui_do_nudge,tn,nshift,shift_unit,shift_scale,use_records,isspec,loadedData,historyWin,$
    statusbar,gui_id,fail=fail,tn1=tn1,replay=replay,overwrite_selections=overwrite_selections

  compile_opt idl2
  
  fail = 1
  
  overwrite_selection = ''
  overwrite_count = 0
  if undefined(replay) then begin
      overwrite_selections = ''
  endif

  ;get variable's data & metadata
  loadeddata->getvardata, name = tn, time = t, $
    data = d, limits = l, dlimits = dl, yaxis = v

  If(ptr_valid(t) Eq 0) Then Begin
     statusbar->update, 'Invalid time pointer: '+tn
     return
  Endif Else Begin
     nshift_str = strcompress(/remove_all, string(nshift))
     If(use_records) Then Begin
        nt = n_elements(*t)
        If(abs(nshift) Ge nt) Then Begin
           ntstr = strcompress(/remove_all, string(nt))
           h = 'Shift value of '+nshift_str+' is GE the number of records:'+ntstr+'. Nudge fails'
           statusbar -> update, h
           historywin -> update, h
           Return
        Endif
        dt_all = (*t)[nt-1]-(*t)[0] ;offset for time arrays
        If(nshift Gt 0) Then Begin
        ; Here you have no clue about what the last record length is, so
        ; assume its the same as the second last record, then append the same array
           dtl = (*t)[nt-1]-(*t)[nt-2]
           t1 = [*t, (dt_all+dtl)+*t]
           ss_shift = lindgen(nt)+nshift ;will be the subscripts of the shifted time array
           t1 = t1[ss_shift]
        Endif Else If(nshift Lt 0) Then Begin
           dtl = (*t)[1]-(*t)[0]
           t1 = [*t-dt_all-dtl, *t]
           ss_shift = lindgen(nt)+nshift+nt ;will be the subscripts of the shifted time array
           t1 = t1[ss_shift]
        Endif Else Return
     Endif Else Begin
        t1 = *t+shift_scale*nshift
     Endelse

      ;Update status, history
      h = 'Nudging: '+tn+' by '+nshift_str+' '+shift_unit
      statusbar->update, h
      historywin->update, h
      tp1 = ptr_new(t1)

      ;Create a new variable name by appending the shift amount
      If((nshift Mod 1.0) Eq 0) Then Begin
          ext = strcompress(string(long(nshift)), /remove_all)
      Endif Else Begin
          ext = strcompress(string(nshift), /remove_all)
      Endelse
      tn1 = tn+'_'+ext+'_'+shift_unit

      ; check if the new tplot variable already exists, query the user to overwrite it if it does
      spd_ui_check_overwrite_data,tn1,loadedData,gui_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
                                 replay=replay,overwrite_selections=overwrite_selections
      if strmid(overwrite_selection, 0, 2) eq 'no' then return   
      
      ;create new data structure
      if isspec && ptr_valid(v) then begin
         data1 = {x:t1, y:*d, v:*v}
      endif else begin
         data1 = {x:t1, y:*d}
      endelse

      ;add new data to GUI
      ok = loadeddata->addData(tn1, temporary(data1), limit=*l, dlimit=*dl)
      
      if ~ok then begin
        statusbar->update, 'Trace Nudge to: '+tn1+' Failed'
        historywin->update, 'Trace Nudge to: '+tn1+' Failed'
        return
      endif
      
      fail = 0
   endelse
 end

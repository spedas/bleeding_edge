;+
;NAME:
; thm_ui_tselect
;PURPOSE:
; A list widget for time selection, this is a blocking widget, it must
; be exited for anything to happen
;CALLING SEQUENCE:
; thm_ui_teslect
;INPUT:
; none
;OUTPUT:
; the selected time is held in the common block saved_time_sel
;HISTORY:
; sep-2006,  jmm,  jimm@ssl.berkeley.edu
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_tselect.pro $
;
;-
Common saved_time_sel, time_selected
pro thm_ui_tselect_event, event
  Common saved_time_sel, time_selected

  this_year = long(strmid(!stime, 7, 4))
  n_years = this_year+2-2005
  xyr = 2005+indgen(n_years)
  xmo = 1+indgen(12)
  pmo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  xdy = 1+indgen(31)
  xhr = indgen(24)
  xmn = indgen(60)
  xsc = indgen(60)
;what happened?
  widget_control, event.id, get_uval = uval
  Case uval Of
    'EXIT': widget_control, event.top, /destroy
    'YR': begin
; get state
      widget_control, event.top, get_uval = state, /no_copy
; get year index
      pindex = widget_info(state.wyr, /list_select)
; update date
      state.ptstruct.year = xyr[pindex]
; save state
      time_selected = state.ptstruct
      widget_control, event.top, set_uval = state, /no_copy
    End
    'MO': begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.wmo, /list_select)
      state.ptstruct.month = xmo[pindex]
      time_selected = state.ptstruct
      widget_control, event.top, set_uval = state, /no_copy
    End 
    'DY': begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.wdy, /list_select)
      state.ptstruct.date = xdy[pindex]
      time_selected = state.ptstruct
      widget_control, event.top, set_uval = state, /no_copy
   End 
   'HR': begin
      widget_control, event.top, get_uval = state, /no_copy
      pindex = widget_info(state.whr, /list_select)
      state.ptstruct.hour = xhr[pindex]
      time_selected = state.ptstruct
      widget_control, event.top, set_uval = state, /no_copy
   End 
   'MN': begin
     widget_control, event.top, get_uval = state, /no_copy
     pindex = widget_info(state.wmn, /list_select)
     state.ptstruct.min = xmn[pindex]
     time_selected = state.ptstruct
     widget_control, event.top, set_uval = state, /no_copy
   End 
   'SC': begin
     widget_control, event.top, get_uval = state, /no_copy
     pindex = widget_info(state.wsc, /list_select)
     state.ptstruct.sec = xsc[pindex]
     time_selected = state.ptstruct
     widget_control, event.top, set_uval = state, /no_copy
   End 
 Endcase
 Return
End

Pro thm_ui_tselect, init_time = init_time, _extra = _extra

  Common saved_time_sel, time_selected

  If(keyword_set(init_time)) Then Begin
    time_selected = time_struct(init_time)
  Endif Else Begin
    time_selected = time_struct('1970-01-01/00:00:00')
  Endelse

;create the widget
  thmtw = widget_base(/col, title = 'THEMIS: Time Interval Selection')
;file browser
  thmtw0 = widget_base(thmtw, /col, /align_center) 
  flabel = widget_label(thmtw0, value = 'Choose Date and time')
  timew = widget_base(thmtw0, /row, frame = 5)

  this_year = long(strmid(!stime, 7, 4))
  n_years = this_year+2-2005

  pyr = strcompress(string(2005+indgen(n_years)))
;  pmo = strcompress(string(1+indgen(12)))
  pmo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  pdy = strcompress(string(1+indgen(31)))
  phr = strcompress(string(indgen(24)))
  pmn = strcompress(string(indgen(60)))
  psc = strcompress(string(indgen(60)))
;  year
  yrwid = widget_base(timew, /row, /frame, /align_top)
  yrlabel = widget_label(yrwid, value = ' year')
  yrlist = widget_list(yrwid, value = pyr, xsiz = 5, $
                       ysiz = 5, uval = 'YR')
  widget_control, yrlist, set_list_top = (n_elements(pyr)-5) > 0
  
;  month
  mowid = widget_base(timew, /row, /frame, /align_top)
  molabel = widget_label(mowid, value = 'month')
  molist = widget_list(mowid, value = pmo, xsiz = 4, ysiz = 12, $
                       uval = 'MO')

;  day
  dywid = widget_base(timew, /row, /frame, /align_top)
  dylabel = widget_label(dywid, value = '  day')
  dylist = widget_list(dywid, value = pdy, xsiz = 4, ysiz = 31, $
                       uval = 'DY')
; hour
  hrwid = widget_base(timew, /row, /frame, /align_top)
  hrlabel = widget_label(hrwid, value = ' hour')
  hrlist = widget_list(hrwid, value = phr, xsiz = 4, ysiz = 24, $
                       uval = 'HR')
; minute
  mnwid = widget_base(timew, /row, /frame, /align_top)
  mnlabel = widget_label(mnwid, value = '  min')
  mnlist = widget_list(mnwid, value = pmn, xsiz = 4, ysiz = 31, $
                       uval = 'MN')
; second
  scwid = widget_base(timew, /row, /frame, /align_top)
  sclabel = widget_label(scwid, value = '  sec')
  sclist = widget_list(scwid, value = psc, xsiz = 4, ysiz = 31, $
                       uval = 'SC')
;  exit button
  butwid = widget_base(thmtw, /col, /align_center)
  exbut = widget_button(butwid, val = ' Accept and Close ', uval = 'EXIT', $
                        /align_center)

  state={wyr:yrlist, wmo:molist, wdy:dylist, whr:hrlist, $
         wmn:mnlist, wsc:sclist, $
         ptstruct:time_selected}
  widget_control, thmtw, set_uval = state, /no_copy

;  realize
  widget_control, thmtw, /realize
  xmanager, 'thm_ui_tselect', thmtw
End

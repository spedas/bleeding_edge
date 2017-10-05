;+
;NAME:
; thm_ui_only_trange
;PURPOSE:
; This program oprerates on the tplot data_quants to strip out data
; the is not in the input time range: start time, end time, and the
; subscripts of the appropriate data_quants structures are used, this
; is designed to be used in thm_ui_load_data_fn only... jmm,
; 13-nov-2006
;INPUT:
; st_time, en_time = time in seconds from 1-jan-1970 0:00
; data_ss = the subscripts of the data array to on which to operate
;OUTPUT:
; None explicit, the tplot variables are changed
;HISTORY:
; jmm, 13-nov-2006, jimm@ssl.berkeley.edu
; jmm, 13-dec-2006, made to work for non thg_mag data
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_only_trange.pro $
;
;-

Pro thm_ui_only_trange, st_time0, en_time0, data_ss
;-
  st_time = time_double(st_time0) &  en_time = time_double(en_time0)
  ndss = n_elements(data_ss)
  For j = 0, ndss-1 Do Begin
    j1 = data_ss[j]
    If(j1 Gt 0) Then Begin
      tplotvars = tnames()
      get_data, tplotvars[j1-1], data = dd
      If(is_struct(dd)) Then Begin
        szy = size(dd.y)
        ok_arr = where(dd.x Ge st_time And dd.x Lt en_time, nok_arr)
        If(nok_arr Gt 0) Then Begin
          xj = dd.x[ok_arr]
          If(szy[0] Eq 1) Then yj = dd.y[ok_arr] $
          Else If(szy[0] Eq 2) Then yj = dd.y[ok_arr, *] $
          Else If(szy[0] Eq 3) Then yj = dd.y[ok_arr, *, *] $
          Else If(szy[0] Eq 4) Then yj = dd.y[ok_arr, *, *, *] $;overkill?
          Else Begin
            xj = dd.x & yj = dd.y
          Endelse
          str_element, dd, 'x', xj, /add_replace
          str_element, dd, 'y', yj, /add_replace
          store_data, tplotvars[j1-1], data = temporary(dd)
        Endif
      Endif
    Endif
  Endfor
  Return
 End

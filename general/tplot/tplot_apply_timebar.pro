;+
;NAME:
; tplot_apply_timebar
;PURPOSE:
; Plots vertical lines (timebars) for plotted tplot variables, if
; there is a timebar tag in the limits structure for those
; variables. To set values, use the 'options' programs: e.g., 

;  options, 'tha_efs', 'timebar', {time:'2016-07-01 '+['06:22', '07:00']}

; sets two vertical lines for the 'tha_efs' variable..

; Then call

;  tplot_apply_timebar

;  options, 'tha_efs', 'timebar', {time:'2016-07-01/'+['06:22','07:00'], color:[3, 6], linestyle:2, thick:2.0}

; Adds color for each of the lines. Linestyle and thick are also
; options for the timebar; color, linestyle and thick can be arrays or scalars

; The timebar value only needs to be a structure if other options are set
; options, 'tha_efs', 'timebar', '2016-07-07/06:12'
; will work

; Note that tplot needs to have been called previously
;CALLING SEQUENCE:
; tplot_apply_timebar
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; varname = if set, only do the timebars for the named variable(s)
; clear = if set, clear the options for the affected variable
;HISTORY:
; 2016-07-29, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-10 12:29:12 -0700 (Mon, 10 Oct 2016) $
; $LastChangedRevision: 22074 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_apply_timebar.pro $
;-
Pro tplot_apply_timebar, varname = varname, clear = clear

@tplot_com ;the tplot_vars.options structure tells us what's on the plot

  If(keyword_set(varname)) Then vn = tnames(varname) Else Begin
     If(is_struct(tplot_vars) && is_struct(tplot_vars.options)) Then Begin
        If(tag_exist(tplot_vars.options, 'varnames') && $
           is_string(tplot_vars.options.varnames)) Then Begin
           vn = tnames(tplot_vars.options.varnames)
        Endif Else Return
     Endif Else Return
  Endelse

  If(~is_string(vn)) Then Begin
     dprint, 'No Valid tplot variables available'
     Return
  Endif

  nvn = n_elements(vn)
  For j = 0, nvn-1 Do Begin
;Check limits for timebar tag
     get_data, vn[j], limits = al, dlimits = dl
;clear the timebar if requested
     If(keyword_set(clear)) Then Begin
        If(is_struct(al) && tag_exist(al, 'timebar')) Then Begin
           str_element, al, 'timebar', /delete
           store_data, vn[j], limits = al
        Endif        
        If(is_struct(dl) && tag_exist(dl, 'timebar')) Then Begin
           str_element, dl, 'timebar', /delete
           store_data, vn[j], dlimits = dl
        Endif
        Continue
     Endif
;Otherwise apply timebar
     If(is_struct(al) && tag_exist(al, 'timebar')) Then Begin
        tb = al.timebar ;tb can be an array or structure
        If(~is_struct(tb)) Then tb = {time: time_double(tb)}
     Endif Else If(is_struct(dl) && tag_exist(dl, 'timebar')) Then Begin
        tb = dl.timebar ;tb can be an array or structure
        If(~is_struct(tb)) Then tb = {time: time_double(tb)}
     Endif Else tb = 0b
;Call 'timebar' program to add to plot, if needed
     If(is_struct(tb)) Then Begin
        If(tag_exist(tb, 'color')) Then clr = tb.color Else clr = 0
        If(tag_exist(tb, 'linestyle')) Then lns = tb.linestyle Else lns = 0
        If(tag_exist(tb, 'thick')) Then thk = tb.thick Else thk = 0
        timebar, tb.time, color = clr, linestyle = lns, thick = thk, varname = vn[j]
     Endif
  Endfor

  Return
End

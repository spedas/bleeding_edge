;+
;NAME:
; tplot_apply_databar
;PURPOSE:
; Plots horizontal lines (databars) for plotted tplot variables, if
; there is a databar tag in the limits structure for those
; variables. To set values, use the 'options' programs: e.g., 

;  options, 'tha_efs', 'databar', {yval:[-5., 0, 5.0]}

; Then call

;  tplot_apply_databar

; sets three vertical lines for the 'tha_efs' variable..
; Color, linestyle and thick can be included, for each value, or one
; scalar for all:

; options, 'tha_efs', 'databar', {yval:[-5., 0, 5.0], color = [2,4,6], linestyle = 2, thick = [2.0, 1.0, 2.0]}

; The timebar value only needs to be a structure if other options are set
; options, 'tha_efs', 'databar', [6, 7, 8]
; will work

; Note that tplot needs to have been called previously
;CALLING SEQUENCE:
; tplot_apply_databar
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; varname = if set, only do the databars for the named variable(s)
; clear = if set, clear out the databar options for the affected variables
;HISTORY:
; 2016-07-29, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-10-10 12:29:12 -0700 (Mon, 10 Oct 2016) $
; $LastChangedRevision: 22074 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_apply_databar.pro $
;-
Pro tplot_apply_databar, varname = varname, clear = clear

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
;Check limits for databar tag
     get_data, vn[j], limits = al, dlimits = dl
;Clear databar if requested
     If(keyword_set(clear)) Then Begin
        If(is_struct(al) && tag_exist(al, 'databar')) Then Begin
           str_element, al, 'databar', /delete
           store_data, vn[j], limits = al
        Endif        
        If(is_struct(dl) && tag_exist(dl, 'databar')) Then Begin
           str_element, dl, 'databar', /delete
           store_data, vn[j], dlimits = dl
        Endif
        Continue
     Endif
;Otherwise apply databar
     If(is_struct(al) && tag_exist(al, 'databar')) Then Begin
        db = al.databar ;db can be an array or structure
        If(~is_struct(db)) Then db = {yval: time_double(db)}
     Endif Else If(is_struct(dl) && tag_exist(dl, 'databar')) Then Begin
        db = dl.databar
        If(~is_struct(db)) Then db = {yval: time_double(db)}
     Endif Else db = 0b
;Call 'databar' program to add to plot, if needed
     If(is_struct(db)) Then Begin
        nyval = n_elements(db.yval) ;timebar does not handle multiple inputs in the same manner for databars
        If(tag_exist(db, 'color')) Then Begin 
           clr0 = db.color
           If(n_elements(clr0) Eq nyval) Then clr = clr0 $
           Else clr = intarr(nyval)+clr0[0]
        Endif Else clr = intarr(nyval)
        If(tag_exist(db, 'linestyle')) Then Begin 
           lns0 = db.linestyle
           If(n_elements(lns0) Eq nyval) Then lns = lns0 $
           Else lns = intarr(nyval)+lns0[0]
        Endif Else lns = intarr(nyval)
        If(tag_exist(db, 'thick')) Then Begin 
           thk0 = db.thick
           If(n_elements(thk0) Eq nyval) Then thk = thk0 $
           Else thk = fltarr(nyval)+thk0[0]
        Endif Else thk = intarr(nyval)
        For k = 0, nyval-1 Do Begin
           timebar, db.yval[k], color = clr[k], linestyle = lns[k], $
                    thick = thk[k], varname = vn[j], /databar
        Endfor
     Endif
  Endfor

  Return
End

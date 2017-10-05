;+
;NAME:
; spd_new_units
; 
;PURPOSE:
; sets units in the dlimits structure of input tplot variables from
; the CDF attributes, or alternatively, input keywords
; 
;CALLING SEQUENCE:
; spd_new_units,vars,units_in=units_in
; 
;INPUT:
; vars = variable names
; 
;OUTPUT:
; none explicit, the dlimits structure of the variables are changed
; 
;KEYWORDS:
; units_in = if set, then the units for all vars will be set to this
;            value (this is a scalar input)
;            
;HISTORY:
; 12-feb-2008, jmm, jimm@ssl.berkeley.edu
; 
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-07 12:01:16 -0700 (Fri, 07 Oct 2016) $
;$LastChangedRevision: 22068 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_new_units.pro $
;-
Pro spd_new_units, vars, units_in = units_in

;add units, systems to variables
  new_v = tnames(vars)
  if ~keyword_set(new_v) then return ;check if tnames returned an empty string
  For j = 0, n_elements(new_v)-1 Do Begin
    get_data, new_v[j], dlimits = dl
    If(is_string(units_in)) Then units = units_in[0] Else Begin
      units = 'none'
;check for units in cdf.vatt's, if it exists, if not, then no units will be set
      If(is_struct(dl)) Then Begin
        str_element, dl, 'cdf', success = yes_cdf
        If(yes_cdf Gt 0) Then Begin
          str_element, dl.cdf, 'vatt', success = yes_vatt
          If(yes_vatt) Then Begin
            str_element, dl.cdf.vatt, 'units', units_test, success = yes_units
            If(yes_units) Then units = units_test
          Endif
        Endif
      Endif
    Endelse
;check for dlimits structure, if it doesn't exist, make one, and add
;data_att structure, if it does exist, change or add the 'units' tag
;if applicable
    If(units Ne 'none') Then Begin
      If(is_struct(dl)) Then Begin
        str_element, dl, 'data_att', success = yes_data_att
        If(yes_data_att) Then Begin ;data_att exists, add or replace the units
          data_att = dl.data_att
          str_element, data_att, 'units', units, /add_replace
        Endif Else data_att = {units:units} ;data_att doesn't exist, so build it
;now add or replace the data_att
        str_element, dl, 'data_att', data_att, /add_replace
      Endif Else Begin          ;no dlimits
        data_att = {units:units}
        dl = {data_att:data_att}
      Endelse
      store_data, new_v[j], dlimits = dl
    Endif                       ;no changes if there are no units to add
  Endfor

  Return
End

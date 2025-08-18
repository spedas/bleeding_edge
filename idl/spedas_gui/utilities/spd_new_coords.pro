;+
;NAME:
; spd_new_coords
; 
;PURPOSE:
; sets coordinate systems in the dlimits structure of input
; tplot variables from the CDF attributes, or alternatively, input
; keywords
; 
;CALLING SEQUENCE:
; spd_new_coords,vars,coords_in=coords_in
; 
;INPUT:
; vars = variable names
; 
;OUTPUT:
; none explicit, the dlimits structure of the variables are changed
; 
;KEYWORDS:
; coords_in = if set, then the coords for all vars will be set to this
;             value (this is a scalar input)
;             
;HISTORY:
; 12-feb-2008, jmm, jimm@ssl.berkeley.edu
; 
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-07-30 17:43:20 -0700 (Wed, 30 Jul 2025) $
;$LastChangedRevision: 33516 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_new_coords.pro $
;-
Pro spd_new_coords, vars, coords_in = coords_in

;add coords, coordinate systems to variables
  new_v = tnames(vars)
  If(is_string(new_v) Eq 0) Then Return
  For j = 0, n_elements(new_v)-1 Do Begin
    get_data, new_v[j], dlimits = dl
    If(is_string(coords_in)) Then coords = coords_in[0] Else Begin
      coords = 'none'
;check cdf.vatt's, if it exists, if not, then no coords will be set
      If(is_struct(dl)) Then Begin
        str_element, dl, 'cdf', success = yes_cdf
        If(yes_cdf Gt 0) Then Begin
          str_element, dl.cdf, 'vatt', success = yes_vatt
          If(yes_vatt) Then Begin
            str_element, dl.cdf.vatt, 'coordinate_system', $
              coords_test, success = yes_coords
            If(yes_coords) Then coords = coords_test
          Endif
        Endif
      Endif
    Endelse
;check for dlimits structure, if it doesn't exist, make one, and add
;data_att structure, if it does exist, change or add the 'coords' tag
;if applicable
    If(coords Ne 'none') Then Begin
      ; convert to lowercase and remove spaces
      coords = strcompress(strlowcase(coords), /remove_all)
      ; remove any CDF comments ('>' and everything after)
      pos = STRPOS(coords, '>')
      if pos NE -1 then coords = STRMID(coords, 0, pos)
      If(is_struct(dl)) Then Begin
        str_element, dl, 'data_att', success = yes_data_att
        If(yes_data_att) Then Begin ;data_att exists, add or replace the coords
          data_att = dl.data_att
          str_element, data_att, 'coord_sys', coords, /add_replace
        Endif Else data_att = {coord_sys:coords} ;data_att doesn't exist, so build it
;now add or replace the data_att
        str_element, dl, 'data_att', data_att, /add_replace
      Endif Else Begin          ;no dlimits
        data_att = {coord_sys:coords}
        dl = {data_att:data_att}
      Endelse
      store_data, new_v[j], dlimits = dl
    Endif                       ;no changes if there are no coords to add
  Endfor

  Return
End

;+
;NAME:
; tpwrspc
;PURPOSE:
; wapper for pwrspc.pro for calling from GUI, a split_vec is performed
; on the data if necessary
;CALLING SEQUENCE:
; thm_ui_pwrspc, varnames, new_names, trange, history_ext, $
;                polar = polar, dynamic = dynamic, _extra = _extra
;INPUT:
; varnames = an array (or scalar) of tplot variable names
;Output
; new_names = the variable names of any new variables
;HISTORY:
; 28-mar-2007, jmm, jimm.ssl.berkeley.edu
; 2-apr-2007, jmm, added the /dynamic keyword
; 5-jun-2007, jmm, no longer handles history
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_pwrspc.pro $
;-
Pro thm_ui_pwrspc, varnames, new_names, trange, $
                   polar = polar, dynamic = dynamic, _extra = _extra

;First extract the data
  new_names = ''
  n = n_elements(varnames)
;Now do split_vec if necessary, then the power spectrum
  For j = 0, n-1 Do Begin
    get_data, varnames[j], data = data
    If(is_struct(data)) Then Begin 
      ndj = n_elements(data.y[0, *])
      If(ndj Eq 3) Then Begin
        split_vec, varnames[j], polar = polar, names_out = vn_j
      Endif Else If(ndj Gt 1) Then Begin
        split_vec, varnames[j], names_out = vn_j, $
          suffix = '_'+strcompress(string(indgen(ndj)), /remove_all)
      Endif Else vn_j = varnames[j]
    Endif Else vn_j = ''
;Do the transform
    If(is_string(vn_j)) Then Begin
      nvnj = n_elements(vn_j)
      For k = 0, nvnj-1 Do Begin
        If(keyword_set(dynamic)) Then Begin
          tdpwrspc, vn_j[k], trange = trange, _extra = _extra
          new_names = [new_names, vn_j[k]+'_dpwrspc']
        Endif Else Begin
          tpwrspc, vn_j[k], trange = trange, _extra = _extra
          new_names = [new_names, vn_j[k]+'_pwrspc']
        Endelse
      Endfor
    Endif
  Endfor
;What are the new names?
  If(n_elements(new_names) Gt 1) Then new_names = new_names[1:*]
  Return
End

;+
; This puts the input data structure into the tplot common block as
; the data_quants structure, and undefines all of the other variables
; in the common block, using temporary, the original common block is
; saved in a different common block. This is needed to call the
; stackmagplot routine on a subset of stations
; 13-nov-2006, jmm, jimm@ssl.berkeley.edu
;
;$LastChangedBy: cgoethel $
;$LastChangedDate: 2008-07-08 08:41:22 -0700 (Tue, 08 Jul 2008) $
;$LastChangedRevision: 3261 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/deprecated/thm_ui/thm_ui_reset_common_block.pro $
;
;-
Pro thm_ui_reset_common_block, data_ss,  restore = restore

  @tplot_com                      ;defines the common block
  common tplot_temp, data_quants2, tplot_vars2, tplot_configs2, current_config2

  If(keyword_set(restore)) Then Begin
    If(n_elements(data_quants2) Gt 0) Then data_quants = temporary(data_quants2)
    If(n_elements(tplot_vars2) Gt 0) Then tplot_vars = temporary(tplot_vars2)
    If(n_elements(tplot_configs2) Gt 0) Then tplot_configs = temporary(tplot_configs2)
    If(n_elements(current_config2) Gt 0) Then current_config = temporary(current_config2)
  Endif Else Begin
    If(n_elements(data_quants) Gt 0) Then data_quants2 = temporary(data_quants)
    If(n_elements(tplot_vars) Gt 0) Then tplot_vars2 = temporary(tplot_vars)
    If(n_elements(tplot_configs) Gt 0) Then tplot_configs2 = temporary(tplot_configs)
    If(n_elements(current_config) Gt 0) Then current_config2 = temporary(current_config)
    data_quants = [data_quants2[0], data_quants2[data_ss]]
  Endelse
  Return
End

  


 

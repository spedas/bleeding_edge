;+
; PROCEDURE:
;         tplot_remove_panel
;
; PURPOSE:
;         Remove panel(s) from the current tplot window
;
; INPUT:
;         panel: int or array of ints containing panel #s 
;                to remove from the current tplot window
;                (starts at 0 at the top)
;                
;                also accepts string or array of strings
;                containing variable names to be removed
;                
; EXAMPLES:
;   IDL> tplot, ['var1', 'var2', 'var3']
;   
;   to remove 'var2' from the figure:
;   
;   IDL> tplot_remove_panel, 'var2'
;   
;   or:
;   
;   IDL> tplot_remove_panel, 1
;   
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-07-10 13:21:07 -0700 (Wed, 10 Jul 2019) $
;$LastChangedRevision: 27433 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_remove_panel.pro $
;-

pro tplot_remove_panel, panel
  compile_opt idl2
  
  @tplot_com.pro
  if undefined(panel) then begin
    dprint, dlevel=0, 'Please specify a panel # to remove from the current tplot window'
    return
  endif
  
  current_vars = tplot_vars.options.varnames
  out_vars = current_vars
  
  for panel_idx=0, n_elements(panel)-1 do begin
    if size(panel[panel_idx], /type) eq 2 || size(panel[panel_idx], /type) eq 3 then begin
      if panel[panel_idx] gt n_elements(current_vars)-1 then begin
        dprint, dlevel=0, 'Panel does not exist'
        continue
      endif
      var_to_remove = current_vars[panel[panel_idx]]
      vars_to_keep = where(out_vars ne var_to_remove, keepcount)
      if keepcount ne 0 then out_vars = out_vars[vars_to_keep]
      if keepcount eq 0 then begin
        dprint, dlevel=0, 'Can not remove all panels from figure'
        return
      endif
    endif else if size(panel[panel_idx], /type) eq 7 then begin
      ; the user supplied the variable name instead of panel #
      findvar = where(current_vars eq panel[panel_idx], varcount)
      
      if varcount eq 0 then begin
        dprint, dlevel=0, 'Panel does not exist'
        continue
      endif
      
      var_to_remove = current_vars[findvar[0]]
      vars_to_keep = where(out_vars ne var_to_remove[0], keepcount)
      if keepcount ne 0 then out_vars = out_vars[vars_to_keep]
      if keepcount eq 0 then begin
        dprint, dlevel=0, 'Can not remove all panels from figure'
        return
      endif
    endif
  endfor
  
  tplot, out_vars
end
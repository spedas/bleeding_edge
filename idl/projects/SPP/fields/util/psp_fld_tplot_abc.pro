;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-07-24 16:40:58 -0700 (Thu, 24 Jul 2025) $
; $LastChangedRevision: 33496 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_tplot_abc.pro $
;
;-

pro psp_fld_tplot_abc
  compile_opt idl2

  @tplot_com

  if n_elements(tplot_vars) eq 0 then return

  nv = n_elements(tplot_vars.settings.varnames)

  lbl = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', $
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']

  lbl = '(' + lbl

  lbl = lbl + ')'

  if nv gt 0 then begin
    for i = 0, nv - 1 do begin
      name = tplot_vars.settings.varnames[i]

      get_data, name, alim = lim

      str_element, lim, 'panel_label', pl, success = has_pl

      if has_pl eq 0 then $
        tplot_panel_label, name, lbl[i], /lower_left

      ; from an earlier version before tplot_panel_label routine was created
      ; c = tplot_vars.settings.clip[*, i]

      ; name = tplot_vars.settings.varnames[i]

      ; if strpos(name, 'dummy') eq -1 then begin
      ; get_data, tplot_vars.settings.varnames[i], dat = d, al = al

      ; if size(/type, d) eq 8 then begin
      ; multi = 0
      ; pl_vars = tplot_vars.settings.varnames[i]
      ; endif else begin
      ; multi = 1
      ; pl_vars = d
      ; ; stop
      ; endelse

      ; foreach pl_var, pl_vars, pl_var_i do begin
      ; delvar, al

      ; get_data, pl_var, al = al

      ; str_element, al, 'spec', spec, success = is_spec

      ; str_element, al, 'panel_label', pl, success = has_pl

      ; ; if has_pl then begin

      ; delvar, plc
      ; delvar, plcs
      ; delvar, plct
      ; delvar, pla
      ; delvar, plxn
      ; delvar, plyn

      ; str_element, al, 'panel_label_color', plc, success = has_plc
      ; str_element, al, 'panel_label_charsize', plcs, success = has_plcs
      ; str_element, al, 'panel_label_charthick', plct, success = has_plct
      ; str_element, al, 'panel_label_align', pla, success = has_pla
      ; str_element, al, 'panel_label_xnorm', plxn, success = has_plxn
      ; str_element, al, 'panel_label_ynorm', plyn, success = has_plyn

      ; ; if has_pl then stop

      ; if has_pl then lbl[i] = pl.label

      ; print, c
      ; print, pl_var
      ; print, has_plcs

      ; ; if is_spec then begin
      ; ; if spec EQ 1 then color = 255 else color = 0
      ; ; endif else begin
      ; ; color = 0
      ; ; endelse

      ; delvar, color
      ; delvar, charsize
      ; delvar, charthick
      ; delvar, align

      ; if has_plc then color = plc else color = 0
      ; if has_plcs then charsize = plcs else charsize = 0
      ; if has_plct then charthick = plct else charthick = 0
      ; if has_pla then align = pla else align = 0.5
      ; if has_plxn then plxn = plxn else plxn = 0.1
      ; if has_plyn then plyn = plyn else plyn = 0.2

      ; if !d.name eq 'PS' then device, /HELVETICA, /BOLD

      ; if has_pl or (multi eq 0) or (pl_var_i eq 0) then begin
      ; if color eq 255 then xyouts, $
      ; c[0] + (c[2] - c[0]) * plxn, $
      ; c[1] + (c[3] - c[1]) * plyn, lbl[i], $
      ; /device, $
      ; align = align, charsize = charsize, charthick = charthick + 4, $
      ; color = 0

      ; xyouts, $
      ; c[0] + (c[2] - c[0]) * plxn, $
      ; c[1] + (c[3] - c[1]) * plyn, lbl[i], $
      ; /device, $
      ; align = align, charsize = charsize, charthick = charthick, $
      ; color = color
      ; endif

      ; if !d.name eq 'PS' then device, /helvetica

      ; ; endif
      ; endforeach
      ; endif
    endfor
  endif
end

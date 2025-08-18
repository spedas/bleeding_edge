pro spp_fld_sc_pse_5hz_mf_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if not keyword_set(prefix) then prefix = 'spp_fld_sc_pse_5hz_mf'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  ; sc_hk_gc_names = tnames(prefix + '*')

  ; if sc_hk_gc_names[0] NE '' then begin

  ; for i = 0, n_elements(sc_hk_gc_names) - 1 do begin

  ; name = sc_hk_gc_names[i]
  ; ytitle = name

  ; ytitle = ytitle.Remove(0, prefix.Strlen()-1)

  ; ytitle = ytitle.Replace('_','!C')

  ; options, name, 'ynozero', 1
  ; options, name, 'colors', [2]
  ; options, name, 'ytitle', ytitle
  ; ;options, name, 'psym', 4
  ; options, name, 'psym_lim', 200
  ; options, name, 'symsize', 0.75
  ; options, name, 'datagap';, 1200d

  ; endfor

  ; endif
end

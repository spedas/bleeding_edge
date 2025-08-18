function spp_fld_dcb_ssr_telemetry_ticks, axis, index, number
  compile_opt idl2

  mach = machar()
  eps = mach.eps

  if (number - long(number)) lt eps then begin
    return, string(number, format = '(I12)')
  endif else begin
    return, ''
  endelse
end

pro spp_fld_dcb_ssr_telemetry_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_ssr_telemetry_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  get_data, prefix + 'ARCWRPTR', data = ssr_ptr
  get_data, prefix + 'AWININX', data = ssr_ptr_frac

  store_data, prefix + 'AWRITE', $
    data = {x: ssr_ptr.x, $
      y: ssr_ptr.y + ssr_ptr_frac.y / 256.d}

  dcb_ssr_telemetry_names = tnames(prefix + '*')

  if dcb_ssr_telemetry_names[0] ne '' then begin
    for i = 0, n_elements(dcb_ssr_telemetry_names) - 1 do begin
      name = dcb_ssr_telemetry_names[i]

      options, name, 'ynozero', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', 'DCB SSR!C' + name.remove(0, prefix.strlen() - 1)

      options, name, 'ysubtitle', ''

      if prefix eq 'spp_fld_dcb_ssr_telemetry_' then $
        options, name, 'ytickformat', 'spp_fld_dcb_ssr_telemetry_ticks'

      ; options, name, 'psym', -4
      options, name, 'psym_lim', 100
      options, name, 'symsize', 0.5

      options, name, 'datagap', 600
    endfor
  endif

  arc_ptrs = ['ARCWRPTR', 'ARCRDPTR']

  foreach arc_ptr, arc_ptrs do begin
    tname = prefix + arc_ptr

    tname_gbit = tname + '_Gbit'

    get_data, tname, data = d_ptr, al = al

    if size(/type, d_ptr) eq 8 then begin
      ; FIELDS SSR storage:
      ; 256 Gibit = 256 * 1024^3 bits
      ;
      ; 512 blocks (value reported in ARCWRPTR) = 1 Gibit
      ;
      ; Max block number = 512 * 256 = 131072
      ;
      ; The item created below gives the value in Gbit = 1000^3 bits
      ; Our allocation from the spacecraft is given in Gbits
      ;
      ; Conversion factor: 1 Gibit = 1.0737 Gbit

      store_data, tname_gbit, lim = al, $
        data = {x: d_ptr.x, y: d_ptr.y / (512d) * (1024d / 1000d) ^ 3}

      options, tname_gbit, 'ysubtitle', 'Gbit'
      options, tname_gbit, 'yrange', [0, 275]
      options, tname_gbit, 'ystyle', 1
      options, tname_gbit, 'yticks', 11
      options, tname_gbit, 'panel_size', 2
      options, tname_gbit, 'ytickv', indgen(12) * 275 / 11
    endif
  endforeach

  options, prefix + '*', 'yticklen', 1
  options, prefix + '*', 'xticklen', 1
  options, prefix + '*', 'xgridstyle', 1
  options, prefix + '*', 'ygridstyle', 1
  options, prefix + '*', 'yminor', 1
end
function spp_fld_dcb_ssr_telemetry_ticks, axis, index, number

  mach = machar()
  eps = mach.eps

  IF (number - long(number)) LT eps then begin
    return, string(number, format = '(I12)')
  endif else begin
    return, ''
  endelse

end

pro spp_fld_dcb_ssr_telemetry_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_ssr_telemetry_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  get_data, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR', data = ssr_ptr
  get_data, 'spp_fld_dcb_ssr_telemetry_AWININX', data = ssr_ptr_frac

  store_data, 'spp_fld_dcb_ssr_telemetry_AWRITE', $
    data = {x:ssr_ptr.x, $
    y:ssr_ptr.y + ssr_ptr_frac.y / 256.d}

  dcb_ssr_telemetry_names = tnames(prefix + '*')

  if dcb_ssr_telemetry_names[0] NE '' then begin

    for i = 0, n_elements(dcb_ssr_telemetry_names)-1 do begin

      name = dcb_ssr_telemetry_names[i]

      options, name, 'ynozero', 1
      ;options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', 'DCB SSR!C' + name.Remove(0, prefix.Strlen()-1)

      options, name, 'ysubtitle', ''

      options, name, 'ytickformat', 'spp_fld_dcb_ssr_telemetry_ticks'

      ;options, name, 'psym', -4
      options, name, 'psym_lim', 100
      options, name, 'symsize', 0.5

      options, name, 'datagap', 600


    endfor

  endif

  get_data, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR', data = d_wptr, al = al

  if size(/type, d_wptr) EQ 8 then begin

    store_data, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', lim = al, $
      data = {x:d_wptr.x, y:d_wptr.y/(512d) * (1024d/1000d)^3}

    options, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', 'ysubtitle', 'Gbit'
    options, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', 'yrange', [0,275]
    options, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', 'ystyle', 1
    options, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', 'yticks', 11
    options, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR_Gbit', 'ytickv', indgen(12) * 275 / 11

  endif

  options, 'spp_fld_dcb_ssr_telemetry_*', 'xticklen', 1
  options, 'spp_fld_dcb_ssr_telemetry_*', 'yticklen', 1
  options, 'spp_fld_dcb_ssr_telemetry_*', 'xgridstyle', 1
  options, 'spp_fld_dcb_ssr_telemetry_*', 'ygridstyle', 1

end
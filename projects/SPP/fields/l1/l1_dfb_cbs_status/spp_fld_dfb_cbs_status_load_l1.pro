;function spp_fld_dcb_ssr_telemetry_ticks, axis, index, number
;
;  mach = machar()
;  eps = mach.eps
;
;  IF (number - long(number)) LT eps then begin
;    return, string(number, format = '(I12)')
;  endif else begin
;    return, ''
;  endelse
;
;end

pro spp_fld_dfb_cbs_status_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_cbs_status_'

  cdf2tplot, /get_support_data, file, prefix = prefix

;  get_data, 'spp_fld_dcb_ssr_telemetry_ARCWRPTR', data = ssr_ptr
;  get_data, 'spp_fld_dcb_ssr_telemetry_AWININX', data = ssr_ptr_frac
;
;  store_data, 'spp_fld_dcb_ssr_telemetry_AWRITE', $
;    data = {x:ssr_ptr.x, $
;    y:ssr_ptr.y + ssr_ptr_frac.y / 256.d}

  dcb_cbs_status_names = tnames(prefix + '*')

  if dcb_cbs_status_names[0] NE '' then begin

    for i = 0, n_elements(dcb_cbs_status_names)-1 do begin

      name = dcb_cbs_status_names[i]

      title = name.Remove(0, prefix.Strlen()-1)
      
      ;title = title.Replace('HOLD', 'H')
      ;title = title.Replace('EBUFF', 'E')
      title = title.Replace('TYPE', '!CTYPE')
      title = title.Replace('SCM', '!CSCM')
      title = title.Replace('IMM', '!CIMM')
      title = title.Replace('BRSTQ', '!CBRSTQ')

      options, name, 'ynozero', 1
      options, name, 'colors', [0]
      options, name, 'ytitle', 'DFB!CCBS!C' + title

      options, name, 'ysubtitle', ''

;      options, name, 'ytickformat', 'spp_fld_dcb_ssr_telemetry_ticks'

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endfor

  endif
  
  options, prefix + '*TYPE', 'yrange', [-0.25, 1.25]
  options, prefix + '*TYPE', 'yticks', 1
  options, prefix + '*TYPE', 'ytickv', [0,1]
  options, prefix + '*TYPE', 'ytickname', ['DFB','DCB']
  options, prefix + '*TYPE', 'ystyle', 1
  options, prefix + '*TYPE', 'yminor', 1
  options, prefix + '*TYPE', 'panel_size', 0.35
  options, prefix + '*TYPE', 'ysubtitle', ''

  options, prefix + '*SCM', 'yrange', [-0.25, 1.25]
  options, prefix + '*SCM', 'yticks', 1
  options, prefix + '*SCM', 'ytickv', [0,1]
  options, prefix + '*SCM', 'ytickname', ['No','SCM']
  options, prefix + '*SCM', 'ystyle', 1
  options, prefix + '*SCM', 'yminor', 1
  options, prefix + '*SCM', 'panel_size', 0.35
  options, prefix + '*SCM', 'ysubtitle', ''

  options, prefix + '*IMM', 'yrange', [-0.25, 1.25]
  options, prefix + '*IMM', 'yticks', 1
  options, prefix + '*IMM', 'ytickv', [0,1]
  options, prefix + '*IMM', 'ytickname', ['No','SCM']
  options, prefix + '*IMM', 'ystyle', 1
  options, prefix + '*IMM', 'yminor', 1
  options, prefix + '*IMM', 'panel_size', 0.35
  options, prefix + '*IMM', 'ysubtitle', ''

;  options, prefix + '*TYPE', 'yrange', [-0.5, 3.5]
;  options, prefix + '*TYPE', 'yticks', 3
;  options, prefix + '*TYPE', 'ytickv', [0,1,2,3]
;  options, prefix + '*TYPE', 'ytickname', ['DFB','DCB', 'SCM', 'Rand']
;  options, prefix + '*TYPE', 'ystyle', 1
;  options, prefix + '*TYPE', 'yminor', 1
;  options, prefix + '*TYPE', 'panel_size', 0.55
;  options, prefix + '*TYPE', 'ysubtitle', ''

;  options, prefix + '*BRSTQ', 'yrange', [0, 256]
;  options, prefix + '*BRSTQ', 'yticks', 4
;  options, prefix + '*BRSTQ', 'ystyle', 1
;  options, prefix + '*BRSTQ', 'yminor', 4
;  options, prefix + '*BRSTQ', 'ysubtitle', ''

  options, prefix + '*DCBH0*', 'colors', [1]
  options, prefix + '*DCBH1*', 'colors', [2]
  options, prefix + '*DCBH2*', 'colors', [3]

  options, prefix + '*DFBH0*', 'colors', [4]
  options, prefix + '*DFBH1*', 'colors', [5]
  options, prefix + '*DFBH2*', 'colors', [6]

end
;+
;Checks ASK MLAT and MLON values for v02 cal files versus v01 values
;for the first tme in each file.
;Input station, output cal01 and cal02 are the output cal structures.
;example: 
;test_ask_cal2, 'gill'
;Plots will show version 02 ask mlat, mlon as line, version 01 ask
;mlat, mlon as red plus signs.
Pro test_ask_cal2, station, cal01, cal02
;-

  thm_load_asi_cal, station, cal02
  thm_load_asi_cal, station, cal01, file_version_in = 1

  a = where(cal02.vars.name Eq 'thg_asf_'+station+'_mlat')
  f_mlat02 = *cal02.vars[a].dataptr
  b = where(cal02.vars.name Eq 'thg_ask_'+station+'_mlat')
  k_mlat02 = *cal02.vars[b].dataptr

  a = where(cal02.vars.name Eq 'thg_asf_'+station+'_mlon')
  f_mlon02 = *cal02.vars[a].dataptr
  b = where(cal02.vars.name Eq 'thg_ask_'+station+'_mlon')
  k_mlon02 = *cal02.vars[b].dataptr

  a = where(cal02.vars.name Eq 'thg_asf_'+station+'_mlat')
  f_mlat01 = *cal01.vars[a].dataptr
  f_mlat01 = reform(f_mlat01[1, *, *])
  b = where(cal01.vars.name Eq 'thg_ask_'+station+'_mlat')
  k_mlat01 = *cal01.vars[b].dataptr
  k_mlat01 = reform(k_mlat01[1, *])

  a = where(cal01.vars.name Eq 'thg_asf_'+station+'_mlon')
  f_mlon01 = *cal01.vars[a].dataptr
  f_mlon01 = reform(f_mlon01[1, *, *])
  b = where(cal01.vars.name Eq 'thg_ask_'+station+'_mlon')
  k_mlon01 = *cal01.vars[b].dataptr
  k_mlon01 = reform(k_mlon01[1, *])


;PLots
  !p.multi = [0, 2, 1]
  plot, k_mlat02, title = 'ASK Mlat values: '+station+', Line-v02, pluses-v01', $
        xtitle = 'pixel', ytitle = 'MLAT (degrees)', /ynozero
  oplot, k_mlat01, psym = 1,  color = 6
  oplot, k_mlat02

  plot, k_mlon02, title = 'ASK Mlon values: '+station+', Line-v02, pluses-v01', $
        xtitle = 'pixel', ytitle = 'MLON (degrees)', /ynozero
  oplot, k_mlon01, psym = 1,  color = 6
  oplot, k_mlon02

  print,  'Testing minmax(mlat(version 02) - mlat(version 01))'
  print, minmax(k_mlat02-k_mlat01)
  print,  'Testing minmax(mlon(version 02) - mlon(version 01))'
  print, minmax(k_mlon02-k_mlon01)


End


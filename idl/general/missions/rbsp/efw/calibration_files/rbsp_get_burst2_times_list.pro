;Return structure with burst 2 start/stop times, duration, and
;sample rate for specified timerange

;Written by Aaron W Breneman, Jan 16, 2020

function rbsp_get_burst2_times_list,sc

  tr = timerange()

  ;grab IDL save file with burst2 info
  homedir = (file_search('~',/expand_tilde))[0]+'/'
  path = homedir + 'Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/calibration_files/'
  fn = 'burst2_times_RBSP'+sc+'.sav
  restore,path+fn


  d0d = time_double(d0)
  d1d = time_double(d1)
  goodstartI = where((d0d ge tr[0]) and (d0d le tr[1]))
  uniquevals = bytarr(n_elements(goodstartI))


  ;Find start/stop times that fall within timerange specified
  if goodstartI[0] ne -1 then begin
    goodstartT = d0d[goodstartI]
    goodendT = dblarr(n_elements(goodstartT))
    durationfin = duration[goodstartI]
    for q=0,n_elements(goodstartI)-1 do begin
      if d1d[goodstartI[q]] le tr[1] then goodendT[q] = d1d[goodstartI[q]]
      if d1d[goodstartI[q]] gt tr[1] then goodendT[q] = tr[1]
      if goodstartT[q] ne goodendT[q] then uniquevals[q] = 1
    endfor
  endif


  ;Remove elements if the start and stop times are the same. This happens when
  ;burst collection crosses day boundaries.
  if total(uniquevals gt 0) then begin
    startT = goodstartT[where(uniquevals)]
    endT = goodendT[where(uniquevals)]
    durationfin2 = durationfin[where(uniquevals)]
  endif

;Test output
;  for i=0,n_elements(startT)-1 do print,time_string(startT[i]) + ' ' + time_string(endT[i]) + ' ' + string(durationfin2[i]) + ' ' + string(srfin2[i])

  if keyword_set(startT) and keyword_set(endT) then $
    vals = {startb2:startT,endb2:endT,duration:durationfin2} else $
    vals = {startb2:!values.f_nan,endb2:!values.f_nan,duration:!values.f_nan}


  return,vals

end

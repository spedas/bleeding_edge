;Load maneuver (thruster firing) times for RBSP for current timerange.
;Uses the final thruster firing files saved locally
;(originally from EMFISIS at https://emfisis.physics.uiowa.edu/events/rbsp-a/thruster/).
;Returns a structure with the start and stop times.
;Returns NaN values if there are no maneuvers within timerange.


function rbsp_load_maneuver_times,sc

  tmpp = findpath('rbsp_load_maneuver_times.pro',/exact,path)
  fn = 'rbsp-'+sc+'_thruster_firing_times.txt'

  tr = timerange()

  t0 = strarr(10000)
  t1 = strarr(10000)


  openr,lun,path+'/'+fn,/get_lun
  tmp = '' & readf,lun,tmp


  i = 0L
  while not eof(lun) do begin $
    readf,lun,tmp  & $
    t0[i] = strmid(tmp,0,19) & $
    t1[i] = strmid(tmp,31,19) & $
    i++
  endwhile

  close,lun & free_lun,lun

  goo = where(t0 eq '')
  t0 = t0[0:goo[0]-1]
  t1 = t1[0:goo[0]-1]

  t0d = time_double(t0)
  t1d = time_double(t1)


  goodmaneuver = where((tr[0] le t0d) and (t0d le tr[1]))

  estart = !values.f_nan & eend = estart
  if goodmaneuver[0] ne -1 then begin
    estart = t0d[goodmaneuver]
    eend =   t1d[goodmaneuver]
  endif

  maneuvertimes = {estart:estart,eend:eend}

  return,maneuvertimes




end

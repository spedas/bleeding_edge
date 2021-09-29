;Load eclipse times for RBSP for current timerange.
;Uses the final eclipse files saved locally.
;(originally from EMFISIS at https://emfisis.physics.uiowa.edu/events/rbsp-a/eclipse/).
;Returns a structure with the start and stop times.
;Returns NaN values if there are no eclipses within timerange.


function rbsp_load_eclipse_times,sc


  tmpp = findpath('rbsp_load_eclipse_times.pro',/exact,path)
  fn = 'rbsp-'+sc+'_eclipse_times.txt'


  tr = timerange()

  t0 = strarr(10000)
  t1 = strarr(10000)


  openr,lun,path+'/calibration_files/'+fn,/get_lun
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


  goodeclipse = where((tr[0] le t0d) and (t0d le tr[1]))

  estart = !values.f_nan & eend = estart
  if goodeclipse[0] ne -1 then begin
    estart = t0d[goodeclipse]
    eend =   t1d[goodeclipse]
  endif

  eclipsetimes = {estart:estart,eend:eend}

  return,eclipsetimes

end

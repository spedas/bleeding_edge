;Load SDT sweep test times for RBSP for current timerange.
;Uses the final SDT list for each sc saved locally.
;Returns a structure with the start and stop times.
;Returns NaN values if there are no sweeps within timerange.

;Note that this list was compiled from two separate lists:
;1) Sheng's list that identified guard and usher voltage changes
;2) Gabe's list that tracked the HSK variable SDRPWRCTL (SDRAM protection bit)
;Between these two lists all the SDT sweeps seem to have been identified, along
;with other times where things go "wonky"...but these should be flagged anyways.

function rbsp_load_sdt_times,sc


  tmpp = findpath('rbsp_load_sdt_times.pro',/exact,path)
  fn = 'rbsp'+sc+'_bias_sweep_times.txt'


  tr = timerange()

  t0 = strarr(10000)
  t1 = strarr(10000)


  openr,lun,path+'/'+fn,/get_lun
  tmp = '' & readf,lun,tmp


  i = 0L
  while not eof(lun) do begin $
    readf,lun,tmp  & $
    t0[i] = strmid(tmp,0,19) & $
    t1[i] = strmid(tmp,20,19) & $
    i++
  endwhile

  close,lun & free_lun,lun

  goo = where(t0 eq '')
  t0 = t0[0:goo[0]-1]
  t1 = t1[0:goo[0]-1]

  t0d = time_double(t0)
  t1d = time_double(t1)



  goodsdt = where((tr[0] le t0d) and (t0d le tr[1]))

  estart = !values.f_nan & eend = estart
  if goodsdt[0] ne -1 then begin
    estart = t0d[goodsdt]
    eend =   t1d[goodsdt]
  endif

  sdttimes = {sdtstart:estart,sdtend:eend}

  return,sdttimes

end

;+
;Routine uses an apid data to produce a tplot variable containing the energy of the bin that the peak eflux is in at each timestep.
;Mass keyword can be set.
;
;mvn_sta_[apid]_energypeak: the energy (in eV) that the peak eflux lies in at each timestep. 
;
;trange: [a,b]: UNIX double start and stop times to calculate parameters over. If not set, entire time range available is used.
;
;mrange: AMU mass range [a,b]. Default is all masses [0, 50] if not set.
;m_int: assumed mass, default is average of mrange if mrange is set and m_int is not. If mrange is not set, m_int=32. Note, I don't think
;       this matters for this routine. 
;
;sta_apid: string: STATIC apid to use. Default is c6 if not set.
;
;output: the output data as a named variable.
;
;Set /scpot to correct peak energy for the spacecraft potential. This routine assumes that mvn_scpot has been run, and will use these values.
;   If this routine has not been run, it will be run automatically.
;   mvn_scpot will be run based on the current timespan set, so ensure this covers the date range you require.
;
;EG:
;timespan, '2019-01-01', 1.
;mvn_sta_l2_load, sta_apid=['c6', 'ca']
;mvn_sta_l2_tplot
;mvn_sta_c6_energy_peak
;
;Testing only:
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_energy_peak.pro
;-

pro mvn_sta_energy_peak, trange=trange, success=success, mrange=mrange, m_int=m_int, sta_apid=sta_apid, output=output, scpot=scpot

proname='mvn_sta_energy_peak'

if not keyword_set(sta_apid) then sta_apid='c6'
if not keyword_set(mrange) then begin
    mrange=[0., 50.]
    if not keyword_set(m_int) then m_int=32.
endif
if not keyword_set(m_int) then m_int = mean(mrange,/nan)

cols=get_colors()

res1 = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)
res2 = execute("dat0 = all_dat_"+sta_apid)

if size(dat0, /type) ne 8 then begin
  print, ""
  print, proname, " : you must load STATIC data into common blocks first using mvn_sta_l2_load, sta_apid=[]."
  success=0
  return
endif


;Pick all times if trange not set:
midT0 = (dat0.time+dat0.end_time)/2d  ;all midtimes
if keyword_set(trange) then begin
  iTIME = where(midT0 ge trange[0] and midT0 le trange[1], neleT)
endif else begin
  neleT = n_elements(dat0.time)
  iTIME = findgen(neleT)
endelse

;ARRAYS:
dat_en_arr = fltarr(neleT)  ;energy of peak eflux bin
midT1 = midT0[iTIME]  ;midtimes for data requested

;Loop over c6 and find energy of peak eflux:
for tt = 0l, neleT-1l do begin
  ;ttSTR = strtrim(string(tt),2)
  tnumber = strtrim(string(iTIME[tt]),2)
  res3 = execute("datTMP1 = mvn_sta_get_"+sta_apid+"(index="+tnumber+")")

  datTMP2 = conv_units(datTMP1, 'eflux')
  
  datTMP3 = sum4m(datTMP2, mass=mrange, m_int=m_int)
  
  m1 = max(datTMP3.data, imax, /nan)

  ;Find closest
  dat_en_arr[tt] = datTMP3.energy[imax]

endfor  ;tt

;Correct for sc pot if requested:
if keyword_set(scpot) then begin
  mvn_sta_tplot_scpot, sta_apid=sta_apid   ;generates tplot variable mvn_sta_c6_cb_scpot, where 'c6' is replaced with sta_apid.
  
  tname_scp = 'mvn_sta_'+sta_apid+'_cb_scpot'
  get_data, tname_scp, data=ddscp
  
  ;Another for loop is probably the slow way to do this, but it's the simplest:
  for tt = 0l, neleT-1l do begin
      diff = abs(midT1[tt] - ddscp.x)
      min1 = min(diff, imin, /nan)
      
      if min1 lt 5. and finite(ddscp.y[imin]) eq 1 then dat_en_arr[tt] += ddscp.y[imin]  ;get within one timestamp (should be the same one)
 
  endfor
  
endif

tname = 'mvn_sta_'+sta_apid+'_energypeak_('+strtrim(string(mrange[0], format='(F7.2)'),2)+'__'+strtrim(string(mrange[1], format='(F7.2)'),2)+')'

store_data, tname, data={x: midT1, y: dat_en_arr}
  ylim, tname, 0.1, 3E4
  options, tname, ylog=1
  options, tname, ytitle='STA energypeak!C'+sta_apid+'[eV]'

output = dat_en_arr

success=1

end



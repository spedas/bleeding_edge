;+
;Routine extracts bkg counts and counts for a specified sta_apid and mass range. These are each saved into separate tplot variables.
;The routine then flags when counts ~< bkg, for the specified threshold.
;
;Flag=0 means ok, flag=1 means background counts are significant compared to counts.
;
;INPUTS:
;massrange: [a,b]: floats: AMU mass range to look at.
;
;sta_apid: string: 'c6', 'd1', etc. Apid to look at.
;
;KEYWORDS:
;trange: [a,b] : double UNIX time: time range to look at. If not set, routine looks at full time range in the relevant common block.
;tplotname: string: the base tplotname to use for the output variables. Variables will have the format:
;           tplotname_tot_cnts - total dat.cnts
;           tplotname_bkg_cnts - total dat.bkg
;           tplotname_flag_cnts - 0 if dat.cnts is statistically significant compared to dat.bkg; 1 if this is not the case.
;           If not set, tplotname will be set to 'sta_cnts'.
;
;REQUIREMENTS:
;Load STATIC data into common blocks before hand.
;
;EXAMPLES:
;timespan, '2020-01-01', 1.
;mvn_sta_l2_load, sta_apid='c6'
;mvn_sta_cnt_bkg_flag, massrange=[12., 20.], sta_apid='c6', tplotname='mvn_sta_c6'
;     
;         
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_cnt_bkg_flag.pro
;-

pro mvn_sta_cnt_bkg_flag, massrange, sta_apid, trange=trange, success=success, tplotname=tplotname

  proname = 'mvn_sta_cnt_bkg_flag'

  if size(sta_apid,/type) ne 7 then begin
    print, proname, ": You must set sta_apid."
    success=0
    return
  endif
    
  if size(massrange,/type) eq 0 then begin
    print, proname, ": You must set the massrange [a,b]."
    success=0
    return
  endif
  
  if size(tplotname,/type) ne 7 then tplotname='sta_cnts'
  
  ;Get data from relevant common block:
  res1 = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)
  res2 = execute("datall = all_dat_"+sta_apid)

  ;Find time range:
  midtimes = (datall.time + datall.end_time)/2.d
  if keyword_set(trange) then iKP = where(midtimes ge trange[0] and midtimes le trange[1], niKP) else begin
  ;if keyword_set(trange) then iKP = where(datall.time ge trange[0] and datall.end_time le trange[1], niKP) else begin
    niKP = n_elements(datall.time)
    iKP = lindgen(niKP)  ;use all timestamps
  endelse

  if niKP eq 0 then begin
    print, proname, ": I couldn't find any times to look at within the specified trange."
    success=0
    return
  endif

  ;Arrays to store values in:
  bkgarray = fltarr(niKP)
  cntarray = fltarr(niKP)
  flagarray = fltarr(niKP)
  timearray = dblarr(niKP)

  for tt=0, niKP-1l do begin
    ind = iKP[tt]  ;index in common block
    res3 = execute("datTMP=mvn_sta_get_"+sta_apid+"(index=ind)")
    
    ;Set all other masses to zero:
    iRM = where(datTMP.mass_arr lt massrange[0] or datTMP.mass_arr gt massrange[1], niRM)
    if niRM gt 0 then begin
      datTMP.cnts[iRM] = 0.
      datTMP.bkg[iRM] = 0.
    endif

    ;Sum over mass. Do bkg and counts
    bkg_tot = total(datTMP.bkg,/nan)
    cnts_tot = total(datTMP.cnts,/nan)

    bkgarray[tt] = bkg_tot
    cntarray[tt] = cnts_tot
    timearray[tt] = (datTMP.time + datTMP.end_time)/2.d  ;use midtime

    ;If cnts ~< bkg, flag. What is the threshold for stat significant? Poisson error?
    ;This is important for iv3, but may be removable for iv4+5****
    err = sqrt(cnts_tot)
    if (cnts_tot - bkg_tot) lt err then flagarray[tt] = 1. ;flag when difference is < sqrt(cnts) ***this could be changed
    
  endfor  ;tt
  
  ;Store results:
  tname = tplotname+'_tot_cnts'
  store_data, tname, data={x: timearray, y: cntarray}
    options, tname, ylog=1
  
  tname = tplotname+'_bkg_cnts'
  store_data, tname, data={x: timearray, y: bkgarray}
    options, tname, ylog=1
  
  tname = tplotname+'_flag_cnts'
  store_data, tname, data={x: timearray, y: flagarray}
    ylim, tname, -1, 2
  
  success=1

end

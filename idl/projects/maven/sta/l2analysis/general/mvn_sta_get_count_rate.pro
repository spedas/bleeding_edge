;+
;Get counts for a specified STATIC apid, mass and energy range, and plot in tplot.
;
;INPUTS:
;trange: double array: [a,b]: time range over which to get count rate. If not set, full time range available is used.
;sta_apid: string, eg 'c6' - STATIC apid to use. Must be set.
;mrange: float array: [a,b]: mass range in AMU. IF not set, default [0., 60.] is set (all masses).
;erange: float array: [a,b]: energy range in eV. If not set, default [0., 1E6] is set (all energies).
;species: string: 'h', 'he', 'o', 'o2', 'co2': use the default mrange values for this species. Overwrites mrange if both are set.
;tplotname: string: the name to give the created tplot variable that contains the number counts at each timestep. The default name if
;           not set is "mvn_sta_cnts_m[A,B]_e[C,D]", where A,B and C,D are the mass and energy ranges respectively.
;
;NOTES:
;Routine doesn't yet distinguish angle, but it could do...
;For apids that don't have mass resolution (eg c8), dat.nmass = 1. In these cases, the mrange and species keywords are ignored
;and all counts are returned. Energy is still filtered for.
;
;You must load STATIC data for the requested apid into common blocks using mvn_sta_l2_load, sta_apid='c6'.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_get_count_rate.pro
;-
;


pro mvn_sta_get_count_rate, trange=trange, sta_apid=sta_apid, mrange=mrange, erange=erange, species=species, success=success, $
                              tplotname=tplotname

proname = 'mvn_sta_get_count_rate'

;Checks:
if size(sta_apid, /type) ne 7 then begin
    print, proname, ": you must set sta_apid as a string, eg 'c6'."
    success=0
    return
endif

if size(species, /type) eq 7 then begin
  mranges = mvn_sta_get_mrange()

  species=strupcase(species)
  case species of
    'H' : begin
                mrange = mranges.H
                m_int=1.
          end
    'HE' : begin
                mrange = mranges.He
                m_int=2.
          end
    'O' : begin
                mrange = mranges.O
                m_int=16.
          end
    'O2' : begin
                mrange = mranges.O2
                m_int=32.
          end
    'CO2' : begin
                mrange = mranges.CO2
                m_int=44.
          end
    else : begin
              mrange=[0., 60.]
              m_int=32.
           end
  endcase
endif

if size(mrange,/type) eq 0 then mrange=[0., 60.]  ;set to default value if needed
if size(erange,/type) eq 0 then erange = [0., 1E6]

;Strings for tplotname:
mstr = '['+strtrim(string(mrange[0], format='(f12.1)'),2)+','+strtrim(string(mrange[1], format='(f12.1)'),2)+']'
estr = '['+strtrim(string(erange[0], format='(f12.1)'),2)+','+strtrim(string(erange[1], format='(f12.1)'),2)+']'

res1 = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)
res2 = execute("all_dat = all_dat_"+sta_apid)

if size(all_dat,/type) ne 8 then begin
    print, proname, ": I couldn't find any STATIC data loaded for that apid. Please load using mvn_sta_l2_load."
    success=0
    return
endif

;Get indices needed for trange requested:
if keyword_set(trange) then begin
    if size(trange,/type) ne 5 then trange2 = time_double(trange) else trange2=trange
    iKP1 = where(all_dat.time ge trange2[0] and all_dat.end_time le trange2[1], niKP1)
    if niKP1 eq 0 then begin
        print, ""
        print, proname, ": I couldn't find any data within the time range requsted."
        success=0
        return
    endif
endif else begin
    ;All availble times:
    nikP1 = n_elements(all_dat.time)
    iKP1 = findgen(niKP1)
endelse

;Arrays:
count_arr = fltarr(niKP1)
midtime = dblarr(niKP1)

;Go over each timestamp and get counts:
for tt = 0l, niKP1-1l do begin
    ind = iKP1[tt]  ;index in common block
    res = execute("dat=mvn_sta_get_"+sta_apid+"(index=ind)")
    dat2 = dat  ;copy
    
    midtime[tt] = (dat.time+dat.end_time)/2d  ;mid time
    
    ;Remove counts outside energy and mass range:
    if dat.nmass gt 1. then begin
        iRM1 = where(dat.mass_arr lt mrange[0] or dat.mass_arr gt mrange[1], niRM1)
        if niRM1 gt 0 then dat2.cnts[iRM1] = 0.  ;remove counts outside mass range
    endif
    
    if dat.nenergy gt 1 then begin
        iRM2 = where(dat.energy lt erange[0] or dat.energy gt erange[1], niRM2)
        if niRM2 gt 0 then dat2.cnts[iRM2] = 0.  ;remove counts outside energy range
    endif
    
    count_arr[tt] = total(dat2.cnts,/nan)  ;store counts

endfor  ;tt

;Store in tplot:
if not keyword_set(tplotname) then tplotname = 'mvn_sta_cnts_m'+mstr+'_e'+estr
store_data, tplotname, data={x: midtime, y: count_arr}
  options, tplotname, ylog=1
  options, tplotname, ytitle='Counts'


end



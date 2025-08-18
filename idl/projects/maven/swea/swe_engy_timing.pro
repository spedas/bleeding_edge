;+
;PROCEDURE:   swe_engy_timing
;PURPOSE:
;  Disassembles A4 packets and sorts data in time sequence.
;
;USAGE:
;  swe_engy_timing
;
;INPUTS:
;
;KEYWORDS:
;       CAL:           Use calibrated data (mvn_swe_engy).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-23 15:48:33 -0700 (Fri, 23 May 2025) $
; $LastChangedRevision: 33331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_engy_timing.pro $
;
;CREATED BY:    David L. Mitchell  06-25-13
;FILE: swe_engy_timing.pro
;-
pro swe_engy_timing, cal=cal

  @mvn_swe_com

  if keyword_set(cal) then begin
    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"No calibrated SPEC data."
      return
    endif

    nspec = n_elements(mvn_swe_engy)
    edat = reform(mvn_swe_engy.data, 64L*nspec)
    evar = reform(mvn_swe_engy.var, 64L*nspec)
    eswp = reform(mvn_swe_engy.energy, 64L*nspec)
    etime = dblarr(64L,nspec)
    units = strupcase(mvn_swe_engy[0].units_name)
    delta_t = 1.95D/2D  ; center time offset

    tvec = dindgen(448)*(1.95D/448D)
    tsam = dblarr(64)
    for j=0,63 do tsam[j] = total(tvec[(j*7+1):(j*7+6)])/6D

    for j=0L,(nspec-1L) do etime[*,j] = tsam + mvn_swe_engy[j].time

    etime = reform(etime, 64L*nspec) - delta_t
      
    store_data,'edat_svy',data={x:etime, y:edat, dy:sqrt(evar)}
    options,'edat_svy','ytitle','SWE SPEC!c' + units
    options,'edat_svy','psym',1
    ylim,'edat_svy',0,0,1

    store_data,'eswp_svy',data={x:etime, y:eswp}
    options,'eswp_svy','ytitle','SWE SPEC!cEnergy (eV)'
    options,'eswp_svy','psym',10
    ylim,'eswp_svy',0,0,1

    return
  endif

  if (size(a4,/type) eq 8) then begin

    nspec = 16L*n_elements(a4)
    edat = reform(a4.data,64L*nspec)
    evar = reform(a4.var,64L*nspec)
    eswp = reform(swe_swp[*,0] # replicate(1.,nspec), 64L*nspec)
    etime = dblarr(64L,nspec)

    tvec = dindgen(448)*(1.95D/448D)
    tsam = dblarr(64)
    for j=0,63 do tsam[j] = total(tvec[(j*7+1):(j*7+6)])/6D

    period = 2D^a4.period
    toff = 2D*dindgen(16)

    for j=0L,(nspec-1L) do begin
      etime[*,j] = tsam + a4[j/16L].time + period[j/16L]*toff[j mod 16L]
;      if (a4[j/16L].smode) then etime[*,j] = etime[*,j] + (period[j/16L] - 1D)
    endfor

    etime = reform(etime,64L*nspec)
      
    store_data,'edat_svy',data={x:etime, y:edat, dy:sqrt(evar)}
    options,'edat_svy','ytitle','Engy Svy Timing'
    options,'edat_svy','psym',1
    ylim,'edat_svy',-10,300,0
    
    store_data,'eswp_svy',data={x:etime, y:eswp}
    options,'eswp_svy','ytitle','Sweep Svy Timing'
    options,'eswp_svy','psym',10
    ylim,'eswp_svy',0,0,1

  endif else print,"No A4 data to process."

  if (size(a5,/type) eq 8) then begin

    nspec = 16L*n_elements(a5)
    edat = reform(a5.data,64L*nspec)
    evar = reform(a5.var,64L*nspec)
    eswp = reform(swe_swp[*,0] # replicate(1.,nspec), 64L*nspec)
    etime = dblarr(64L,nspec)

    tvec = dindgen(448)*(1.95D/448D)
    tsam = dblarr(64)
    for j=0,63 do tsam[j] = total(tvec[(j*7+1):(j*7+6)])/6D

    period = 2D^a5.period
    toff = 2D*dindgen(16)

    for j=0L,(nspec-1L) do begin
      etime[*,j] = tsam + a5[j/16L].time + period[j/16L]*toff[j mod 16L]
;      if (a5[j/16L].smode) then etime[*,j] = etime[*,j] + (period[j/16L] - 1D)
    endfor

    etime = reform(etime,64L*nspec)
      
    store_data,'edat_arc',data={x:etime, y:edat, dy:sqrt(evar)}
    options,'edat_arc','ytitle','Engy Arc Timing'
    options,'edat_arc','psym',1
    ylim,'edat_arc',-10,300,0
    
    store_data,'eswp_arc',data={x:etime, y:eswp}
    options,'eswp_arc','ytitle','Sweep Arc Timing'
    options,'eswp_arc','psym',10
    ylim,'eswp_arc',0,0,1

  endif else print,"No A5 data to process."
 
  return

end

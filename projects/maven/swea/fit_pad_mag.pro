;+
;PROCEDURE:   fit_pad_mag
;PURPOSE:
;  Determines the time offset between MAG1 data and SWEA MAG angles.  For SWEA pitch
;  angle sorting, the magnetic field is averaged over the second half of the 2-sec
;  measurement cycle.  However, there can be apparent differences between the MAG and
;  SWEA timing if one of the decommutators has an error.  Here, I assume that the SWEA
;  timing is correct (naturally) and fit for a constant MAG time offset.
;
;USAGE:
;  fit_pad_mag
;
;INPUTS:
;
;KEYWORDS:
;       RESULT:       Timing and angular offsets.  The timing offset is robust.
;                     Angular offsets are for reference only.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-02-04 13:44:34 -0800 (Wed, 04 Feb 2015) $
; $LastChangedRevision: 16867 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/fit_pad_mag.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro fit_pad_mag, trange=trange, result=result

  @mvn_swe_com
  
  if (size(a2,/type) ne 8) then begin
    print,"No PAD data."
    return
  endif
  
  if (size(swe_mag1,/type) ne 8) then begin
    print,"No MAG1 data."
    return
  endif
  
  if (size(swe_mag2,/type) eq 8) then domag2 = 1 else domag2 = 0

  if not keyword_set(trange) then tmin = min(swe_mag1.time, max=tmax) $
                             else tmin = min(trange, max=tmax)

; Get SWEA PAD MAG angles and MAG1 data

  Sx = a2.time + 1.5D                   ; center time of SWEA MAG sample
  Sy = (a2.Baz + 0.5)*(360./256.)       ; azimuth (deg)
  Sz = (a2.Bel + 0.5)*(180./40.) - 90.  ; elevation (deg)

  Bx = swe_mag1.time
  By = swe_mag1.Bphi*!radeg
  Bz = swe_mag1.Bthe*!radeg
  indx = sort(Bx)                       ; MAG times sometimes not monotonic
  Bx = temporary(Bx[indx])
  By = temporary(By[indx])
  Bz = temporary(Bz[indx])

; Trim the data to trange

  indx = where((Bx ge tmin) and (Bx le tmax), count)
  if (count gt 0L) then begin
    Bx = temporary(Bx[indx])
    By = temporary(By[indx])
    Bz = temporary(Bz[indx])
  endif else begin
    print,"No MAG data within trange."
    return
  endelse

  indx = where((Sx ge tmin) and (Sx le tmax), count)
  if (count gt 0L) then begin
    Sx = temporary(Sx[indx])
    Sy = temporary(Sy[indx])
    Sz = temporary(Sz[indx])
  endif else begin
    print,"No SWEA data within trange."
    return
  endelse

; Differentiate to ignore constant angle offsets

  dSy = Sy - shift(Sy,1)
  dSy = dSy[1L:*]

; Calculate correlation function

  dt_min = -10D
  dt_max = 10D
  dt_step = 0.125D
  npts = round((dt_max - dt_min)/dt_step) + 1L
  dt = dt_min + dt_step*dindgen(npts)

  Bc = fltarr(npts)
  for i=0,(npts-1L) do begin
    BSy = interpol(By, (Bx-dt[i]), Sx)  ; sample at PAD times
    dBSy = BSy - shift(BSy,1)           ; differentiate to ignore offsets
    dBSy = dBSy[1L:*]
    chi2 = (dSy - dBSy)^2.
    indx = where(chi2 lt (1.e3*median(chi2)))  ; filter spikes
    Bc[i] = total(chi2[indx])           ; chi2 at dt[i]
  endfor
  Bc = Bc/mean(Bc)                      ; normalize
  Bc_min = min(Bc,i)                    ; minimum chi2
  toff = dt[i]                          ; timing difference (PAD - MAG)

; Plot the result

  Twin = !d.window
  window,/free
  
  tmin = min(swe_mag1.time, max=tmax)
  tmsg = time_string(tmin) + " to " + time_string(tmax)

  plot,dt,Bc,/ynozero, thick=2, xrange=[min(dt),max(dt)],/xsty, title=tmsg, $
       xtitle='Time Offset (sec)',ytitle='Bphi Chi2 Amplitude (MAG - PAD)',charsize=1.4
  oplot,[toff,toff],[0,2D*max(Bc)],line=2
  xnorm = 1.05*(toff - dt[0])/(max(dt) - dt[0])
  xyouts,xnorm,0.85,string(toff,format='("Offset: ",f6.3)'),/norm,charsize=1.4

; Gain and offset "corrections" - these are for reference only and should not be
; used to correct MAG data.  They are way too simplistic.

  BSy = interpol(By, (Bx-toff), Sx)
  gphi = median(Sy/BSy)
  dphi = median(Sy - BSy)
  
  BSz = interpol(Bz, (Bx-toff), Sx)
  gthe = median(Sz/BSz)
  dthe = median(Sz - BSz)

  result = {toff:toff, gphi:gphi, gthe:gthe, dphi:dphi, dthe:dthe}

; Apply the time offset

  yn = 'N'
  print,toff,format='("Time offset: ",f7.3," sec")'
  read, yn, prompt='Apply time offset (y|n) ? '

  if (strupcase(yn) eq 'Y') then begin
    swe_mag1.time = swe_mag1.time - toff
    if (domag2) then swe_mag2.time = swe_mag2.time - toff
    
    get_data,'Bphi1',data=Bphi1,index=k
    if (k gt 0) then begin
      Bphi1.x = Bphi1.x - toff
      store_data,'Bphi1',data=Bphi1
    endif
    
    get_data,'Bthe1',data=Bthe1,index=k
    if (k gt 0) then begin
      Bthe1.x = Bthe1.x - toff
      store_data,'Bthe1',data=Bthe1
    endif
    
    get_data,'Bphi2',data=Bphi2,index=k
    if (k gt 0) then begin
      Bphi2.x = Bphi2.x - toff
      store_data,'Bphi2',data=Bphi2
    endif
    
    get_data,'Bthe2',data=Bthe2,index=k
    if (k gt 0) then begin
      Bthe2.x = Bthe2.x - toff
      store_data,'Bthe2',data=Bthe2
    endif
    
    get_data,'mvn_B_1sec',data=mag,index=k
    if (k gt 0) then begin
      mag.x = mag.x - toff
      store_data,'mvn_B_1sec',data=mag
    endif
    
    get_data,'mvn_B_full',data=mag,index=k
    if (k gt 0) then begin
      mag.x = mag.x - toff
      store_data,'mvn_B_full',data=mag
    endif
    
    get_data,'mvn_B_full_amp',data=mag,index=k
    if (k gt 0) then begin
      mag.x = mag.x - toff
      store_data,'mvn_B_full_amp',data=mag
    endif
  endif

  wset, Twin

  return

end

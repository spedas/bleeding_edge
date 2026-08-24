;+
;Determine whether STATICs field of view (FOV) is pointing nadir (towards Mars) or not. Produce a flag when the FOV is greater than
;45 degrees from the nadir direction. This is important for determining if STATIC is orientated to observe pick up ions from Mars (note:
;the motional electric field must also be pointing into STATICs FOV (not calculated here), but STATIC must be pointing toward Mars in order to see pick up ions
;from there).
;
;
;Note, this routine will call upon mvn_sta_anc_ephemeris to generate the MAVEN sc position. It will thus overwrite the tplot variable
;mvn_sta_anc_mvn_pos_mso (if already present) for data at times "timein". The user should ensure this will not be a problem.
;
;
;INPUTS:
;timein: UNIX double precision timestamps. Pointing flag is generated at each of these timesteps using SPICE. If you have an array of string 
;        UTC times (eg '2015-01-01/00:00:00'), first convert these to double precision UNIX times using time_double().
;
;
;KEYWORDS:
;spicekernels: if you have already loaded SPICE, set this keyword to the kernels loaded. These kernels will be checked to ensure that there is
;              coverage for the times requested. If you have not already loaded SPICE, do not set this keyword. SPICE will then be initiated
;              based on the timespan set (the user must ensure that timespan spans the date range of timein; for timein points outside of 
;              the set timespan, SPICE coverage will not be available). See examples below for how to set this keyword.
;
;spicevar: string: if you have already run SPICE and have the MAVEN sc position in MSO coordinates at times "timein", set this keyword
;                  to that variable. The routine will grab this tplot variable, rather than running SPICE to calculate it. If this keyword 
;                  is not set, SPICE will be run.
;
;success: if set, returns:
;                 0 : return could not generate nadir flags.
;                 1 : return successfully generated nadir flags.
;
;
;HISTORY:
;Original version written by CM Fowler (cmfowler@berkeley.edu), 2019-12-04.
;
;.r /Users/cmfowler/IDL/STATIC_routines/mvn_sta_mom/mvn_sta_mom_nadirpoint.pro   ;for testing, ignore.
;-
;


pro mvn_sta_mom_nadirpoint, timein, spicekernels=spicekernels, success=success, spicevar=spicevar

proname = 'mvn_sta_mom_nadirpoint'

;CHECKS:
if size(timein, /type) ne 5 then begin
  print, proname, ": timein must be a double precision array of UNIX times."
  success=0
  return
endif

if not keyword_set(spicekernels) then begin
  get_timespan, trange
  
  if size(trange,/type) eq 0. then begin
    print, proname, ": you must set timespan first."
    success=0
    return
  endif
  
  spicekernels = mvn_spice_kernels(/load)  ;load SPICE
  
endif

;ADDITIONAL INFO:
if keyword_set(spicevar) then begin
  ;Check to see if the user set variable exists:
  if total(strmatch(tnames(), spicevar)) eq 1 then posvar = spicevar else begin
       mvn_sta_anc_ephemeris, timein, /mvn_pos, spicekernels=spicekernels  ;input spice kernels here to this routine doesn't call SPICE also
       posvar = 'mvn_sta_anc_mvn_pos_mso'  
  endelse
endif else begin
  mvn_sta_anc_ephemeris, timein, /mvn_pos, spicekernels=spicekernels  ;input spice kernels here to this routine doesn't call SPICE also
  posvar = 'mvn_sta_anc_mvn_pos_mso' 
endelse

get_data, posvar, data=ddPOS

if size(ddPOS, /type) ne 8 then begin
  print, proname, ": I couldn't generate MAVEN position. "
  success=0
  return
endif


;ROTATE STATIC k VECTOR TO MSO SYSTEM:
neleT = n_elements(timein)  ;number of time steps

vect = fltarr(3,neleT)  ;arrays must be 3xN for rotation. 
vect[2,*] = 1.  ;This is the MAVEN STATIC k vector array

;Check when we have SPICE coverage for STATIC rotations:
mvn_sta_ck_check, timein, success=sc  

get_data, 'mvn_sta_ck_check', data=dd_ck_check  ;dd_ck_check.y is an array the same length as timein: 0 means data point is covered by SPICE,
                                                ;1 means flag - data point is not covered by SPICE (for pointing (ck) information).

if sc eq 1 and size(dd_ck_check, /type) eq 8 then begin
 
  rotateARR_full = fltarr(neleT,3)+!values.f_nan  ;store the STATIC k vector in MSO frame here (note, Nx3 size for tplot)

  for rr = 0l, neleT-1l do begin
    if dd_ck_check.y[rr] eq 0 then begin  ;if ck coverage present, do rotation. If not, values left as NaNs.
      rotateTMP = spice_vector_rotate(vect[*,rr],timein[rr],'MAVEN_STATIC','MAVEN_MSO')
      rotateARR_full[rr,*] = transpose(rotateTMP)
    endif
  endfor
  
  ;Calculate angle between STATIC k and nadir vector. Nadir vector is just MAVEN position in MSO frame.
  ;Use cos(theta) = adotb/(|A||B|)
  Amag = sqrt(ddPOS.y[*,0]^2 + ddPOS.y[*,1]^2 + ddPOS.y[*,2]^2)
  Bmag = sqrt(rotateARR_full[*,0]^2 + rotateARR_full[*,1]^2 + rotateARR_full[*,2]^2)  ;this should be 1 as it's defined earlier
  adotb = (ddPOS.y[*,0]*rotateARR_full[*,0]) + (ddPOS.y[*,1]*rotateARR_full[*,1]) + (ddPOS.y[*,2]*rotateARR_full[*,2])
  
  theta = acos(adotb/(Amag*Bmag)) * 180./!pi  ;convert radians to degrees.
  
  ;Wrap angles 90-180 to 0-90:
  theta2=theta
  iCH = where(theta gt 90., niCH)
  if niCH gt 0 then theta2[iCH] = 180. - theta[iCH]
  
  ;YES/NO flag: yes when theta>45 degrees (k vector perp to plane of STATIC FOV):
  nadirflag = theta2 gt 45.
  
  ;Get the nadirangle rate of change, to find times when APP or SC changes orientation quickly. This can cause "blips" in STATIC data that
  ;appear interesting but are probably just FOV changes:
  ;Because this routine can be used with all STATIC data products, I specifically calculate dt here, rather than assuming it.
  dt = timein[1:*]-timein[0:*]
  dt = [dt, dt[neleT-2l]]  ;copy the last value of dt, assuming it's the same as the previous, so that dt is the same length as timein.
  
  da = theta2[1:*]-theta2[0:*]
  da = [da, da[neleT-2l]]  ;copy last value as above
  
  dadt = abs(da/dt)  ;change in nadirangle in degrees per sec
  
  ;Generate flag when change in nadir angle is large:
  dA_flag = dadt gt 0.5  ;1: flag as large, quick change in angle, use with caution; 0: should be no problems. 0.5 is determined by-eye. I checked c6 and d0 
                         ;d0 data and the two products agree. d0 data have lower time cadence, so sometimes miss "quick" rotations that
                         ;are captured by c6. Errors from this should be negligible though.
                         
  ;STORE OUTPUTS IN TPLOT:
  fname = 'mvn_sta_mom_nadirangle'
  store_data, fname, data={x: timein, y: theta2}  
      ylim, fname, 0, 90
      options, fname, ytitle='STA nadir angle'
      options, fname, ysubtitle='[degrees]'
  
  fname = 'mvn_sta_mom_nadirangle_flag'
  store_data, fname, data={x: timein, y: nadirflag}
    ylim, fname, -1, 2
    options, fname, ytitle='STA nadir!Cflag'
    
  fname = 'mvn_sta_mom_del_nadirangle'
  store_data, fname, data={x: timein, y: dadt}
    options, fname, ytitle='STA dNadir/dT'
  
  fname = 'mvn_sta_mom_del_nadirangle_flag'
  store_data, fname, data={x: timein, y: dA_flag}
    ylim, fname, -1, 2
    options, fname, ytitle='STA dNadir flag'
   
  success=1
endif else begin
  print, proname, ": I couldn't check SPICE ck kernel coverage. Is timein a double precision array?"
  success=0 
  return
endelse

end




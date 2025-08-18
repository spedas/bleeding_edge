;+
;PROCEDURE: 
;	mvn_scpot
;
;PURPOSE:
;	Merges five separate methods for estimating the spacecraft potential.
;   In cases where more than one method yields a potential, this routine
;   sets a hierarchy for which method takes precedence.  The hierarchy
;   depends on location (altitude, shadow).  The five methods are:
;
;       SWE+    : Estimate positive potentials by looking for a sharp
;                 break in the electron energy spectrum.  Mainly for
;                 the solar wind and sheath.
;                 (Author: D. Mitchell)
;
;       SWE-    : Estimate negative potentials by measuring shifts in
;                 position of the He-II photoelectron peak.  Mainly
;                 for the ionosphere.*
;                 (Author: S. Xu)
;
;       SWE/LPW : Use LPW I-V curves, empirically calibrated by the
;                 SWE+ and SWE- methods.  Works almost everywhere, 
;                 except in the EUV shadow or when the spacecraft 
;                 charges to large negative potentials.
;                 (Author: Y. Harada)
;
;       STA-    : Estimate negative potentials by the low energy 
;                 cutoff of the H+ distribution (away from periapsis),
;                 or energy shifts, relative to the ram energy, of O+
;                 and O2+ (near periapsis).**
;                 (Author: J. McFadden)
;
;       SWEPAD  : Use pitch angle resolved photoelectron spectra to 
;                 estimate negative potentials in the wake.  Combined
;                 with the STA- method, may be used to distinguish 
;                 spacecraft and Mars potentials.  Only works with
;                 burst data.*
;                 (Author: S. Xu)
;
;  * Warning: The SWE- and SWEPAD methods provide the sum of the spacecraft
;             and Mars potentials.  Ionospheric photoelectrons are always subject
;             to the ambipolar potential (~1 V) that forms at the electron exobase 
;             to maintain charge neutrality with the gravitationally bound ions.  
;             There are other Mars potentials that can sometimes play a role.  
;             Comparison with the STA method is necessary to separate the spacecraft
;             and Mars potentials.  Thus, the LPW, SWE+, and STA methods must take
;             precedence.
;
; ** Warning: O2+ dominates at periapsis.  Using shifts in the O2+ energy alone
;             assumes that thermospheric winds are negligible.
;
;   The general order of precedence is: SWE/LPW, SWE+, STA-, SWE-, and
;   SWEPAD (when activated by keyword).
;
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_scpot
;
;INPUTS: 
;   none - energy spectra are obtained from SWEA common block.
;
;KEYWORDS:
;	POTENTIAL: Returns a time-ordered array of structures:
;
;                {time            : 0D       , $
;                 potential       : 0.       , $
;                 method          : -1          }
;
;              The methods are: -1 (invalid), 0 (manually set), 
;              1 (SWE/LPW), 2 (SWE+), 3 (SWE-), 4 (STA-), 5 (SWEPAD),
;              6 (interpolated).
;
;              The optimal value depends on the plasma environment.
;
;   SETVAL:    Make no attempt to estimate the potential, just set it to
;              this value.  Units = volts.  No default.
;
;   COMPOSITE: The composite potential (SWE/LPW, SWE+, SWE-, STA-) has  
;              been pre-calculated with this routine and stored in save 
;              files.  Set this keyword to simply restore this file and
;              save lots of time.  (Works for multiple days and can span
;              UT day boundaries.)  This is the default.  Set this keyword
;              to zero to force a recalculation.
;
;   NOCALC:    Do not perform a recalculation.  Use the composite potential
;              or nothing.
;
;   LPWPOT:    Use pre-calculated LPW/SWE derived potentials.  There is
;              a ~2-week delay in the production of this dataset.  You can
;              set this keyword to the full path and filename of a tplot 
;              save/restore file, if one exists.  Otherwise, this routine 
;              will determine the potential from SWEA and STATIC.
;              Default = 1 (yes).
;
;   POSPOT:    Calculate positive potentials with mvn_swe_sc_pot (SWE+).
;              Default = 1 (yes).
;
;   NEGPOT:    Calculate negative potentials with mvn_swe_sc_negpot.
;              Default = 1 (yes).
;
;   STAPOT:    Use STATIC-derived potentials to fill in gaps.  This is 
;              especially useful in the high-altitude shadow region.
;              Assumes that you have calculated STATIC potentials.
;              (See mvn_sta_scpot_load.pro)
;              Default = 1 (yes).
;              
;   SHAPOT:    Calculate negative potentials with 'mvn_swe_sc_negpot_
;              twodir_burst'.  Two estimates are obtained, one each for
;              the parallel and anti-parallel electron populations.  If
;              both directions yield a potential, then the one closer to 
;              zero is chosen for merging with other methods.
;              Requires keyword NEGPOT to be set.
;              Default = 1 (yes).
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   LOADONLY:  Load the potential but do not refresh the tplot window.
;
;   QLEVEL:    Minimum quality level for SWEA data.  Filters out the vast
;              majority of spectra affected by the sporadic low energy
;              anomaly below 28 eV.  The validity levels are:
;
;                0B = Data are affected by the low-energy anomaly.  There
;                     are significant systematic errors below 28 eV.
;                1B = Unknown because: (1) the variability is too large to 
;                     confidently identify anomalous spectra, as in the 
;                     sheath, or (2) secondary electrons mask the anomaly,
;                     as in the sheath just downstream of the bow shock.
;                2B = Data are not affected by the low-energy anomaly.
;                     Caveat: There is increased noise around 23 eV, even 
;                     for "good" spectra.
;
;                Default = 1.
;
;   QINTERP:   Interpolate the potential for small gaps caused by the 
;              sporadic low-energy anomaly.  Set this keyword to the largest
;              gap (in seconds) to interpolate across.
;
;   SUCCESS:   Returns exit status.
;
;OUTPUTS:
;   None - Result is stored in common blocks, returned via the POTENTIAL
;          keyword, and stored as TPLOT variables.  Two TPLOT variables
;          are created: one with a single merged potential and one showing
;          the five unmerged methods in one panel.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 10:37:26 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33410 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot.pro $
;
;-

pro mvn_scpot, potential=pot, setval=setval, pospot=pospot, negpot=negpot, $
               stapot=stapot, lpwpot=lpwpot, shapot=shapot, composite=composite, $
               pans=pans, nocalc=nocalc, qlevel=qlevel, qinterp=qinterp, $
               success=success, loadonly=loadonly, no_server=no_server

  compile_opt idl2

  @mvn_swe_com
  @mvn_scpot_com

  pot = 0
  success = 0
  NaN = !values.f_nan
  qlevel = (n_elements(qlevel) gt 0) ? byte(qlevel[0]) : 1B
  loadonly = keyword_set(loadonly)

; Parameters for each of the potential estimation methods are managed by
; mvn_scpot_defaults.pro.  See that procedure for parameter definitions.

  if (size(Espan,/type) eq 0) then mvn_scpot_defaults

  tmin = min(timerange(), max=tmax)

; Set processing flags

  if (size(composite,/type) eq 0) then composite = 1 else composite = keyword_set(composite)
  if (size(lpwpot,/type) eq 0) then lpwpot = 1 else lpwpot = keyword_set(lpwpot)
  if (size(pospot,/type) eq 0) then pospot = 1 else pospot = keyword_set(pospot)
  if (size(negpot,/type) eq 0) then negpot = 1 else negpot = keyword_set(negpot)
  if (size(stapot,/type) eq 0) then stapot = 1 else stapot = keyword_set(stapot)
  if (size(shapot,/type) eq 0) then shapot = 1 else shapot = keyword_set(shapot)
  if (shapot) then negpot = 1  ; required for pot_in_shadow to work

; Set the potential manually

  if (size(setval,/type) ne 0) then begin
    if (size(mvn_sc_pot,/type) ne 8) then begin
        mvn_scpot_restore, result=comp, success=ok, no_server=no_server
      if (ok) then begin
        mvn_sc_pot = replicate(mvn_pot_struct, n_elements(comp.time))
        mvn_sc_pot.time = comp.time
      endif else begin
        dt = 2D
        npts = floor((tmax - tmin)/dt) + 1L
        mvn_sc_pot = replicate(mvn_pot_struct, npts)
        mvn_sc_pot.time = tmin + dt*dindgen(npts)
      endelse
    endif
    print,"Setting the s/c potential to: ",setval
    mvn_sc_pot.potential = setval
    mvn_sc_pot.method = 0  ; potential set manually

    phi = {x:mvn_sc_pot.time, y:mvn_sc_pot.potential}
    store_data,'mvn_sc_pot',data=phi

    mvn_swe_addpot, loadonly=loadonly
    mvn_sta_scpot_update

    pot = mvn_sc_pot
    success = 1
    return
  endif

; Get pre-calculated composite potentials (this is the default)

  if (composite) then begin
    mvn_scpot_restore, result=comp, /tplot, success=ok, no_server=no_server
    if (ok) then begin
      print,"Using SWE/LPW/STA composite potential."
      indx = where(comp.method eq -1, count)
      if (count gt 0L) then comp[indx].potential = NaN

      mvn_sc_pot = replicate(mvn_pot_struct, n_elements(comp.time))
      mvn_sc_pot.time = comp.time
      mvn_sc_pot.potential = comp.potential
      mvn_sc_pot.method = comp.method

      mvn_swe_addpot
      mvn_sta_scpot_update

      pot = mvn_sc_pot
      success = 1
      return
    endif else print,"SWE/LPW/STA composite potential not available."
  endif

  if keyword_set(nocalc) then return

; If the routine has not returned by this point, then it has to calculate the
; potential from the original data sources (SWEA, STATIC, LPW).  Thus, we need
; to check that the necessary data have been loaded.

; Make sure SWEA SPEC data are available

  if (size(mvn_swe_engy,/type) ne 8) then begin
    mvn_swe_load_l2, /spec
    if (size(mvn_swe_engy,/type) ne 8) then begin
      print,"Cannot find SWEA data."
      pot = 0
      success = 0
      return
    endif
  endif

; Initialize the potential structure

  time = mvn_swe_engy.time
  npts = n_elements(time)
  mvn_sc_pot = replicate(mvn_pot_struct, npts)
  mvn_sc_pot.time = mvn_swe_engy.time
  mvn_sc_pot.potential = NaN
  mvn_sc_pot.method = -1

; Get the EUV shadow location

  get_data, 'wake', data=wake, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /load, /shadow
    get_data, 'wake', data=wake, index=i
  endif
  if (i eq 0) then begin
    print,"Cannot get orbit information!  Problem with maven_orbit_tplot."
    pot = 0
    success = 0
    return
  endif
  str_element, wake, 'shadow', value=shadow, success=ok
  if (ok) then shadow = shadow[0] else shadow = ''
  if (strupcase(shadow) ne 'EUV') then begin
    maven_orbit_tplot, /load, /shadow
    get_data, 'wake', data=wake, index=i
  endif
  if (i eq 0) then begin
    print,"Cannot get orbit information!  Problem with maven_orbit_tplot."
    pot = 0
    success = 0
    return
  endif
  wake = interp(wake.y, wake.x, time, /no_extrap)
  indx = where(finite(wake), count)
  wake = replicate(0B, npts)
  if (count gt 0L) then wake[indx] = 1B

; Get the altitude

  get_data, 'alt', data=alt
  alt = spline(alt.x, alt.y, time)

; Step 1: Get pre-calculated potentials from SWEA-LPW analysis.

  if (lpwpot) then begin
     get_data, 'mvn_swe_lpw_scpot_pol', index=i
     if (i gt 0) then store_data, 'mvn_swe_lpw_scpot_pol', /delete
     mvn_swe_lpw_scpot_restore  ; ,suffix='_v01_r10' ; for testing

     get_data, 'mvn_swe_lpw_scpot_pol', data=lpwphi, index=i
     if (i gt 0) then begin
        print,"Using SWE/LPW potential."
        options,'mvn_swe_lpw_scpot_pol','psym',3
        options,'mvn_swe_lpw_scpot_pol','color',!p.color

;       Don't use potentials more negative than min_lpw_pot

        igud = where(lpwphi.y gt min_lpw_pot, ngud, complement=ibad, ncomplement=nbad)
        if (nbad gt 0L) then lpwphi.y[ibad] = NaN

        if (ngud gt 0L) then begin
          phi = interp(lpwphi.y, lpwphi.x, time, interp_thresh=maxdt, /no_extrap)

          indx = where(finite(phi) and (mvn_sc_pot.method lt 1), count)
          if (count gt 0L) then begin
            mvn_sc_pot[indx].potential = phi[indx]
            mvn_sc_pot[indx].method = 1  ; swe/lpw method
          endif

        endif else print, "No valid SWE/LPW potentials."

     endif else print, "SWE/LPW potential not available."
  endif

; Step 2: Estimate positive potential from SWEA alone
  
  if (pospot) then begin
    mvn_swe_sc_pot, potential=phi, qlevel=qlevel, diag=diag

;   Don't trust SWE+ potentials in the EUV shadow

    indx = where(wake, count)
    if (count gt 0L) then begin
      phi[indx].potential = NaN
      phi[indx].method = -1
    endif

;   Don't trust SWE+ potentials below min_swe_alt (default = 400 km)

    indx = where(alt lt min_swe_alt, count)
    if (count gt 0L) then begin
      phi[indx].potential = NaN
      phi[indx].method = -1
    endif

;   Insert valid SWE+ potentials into potential structure

    indx = where((mvn_sc_pot.method lt 1) and (phi.method eq 2), count)
    if (count gt 0) then mvn_sc_pot[indx] = phi[indx]
  endif

; Step 3: Estimate negative potentials from SWEA (He-II feature)
;   This fills in missing negative LPW-derived potentials.

  if (negpot) then begin    
    mvn_swe_sc_negpot, potential=phi, qlevel=qlevel
    indx = where((mvn_sc_pot.method lt 1) and (phi.method eq 3), count)
    if (count gt 0) then mvn_sc_pot[indx] = phi[indx]

    options,'neg_pot','color',6
  endif        

; Step 4: Use STATIC-derived negative potentials.

  if (stapot) then begin
    print,"Getting negative potentials from STATIC."

    get_data,'mvn_sta_c6_scpot',data=stapot,index=i

    if (i gt 0) then begin
      indx = where((stapot.x ge tmin) and (stapot.x le tmax), count)  ; reload STATIC data?
      if (count lt 20L) then i = 0
    endif

    if (i eq 0) then begin
      mvn_sta_l2_load, sta_apid=['c6']
      mvn_sta_l2_tplot, /replace
      get_data,'mvn_sta_c6_scpot',data=stapot,index=i
    endif

    if (i gt 0) then begin
      options,'mvn_sta_c6_scpot','color',4

;     Get all "good" potential estimates.  Replace values >= 0 with NaNs.

      igud = where(stapot.y lt 0., ngud, comp=ibad, ncomp=nbad)
      if (nbad gt 0L) then stapot.y[ibad] = NaN
      msg = string("STA- : ",ngud," valid potentials from ",ngud+nbad," spectra",format='(a,i8,a,i8,a)')
      print, strcompress(strtrim(msg,2))

      if (ngud gt 0L) then begin

        phi = interp(stapot.y, stapot.x, time, interp_thresh=maxdt, /no_extrap)

;       Trust all values within the EUV shadow and above max_sta_alt

        indx = where(finite(phi) and wake and (alt gt max_sta_alt), count)
        if (count gt 0L) then begin
          mvn_sc_pot[indx].potential = phi[indx]
          mvn_sc_pot[indx].method = 4
        endif

;       Trust all values between 200 and 300 km ; hmm need something better
;
;        indx = where(finite(phi) and (alt gt max_sta_alt) and (alt lt 300.), count)
;        if (count gt 0L) then begin
;          mvn_sc_pot[indx].potential = phi[indx]
;          mvn_sc_pot[indx].method = 4
;        endif

;       Fill in missing values.  If more than one of LPW, SWE and STA provide values,
;       choose one that is greater (less negative or more positive).

        indx = where((phi gt min_sta_pot) and $ ; (mvn_sc_pot.method ne 1) and $
                     ((phi gt mvn_sc_pot.potential) or (mvn_sc_pot.method lt 1)), count)
        if (count gt 0L) then begin
          mvn_sc_pot[indx].potential = phi[indx]
          mvn_sc_pot[indx].method = 4
        endif

      endif else print, "No valid STATIC potentials."
    endif else print, "STATIC potential not available."
  endif

; Step 5: Estimate negative potential from SWEA PAD data

  if (shapot) then begin
    print,"Estimating negative potentials from SWEA PAD data."

    mvn_swe_sc_negpot_twodir_burst, potential=phi, /shadow

    if (size(phi,/type) eq 8) then begin
       indx = where((phi.method eq 5) and (mvn_sc_pot.method lt 1), count)
       if (count gt 0L) then begin
          mvn_sc_pot[indx] = phi[indx]
          mvn_swe_engy[indx].sc_pot = phi[indx].potential
       endif             
    endif

    options,'pot_inshdw','constant',!values.f_nan
    options,'pot_inshdw','color',1
  endif

; Mask missing data

  if (finite(badval)) then begin
    indx = where(mvn_sc_pot.method lt 1, count)
    if (count gt 0L) then begin
      mvn_sc_pot[indx].potential = badval
      mvn_sc_pot[indx].method = 0
    endif
  endif

; Interpolate potential for anomalous spectra

  if keyword_set(qinterp) then begin
    bndx = where(mvn_swe_engy.quality eq 0, nbad)
    pndx = where(mvn_sc_pot.method ge 1, npot)
    if ((nbad gt 0L) and (npot gt 0L)) then begin
      i = nn2(mvn_sc_pot[pndx].time, mvn_swe_engy[bndx].time, maxdt=qinterp, /valid, vindex=vndx)
      qpot = interpol(mvn_sc_pot[pndx].potential, mvn_sc_pot[pndx].time, mvn_swe_engy[bndx[vndx]].time)
      mvn_sc_pot[bndx[vndx]].potential = qpot
      mvn_sc_pot[bndx[vndx]].method = 6
    endif
  endif

; Finish

  pot = mvn_sc_pot
  success = 1

; Update the SWEA and STATIC potentials.

  mvn_swe_addpot
  mvn_sta_scpot_update

; Create a tplot variable for all potential methods (with overlap)

  potpans = ['mvn_swe_lpw_scpot_pol','swe_pos','neg_pot','mvn_sta_c6_scpot','pot_inshdw']
  potlabs = ['lpw', 'swe+', 'swe-', 'sta', 'swe-(sh)']
  potcols = [!p.color, 2, 6, 4, 1]

  store_data,'swe_pot_lab',data={x:minmax(mvn_sc_pot.time), y:replicate(!values.f_nan,2,5)}
  options,'swe_pot_lab','labels',reverse(potlabs)
  options,'swe_pot_lab','colors',reverse(potcols)
  options,'swe_pot_lab','labflag',1

  potall = 'scpot_all'
  potpans = ['swe_pot_lab',potpans]

  store_data,potall,data=potpans
  options,potall,'ytitle','S/C Potential!cVolts'
  options,potpans,'constant',!values.f_nan
  options,potall,'constant',[0]

; Create a tplot variable for the composite potential (no overlap)

  vname = ['pot_swelpw','pot_swepos','pot_sweneg','pot_staneg','pot_sweshdw']

  nv = n_elements(vname)

  for i=0,nv-1 do begin
     x=mvn_sc_pot.time
     y=replicate(!values.f_nan,n_elements(x))
     inx=where(mvn_sc_pot.method eq i+1,cts)
     if cts gt 0L then begin
        y[inx]=mvn_sc_pot[inx].potential
        store_data,vname[i],data={x:x,y:y}
     endif else begin
        store_data,vname[i],data={x:minmax(mvn_sc_pot.time), y:replicate(!values.f_nan,2)}
     endelse
     options,vname[i],'color',potcols[i]
  endfor

  potall = 'scpot_comp'
  store_data,potall,data=['swe_pot_lab',vname]
  options, vname, 'constant', !values.f_nan
  options, potall, 'constant', [0]
  options, potall, 'ytitle', 'S/C Potential!cVolts'

  return

end

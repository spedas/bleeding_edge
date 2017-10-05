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
;                 for the ionosphere.
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
;                 and O2+ (near periapsis).
;                 (Author: J. McFadden)
;
;       SWEPAD  : Use pitch angle resolved photoelectron spectra to 
;                 estimate negative potentials in the wake.  Combined
;                 with the STA- method, may be used to distinguish 
;                 spacecraft and Mars potentials.  Only works with
;                 burst data.
;                 (Author: S. Xu)
;
;   The general order of precedence is: SWE/LPW, SWE+, SWE-, STA-, and
;   SWEPAD (when activated by keyword).
;
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_scpot, potential=dat
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
;              1 (SWE/LPW), 2 (SWE+), 3 (SWE-), 4 (STA-), 5 (SWEPAD).
;
;   ERANGE:    Energy range over which to search for the potential
;              with the SWE+ method.  Default = [3.,30.]
;
;   THRESH:    Minimum value of d(logF)/d(logE) for identifying a 
;              discontinuity in the electron energy spectrum for the
;              SWE+ method.  Default = 0.05.
;
;              The optimal value depends on the plasma environment.
;
;   MINFLUX:   Minimum peak energy flux for the SWE+ method.
;              Default = 1e6.
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature.  This excludes features not related
;              to the spacecraft potential at higher energies (often 
;              observed downstream of the shock).  Default = 6 eV.
;
;   DDD:       Use 3D data to calculate potential.  Allows bin masking,
;              but lower cadence and typically lower energy resolution.
;
;   ABINS:     When using 3D spectra, specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     When using 3D spectra, specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   OBINS:     When using 3D spectra, specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = reform(ABINS#DBINS,96).  Takes precedence over
;              ABINS and OBINS.
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking specified by the above three keywords.
;              Default = 1 (yes).
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   SETVAL:    Make no attempt to estimate the potential, just set it to
;              this value.  Units = volts.  No default.
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   ANGCORR:   Angular distribution correction based on interpolated 3d data
;              to emphasize the returning photoelectrons and improve 
;              the edge detection (added by Yuki Harada).
;
;   COMPOSITE: The composite potential (SWE/LPW, SWE+, SWE-, STA-) has  
;              been pre-calculated with this routine and stored in save 
;              files.  Set this keyword to simply restore this file and
;              save lots of time.  (Works for multiple days and can span
;              UT day boundaries.)  Soon to be the default.
;
;   LPWPOT:    Use pre-calculated LPW/SWE derived potentials.  There is
;              a ~2-week delay in the production of this dataset.  You can
;              set this keyword to the full path and filename of a tplot 
;              save/restore file, if one exists.  Otherwise, this routine 
;              will determine the potential from SWEA alone.
;
;   LPW_L2:    Load the LPW L2 potentials for comparison.
;
;   MIN_LPW_POT : Minumum valid LPW potential.
;
;   POSPOT:    Calculate positive potentials with mvn_swe_sc_pot.
;              Default = 1 (yes).
;
;   NEGPOT:    Calculate negative potentials with mvn_swe_sc_negpot.
;              Default = 1 (yes).
;
;   STAPOT:    Use STATIC-derived potentials to fill in gaps.  This is 
;              especially useful in the high-altitude shadow region.
;              Assumes that you have calculated STATIC potentials.
;              (See mvn_sta_scpot_load.pro)
;
;   MAXALT:    Maximum altitude for replacing SWE/LPW and SWE+ potentials
;              with SWE- or STA- potentials.
;
;   MAXDT:     Maximum time gap to interpolate across.  Default = 64 sec.
;              
;   SHAPOT:    Calculate negative potentials with 'mvn_swe_sc_negpot_
;              twodir_burst'.  Two estimates are obtained, one each for
;              the parallel and anti-parallel electron populations.  If
;              both directions yield a potential, then the one closer to 
;              zero is chosen for merging with other methods.
;              Requires keyword NEGPOT to be set. 
;
;OUTPUTS:
;   None - Result is stored in the SPEC data structure, returned via the 
;          POTENTIAL keyword, and stored as TPLOT variables.  Two TPLOT
;          variables are created: one with a single merged potential and
;          one showing the five unmerged methods in one panel.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-10-02 17:57:06 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24098 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot.pro $
;
;-

pro mvn_scpot, potential=pot, erange=erange2, thresh=thresh2, dEmax=dEmax2, $
               pans=pans, ddd=ddd, abins=abins, dbins=dbins, obins=obins2, $
               mask_sc=mask_sc, setval=setval, badval=badval2, $
               angcorr=angcorr, minflux=minflux2, pospot=pospot, $
               negpot=negpot, stapot=stapot, lpwpot=lpwpot, $
               shapot=shapot, composite=composite, maxdt=maxdt2, $
               maxalt=maxalt2, min_lpw_pot=min_lpw_pot2

  compile_opt idl2
  
  @mvn_swe_com
  @mvn_scpot_com

  if (size(Espan,/type) eq 0) then mvn_scpot_defaults

; Override defaults by keyword.  Affects all routines that use mvn_scpot_com.

  if (n_elements(erange2)  gt 1) then Espan = float(minmax(erange2))
  if (size(thresh2,/type)  gt 0) then thresh = float(thresh2)
  if (size(dEmax2,/type)   gt 0) then dEmax = float(dEmax2)
  if (size(minflux2,/type) gt 0) then minflux = float(minflux2)
  if (size(badval2,/type)  gt 0) then badval = float(badval2)
  if (size(maxalt2,/type)  gt 0) then maxalt = float(maxalt2)
  if (size(min_lpw_pot2,/type) gt 0) then min_lpw_pot = float(min_lpw_pot2)

; Set processing flags

  if (size(lpwpot,/type) eq 0) then lpwpot = 1
  if (size(pospot,/type) eq 0) then pospot = 1
  if (size(negpot,/type) eq 0) then negpot = 1
  if (size(stapot,/type) eq 0) then stapot = 1
  shapot = keyword_set(shapot)
  if (shapot) then negpot = 1  ; required for pot_in_shadow to work

; Configure the 3D FOV mask

  do3d = keyword_set(ddd)

  if ((size(obins,/type) eq 0) or keyword_set(abins) or keyword_set(dbins) or $
      keyword_set(obins2) or (size(mask_sc,/type) ne 0)) then begin
    if (n_elements(abins)  ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins)  ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins2) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins2 # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  endif

; Make sure electron energy spectra are available

  maxdt = 64  ; Define data gap as dt > maxdt seconds

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  npts = n_elements(mvn_swe_engy)

; Set the potential manually

  if (size(setval,/type) ne 0) then begin
    print,"Setting the s/c potential to: ",setval
    mvn_sc_pot = replicate(mvn_pot_struct, npts)
    mvn_sc_pot.time = mvn_swe_engy.time
    mvn_sc_pot.potential = setval
    mvn_sc_pot.method = 0  ; potential set manually

    pot = mvn_sc_pot              ; set return keyword value
    mvn_swe_engy.sc_pot = setval  ; fill in SWEA SPEC potentials
    swe_sc_pot = mvn_sc_pot       ; fill in SWEA potential common block

    phi = {x:mvn_sc_pot.time, y:mvn_sc_pot.potential}
    store_data,'mvn_sc_pot',data=phi

    str_element,phi,'thick',2,/add
    str_element,phi,'color',0,/add
    str_element,phi,'psym',3,/add
    store_data,'swe_pot_overlay',data=phi
    store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
    ylim,'swe_a4_pot',3,5000,1
    return
  endif
  
; Clear any previous potential calculations

  tmin = min(timerange(), max=tmax)
  badphi = !values.f_nan  ; bad value that's guaranteed to be a NaN

  mvn_sc_pot = replicate(mvn_pot_struct, npts)
  mvn_sc_pot.time = mvn_swe_engy.time
  mvn_sc_pot.potential = badphi
  mvn_sc_pot.method = -1

  mvn_swe_engy.sc_pot = badphi

; Get pre-calculated, pre-prioritized composite potentials

  if keyword_set(composite) then begin
    mvn_scpot_restore, result=comp, /tplot, success=ok
    if (ok) then begin
      print,"Using SWE/LPW/STA composite potential."
      indx = where(comp.method eq -1, count)
      if (count gt 0L) then comp[indx].potential = badphi

      phi = interpol(comp.potential, comp.time, mvn_sc_pot.time)
      indx = nn(comp.time, mvn_sc_pot.time)
      method = comp[indx].method
      gap = where(abs(comp[indx].time - mvn_sc_pot.time) gt maxdt, count)
      if (count gt 0L) then begin
        phi[gap] = badphi
        method[gap] = -1
      endif

      mvn_sc_pot.potential = phi
      mvn_sc_pot.method = method  ; various methods

      lpwpot = 0
      pospot = 0
      negpot = 0
      stapot = 0
      shapot = 0

    endif else print,"SWE/LPW/STA composite potential not available."
  endif

; Get the EUV shadow location

  get_data, 'wake', data=wake, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /load, /shadow
    get_data, 'wake', data=wake, index=i
  endif
  if (i eq 0) then begin
    print,"Cannot get orbit information!  Problem with maven_orbit_tplot."
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
    return
  endif
  wake = interpol(wake.y, wake.x, mvn_sc_pot.time)
  indx = where(finite(wake), count)
  wake = replicate(0B, n_elements(mvn_sc_pot.time))
  if (count gt 0L) then wake[indx] = 1B

; Get the altitude

  get_data, 'alt', data=alt
  alt = spline(alt.x, alt.y, mvn_sc_pot.time)

; First priority: Get pre-calculated potentials from SWEA-LPW analysis.

  if (lpwpot) then begin
     get_data, 'mvn_swe_lpw_scpot_pol', index=i
     if (i gt 0) then store_data, 'mvn_swe_lpw_scpot_pol', /delete
     mvn_swe_lpw_scpot_restore

     get_data, 'mvn_swe_lpw_scpot_pol', data=lpwphi, index=i
     if (i gt 0) then begin
        print,"Using SWE/LPW potential."
        options,'mvn_swe_lpw_scpot_pol','psym',3
        options,'mvn_swe_lpw_scpot_pol','color',!p.color

;       Don't use potentials more negative than min_lpw_pot

        igud = where(lpwphi.y gt min_lpw_pot, ngud, complement=ibad, ncomplement=nbad)
        if (nbad gt 0L) then lpwphi.y[ibad] = badphi

        if (ngud gt 0L) then begin
          xgud = lpwphi.x[igud]

          phi = interpol(lpwphi.y, lpwphi.x, mvn_sc_pot.time)  ; interpolate with NaNs

          indx = nn(xgud, mvn_sc_pot.time)
          gap = where(abs(xgud[indx] - mvn_sc_pot.time) gt maxdt, count)
          if (count gt 0L) then phi[gap] = badphi   ; valid estimates too far away

          indx = where(finite(phi) and (mvn_sc_pot.method lt 1), count)
          if (count gt 0L) then begin
            mvn_sc_pot[indx].potential = phi[indx]
            mvn_sc_pot[indx].method = 1  ; swe/lpw method
          endif

        endif else print, "No valid SWE/LPW potentials."

     endif else print, "SWE/LPW potential not available."
  endif

; Second priority: Estimate positive potential from SWEA alone
  
  if (pospot) then begin
    mvn_swe_sc_pot, potential=phi
    indx = where((mvn_sc_pot.method lt 1) and (phi.method eq 2), count)
    if (count gt 0) then mvn_sc_pot[indx] = phi[indx]
  endif

; Third priority: Estimate negative potentials from SWEA (He-II feature)
;   This fills in missing negative LPW-derived potentials.

  if (negpot) then begin    
    mvn_swe_sc_negpot, potential=phi
    indx = where((mvn_sc_pot.method lt 1) and (phi.method eq 3), count)
    if (count gt 0) then mvn_sc_pot[indx] = phi[indx]
;   indx = where((alt le maxalt) and (phi.method eq 3) and (mvn_sc_pot.potential gt 0.), count)
;   if (count gt 0) then mvn_sc_pot[indx] = phi[indx]

    options,'neg_pot','color',6
  endif        

; Fourth priority: Use STATIC-derived negative potentials.

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

;     Only use STA potentials between min_sta_pot and zero.

      igud = where((stapot.y lt 0.) and (stapot.y gt min_sta_pot), ngud, comp=ibad, ncomp=nbad)
      if (nbad gt 0L) then stapot.y[ibad] = badphi
      msg = string("STA- : ",ngud," valid potentials from ",ngud+nbad," spectra",format='(a,i8,a,i8,a)')
      print, strcompress(strtrim(msg,2))

      if (ngud gt 0L) then begin
        xgud = stapot.x[igud]

        phi = interpol(stapot.y, stapot.x, mvn_sc_pot.time)  ; interpolate with NaNs
        indx = nn(xgud, mvn_sc_pot.time)
        gap = where(abs(xgud[indx] - mvn_sc_pot.time) gt maxdt, count)
        if (count gt 0L) then phi[gap] = badphi   ; valid estimates too far away

;       Trust all negative values within the EUV shadow and above max_sta_alt

        indx = where(finite(phi) and wake and (alt gt max_sta_alt), count)
        if (count gt 0L) then begin
          mvn_sc_pot[indx].potential = phi[indx]
          mvn_sc_pot[indx].method = 4  ; sta_pot method
        endif

;       Fill in missing values.  If more than one method [LPW, SWE, STA] provides a
;       value, choose one that closer to zero or positive.

        indx = where((phi gt min_sta_pot) and $
                     ((phi gt mvn_sc_pot.potential) or (mvn_sc_pot.method lt 1)), count)
        if (count gt 0L) then begin
          mvn_sc_pot[indx].potential = phi[indx]
          mvn_sc_pot[indx].method = 4  ; sta_pot method
        endif

      endif else print, "No valid STATIC potentials."
    endif else print, "STATIC potential not available."
  endif

; Last priority: Estimate negative potential from SWEA PAD data

  if (shapot) then begin
    print,"Estimating negative potentials from SWEA PAD data."

    mvn_swe_sc_negpot_twodir_burst, potential=phi, /shadow

    indx = where((phi.method eq 5) and (mvn_sc_pot.method lt 1), count)
    if (count gt 0L) then begin
      mvn_sc_pot[indx] = phi[indx]
      mvn_swe_engy[indx].sc_pot = phi[indx].potential
    endif             

    options,'pot_inshdw','constant',!values.f_nan
    options,'pot_inshdw','color',1
  endif

; Finish up

  if (finite(badval)) then begin
    indx = where(mvn_sc_pot.method lt 1, count)
    if (count gt 0L) then begin
      mvn_sc_pot[indx].potential = badval
      mvn_sc_pot[indx].method = 0
    endif
  endif

  pot = mvn_sc_pot
  mvn_swe_engy.sc_pot = mvn_sc_pot.potential
  swe_sc_pot = mvn_sc_pot

; Create the electron energy spectra overlay

  phi = {x:mvn_sc_pot.time, y:mvn_sc_pot.potential}
  str_element,phi,'thick',2,/add
  str_element,phi,'color',0,/add
  str_element,phi,'psym',3,/add
  store_data,'swe_pot_overlay',data=phi
  store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
  ylim,'swe_a4_pot',3,5000,1

  tplot_options, get=opt
  str_element, opt, 'varnames', varnames, success=ok
  if (ok) then begin
    i = (where(varnames eq 'swe_a4'))[0]
    if (i ne -1) then begin
      varnames[i] = 'swe_a4_pot'
      tplot, varnames
    endif
  endif

; Create a tplot variable for all potential methods (with overlap)

  potpans = ['mvn_swe_lpw_scpot_pol','swe_pos','neg_pot','mvn_sta_c6_scpot','pot_inshdw']
  potlabs = ['swe/lpw', 'swe+', 'swe-', 'sta', 'swe-(sh)']
  potcols = [!p.color, 2, 6, 4, 1]

  store_data,'swe_pot_lab',data={x:minmax(mvn_sc_pot.time), y:replicate(!values.f_nan,2,5)}
  options,'swe_pot_lab','labels',reverse(potlabs)
  options,'swe_pot_lab','colors',reverse(potcols)
  options,'swe_pot_lab','labflag',1

  potall = 'mvn_swe_pot_all'
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

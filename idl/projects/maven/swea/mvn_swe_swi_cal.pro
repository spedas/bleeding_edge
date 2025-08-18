;+
;PROCEDURE:   mvn_swe_swi_cal
;PURPOSE:
;  Compares ion density from SWIA and electron density from SWEA for the purpose 
;  of cross calibration.  Beware of situations where SWEA and/or SWIA are not
;  measuring important parts of the distribution.  Furthermore, SWEA data must be
;  corrected for spacecraft potential (see mvn_scpot), and photoelectron 
;  contamination must be removed for any hope of a decent cross calibration.  For
;  some distributions, secondary electrons can also bias the SWEA density estimate.
;
;USAGE:
;  mvn_swe_swi_cal
;
;INPUTS:
;   None.  Uses the current value of TRANGE_FULL to define the time range
;   for analysis.  Calls timespan, if necessary, to set this value.
;
;KEYWORDS:
;   COARSE:    Select SWIA 'coarse' data for analysis.  Provides density estimates
;              in the sheath.  Not recommended for cross calibration.
;
;   FINE:      Select SWIA 'fine' data for analysis.  This is the default.
;
;   ALPHA:     Calculate both proton and alpha densities using SWIA code.
;              Requires 'fine' data, so this forces FINE to be set.
;
;   DDD:       Use SWEA 3D data for computing density.  Allows for bin
;              masking.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-01-08 16:07:28 -0800 (Mon, 08 Jan 2024) $
; $LastChangedRevision: 32342 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_swi_cal.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_swi_cal, coarse=coarse, fine=fine, alpha=alpha, ddd=ddd, pans=pans, burst=burst, $
                     noswi=noswi

  @mvn_swe_com

  tplot_options, get=opt
  if (max(opt.trange_full) eq 0D) then timespan

  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if keyword_set(coarse) then fine = 0
  if (size(fine,/type) eq 0) then fine = 1
  if keyword_set(alpha) then fine = 1
  burst = keyword_set(burst)
  doswi = ~keyword_set(noswi)

; Get electron density from SWEA - create a variable for overplotting
; with SWIA densities.

  if (dflg) then dname = 'mvn_swe_3d_dens' else dname = 'mvn_swe_spec_dens'
  get_data,dname,data=den,index=i
  if (i eq 0) then begin
    print,"You must calculate SWEA densities first."
    return
  endif
  dt = den.x - shift(den.x,1)
  indx = where(dt gt 600D, count)
  if (count gt 0L) then den.y[indx] = !values.f_nan
  store_data,'nelectron',data=den

  pans = ['']

; Load SWIA fine spectra

  if (doswi) then begin
    mvn_swia_load_l2_data, /loadall, /tplot
    mvn_swia_part_moments, type=['cs','ca'] ; get coarse moments (mainly for sheath)

    if keyword_set(fine) then begin
      if keyword_set(alpha) then begin
        mvn_swia_protonalphamoms_minf,archive=burst  ; uses fine data to calculate moments
        get_data,'nproton',data=den
        dt = den.x - shift(den.x,1)
        indx = where(dt gt 600D, count)
        if (count gt 0L) then den.y[indx] = !values.f_nan
        store_data,'nproton',data=den
        get_data,'nalpha',data=den
        dt = den.x - shift(den.x,1)
        indx = where(dt gt 600D, count)
        if (count gt 0L) then den.y[indx] = !values.f_nan
        store_data,'nalpha',data=den
        pans = ['nproton','nalpha']

        add_data,'nproton','nalpha'
        get_data,'nproton+nalpha',data=den

        options,'vproton','colors',[2,4,6]
        options,'vproton','labels',['Vx','Vy','Vz']
        options,'vproton','labflag',1
        get_data,'vproton',data=vp

        vph = atan(vp.y[*,1],vp.y[*,0])*!radeg
        indx = where(vph lt 0., count)
        if (count gt 0L) then vph[indx] += 360.
        vmag = sqrt(total(vp.y^2.,2,/nan))
        vth = asin(vp.y[*,2]/vmag)*!radeg

        store_data,'vmag_proton',data={x:vp.x, y:vmag}
        options,'vmag_proton','ytitle','|V| (H+)'
        options,'vmag_proton','psym',3
        options,'vmag_proton','colors',4
        options,'vmag_proton','constant',[300.,400.,500.]

        store_data,'vph_proton',data={x:vp.x, y:vph}
        options,'vph_proton','ytitle','Vph (H+)'
        options,'vph_proton','colors',4
        options,'vph_proton','psym',3
        options,'vph_proton','ynozero',1
        abb = 1.5  ; nominal SW aberration angle at Mars (deg)
        options,'vph_proton','constant',[180. + abb]

        store_data,'vth_proton',data={x:vp.x, y:vth}
        options,'vth_proton','ytitle','Vth (H+)'
        options,'vth_proton','colors',4
        options,'vth_proton','psym',3
        options,'vth_proton','ynozero',1
        options,'vth_proton','constant',[0.]
      endif else begin
        mvn_swia_part_moments, type=['fs','fa']  ; just calculate fine moments directly
        get_data,'mvn_swifs_density',data=den

        dt = den.x - shift(den.x,1)
        indx = where(dt gt 600D, count)
        if (count gt 0L) then den.y[indx] = !values.f_nan
        store_data,'nion',data=den
      endelse

    endif else begin
      get_data,'mvn_swics_density',data=den

      dt = den.x - shift(den.x,1)
      indx = where(dt gt 600D, count)
      if (count gt 0L) then den.y[indx] = !values.f_nan
      store_data,'nion',data=den
    endelse

    store_data,'ie_density',data=['nion','nelectron',pans]
    ylim,'ie_density',0.01,10,1
    options,'ie_density','ytitle','Ion-Electron!CDensity'
    options,'ie_density','colors',[!p.color,6,4,1]
    options,'ie_density','labels',['i+','e-','H+','He++']
    options,'ie_density','labflag',1

    divname = 'swe_swi_crosscal'
    div_data,'nion','nelectron',newname=divname
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWI/SWE'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1

  endif else begin
    options,'mvn_swics_density','ynozero',1
    get_data,'mvn_swics_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'nion',data=den

    store_data,'ie_density',data=['nion','nelectron']
    ylim,'ie_density',0.1,10,1
    options,'ie_density','ynozero',1
    options,'ie_density','ytitle','Ion-Electron!CDensity'
    options,'ie_density','colors',[4,6]
    options,'ie_density','labels',['i+','e-']
    options,'ie_density','labflag',1

    divname = 'swe_swi_crosscal'
    div_data,'nion','nelectron',newname=divname
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWI/SWE'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1
  endelse

  pans = [divname,'ie_density']

  return

end

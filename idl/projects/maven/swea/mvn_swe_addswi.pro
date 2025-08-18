;+
;PROCEDURE:   mvn_swe_addswi
;PURPOSE:
;  Loads SWIA data and calculates moments based on coarse survey.  All calculations
;  are performed with the SWIA code, which stores the results as tplot variables.
;
;USAGE:
;  mvn_swe_addswi
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    FINE:          Calculate moments with fine survey.  This provides better values
;                   in the upstream solar wind.
;
;    ALPHA:         Calculate both proton and alpha densities using SWIA code.
;                   Requires 'fine' data, so this forces FINE to be set.
;
;    PANS:          Named variable to hold an array of
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-01-08 16:06:22 -0800 (Mon, 08 Jan 2024) $
; $LastChangedRevision: 32341 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addswi.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addswi, fine=fine, alpha=alpha, pans=pans

  if keyword_set(alpha) then fine = 1

  mvn_swia_load_l2_data, /loadall, /tplot
  if keyword_set(fine) then begin
    if keyword_set(alpha) then begin
      mvn_swia_protonalphamoms_minf  ; uses fine data to calculate moments
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

      add_data,'nproton','nalpha'
      get_data,'nproton+nalpha',data=den

      store_data,'nion',data=['nproton+nalpha','nproton','nalpha']
      ylim,'nion',0.1,1000,1
      options,'nion','ytitle','Density (cm!u-3!n)'
      options,'nion','line_colors',5
      options,'nion','colors',[!p.color,3,4] ; foreground, lt. blue, green
      options,'nion','labels',['Ni','H+','He++']
      options,'nion','labflag',1

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

      pans = ['nion','vmag_proton']
    endif else begin
      mvn_swia_part_moments, type=['fs']  ; just calculate fine moments directly
      get_data,'mvn_swifs_density',data=den
      dt = den.x - shift(den.x,1)
      indx = where(dt gt 600D, count)
      if (count gt 0L) then den.y[indx] = !values.f_nan
      store_data,'nion',data=den
      ylim,'nion',0.1,1000,1
      options,'nion','ytitle','Density (cm!u-3!n)'

      get_data,'mvn_swifs_velocity',data=vi
      dt = vi.x - shift(vi.x,1)
      indx = where(dt gt 600D, count)
      if (count gt 0L) then vi.y[indx,*] = !values.f_nan
      store_data,'vion',data=vi
      options,'vion','ytitle','Velocity (km/s)'
      options,'vion','colors',[2,4,6]
      options,'vion','labels',['Vx','Vy','Vz']
      options,'vion','labflag',1

      vph = atan(vi.y[*,1],vi.y[*,0])*!radeg
      indx = where(vph lt 0., count)
      if (count gt 0L) then vph[indx] += 360.
      vmag = sqrt(total(vi.y^2.,2,/nan))
      vth = asin(vi.y[*,2]/vmag)*!radeg

      store_data,'vmag_ion',data={x:vi.x, y:vmag}
      options,'vmag_ion','ytitle','|V| (i+)'
      options,'vmag_ion','psym',3
      options,'vmag_ion','colors',4
      options,'vmag_ion','constant',[300.,400.,500.]

      store_data,'vph_ion',data={x:vi.x, y:vph}
      options,'vph_ion','ytitle','Vph (i+)'
      options,'vph_ion','colors',4
      options,'vph_ion','psym',3
      options,'vph_ion','ynozero',1
      abb = 1.5  ; nominal SW aberration angle at Mars (deg)
      options,'vph_ion','constant',[180. + abb]

      store_data,'vth_ion',data={x:vi.x, y:vth}
      options,'vth_ion','ytitle','Vth (i+)'
      options,'vth_ion','colors',4
      options,'vth_ion','psym',3
      options,'vth_ion','ynozero',1
      options,'vth_ion','constant',[0.]

      pans = ['nion','vmag_ion']
    endelse
  endif else begin
    mvn_swia_part_moments, type=['cs']
    get_data,'mvn_swics_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'nion',data=den
    ylim,'nion',0.1,1000,1
    options,'nion','ytitle','Density (cm!u-3!n)'

    get_data,'mvn_swics_velocity',data=vi
    dt = vi.x - shift(vi.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then vi.y[indx,*] = !values.f_nan
    store_data,'vion',data=vi
    options,'vion','ytitle','Velocity (km/s)'
    options,'vion','colors',[2,4,6]
    options,'vion','labels',['Vx','Vy','Vz']
    options,'vion','labflag',1

    vph = atan(vi.y[*,1],vi.y[*,0])*!radeg
    indx = where(vph lt 0., count)
    if (count gt 0L) then vph[indx] += 360.
    vmag = sqrt(total(vi.y^2.,2,/nan))
    vth = asin(vi.y[*,2]/vmag)*!radeg

    store_data,'vmag_ion',data={x:vi.x, y:vmag}
    options,'vmag_ion','ytitle','|V| (i+)'
    options,'vmag_ion','psym',3
    options,'vmag_ion','colors',4
    options,'vmag_ion','constant',[300.,400.,500.]

    store_data,'vph_ion',data={x:vi.x, y:vph}
    options,'vph_ion','ytitle','Vph (i+)'
    options,'vph_ion','colors',4
    options,'vph_ion','psym',3
    options,'vph_ion','ynozero',1
    abb = 1.5  ; nominal SW aberration angle at Mars (deg)
    options,'vph_ion','constant',[180. + abb]

    store_data,'vth_ion',data={x:vi.x, y:vth}
    options,'vth_ion','ytitle','Vth (i+)'
    options,'vth_ion','colors',4
    options,'vth_ion','psym',3
    options,'vth_ion','ynozero',1
    options,'vth_ion','constant',[0.]

    pans = ['nion','vmag_ion']
  endelse

  return
  
end

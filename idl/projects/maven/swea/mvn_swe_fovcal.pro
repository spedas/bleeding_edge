;+
;PROCEDURE:   mvn_swe_fovcal
;PURPOSE:
;  Given 3D electron distributions, the magnetic field direction, the 
;  solar wind velocity, and the spacecraft potential, this routine 
;  estimates the relative sensitivities of the SWEA 3D angular bins.
;  The technique takes advantage of the fact that the electron 
;  distribution should be very nearly gyrotropic in the plasma rest 
;  frame.
;
;  Assumptions: (1) The measured magnetic field vector is accurate, and
;                   apparent deviations from gyrotropy are caused entirely
;                   by uncompensated variations in sensitivity around the
;                   field of view.
;
;               (2) A polynomial fit to the measured distribution is a
;                   reasonable approximation to the "true" distribution.
;                   Corollary: There are no sharp features in the pitch
;                   angle distribution.
;
;  Errors caused by (1) can be minimized by comparing the magnetic field
;  vector to the symmetry direction of the electron angular distribution.
;  Only times when these two directions agree to within a fraction of a 
;  ~20-deg-wide angular bin are used.  Exceptions can be made when the
;  magnetic field vector is in or near one of SWEA's blind spots, in which
;  case the symmetry direction is ill defined.  See swe_3d_strahl_dir.
;
;  Errors caused by (2) can be minimized by visually inspecting the fits
;  before adding the calibration to the database.  There are, occasionally,
;  sharp features in the pitch angle distribution, and these should be
;  avoided.
;
;  Since the calibration is based on numerous pitch angle distributions, 
;  each with its own polynomial fit, the assumption is that any remaining
;  errors introduced by (1) and (2) will be averaged out.
;
;USAGE:
;  mvn_swe_fovcal, result=result
;
;INPUTS:
;
;KEYWORDS:
;       UNITS:     Units.
;
;       MINCNTS:   Minimum number of raw counts for calculating the result.
;                  Used to ensure reasonable statistics. Default = 30.
;
;       ORDER:     A one- or two-element integer array specifying the 
;                  polynomial orders for each half of the pitch angle
;                  distribution.  Default = [4,4].
;
;       MIDPA:     Pitch angle at which to divide the spectrum for fitting
;                  each polynomial.  Default = 90 deg.
;
;       OLAP:      Pitch angle width for overlapping MIDPA for polynomial 
;                  fits.  Produces more reasonable fits by constraining the
;                  polynomial to continue going through data points beyond
;                  MIDPA.  Default = 10 deg.
;
;       ENERGY:    Energy at which to perform the calibration.  Default is
;                  125 eV.
;
;       SYMDIR:    Use the 3D symmetry direction instead of the magnetic
;                  field vector.  Use with caution, since this routine is
;                  symmetrizes the distribution based on this direction.
;
;       SCP:       Set the spacecraft potential to this value.
;
;       CALNUM:    Set the nominal calibration to this solar wind period.
;                  Default = 1.
;
;       RESULT:    A structure containing the time and a 96-element array
;                  containing the relative geometric factors for the 3D
;                  bins.
;
;       KILLWINS:  Delete the windows upon completion.  Default is to keep
;                  and reuse them for subsequent plots.
;
;CREATED BY:	David L. Mitchell  2016-08-03
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-06-05 12:17:33 -0700 (Mon, 05 Jun 2023) $
; $LastChangedRevision: 31883 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_fovcal.pro $
;-
pro mvn_swe_fovcal, units=units, mincnts=mincnts, order=order, energy=energy, $
                    midpa=midpa, olap=olap, symdir=symdir, result=result, $
                    lon=lon, lat=lat, calnum=calnum, scp=scp, killwins=killwins

  @mvn_swe_com
  common colors_com
  common fovcal_windows, Pwin, Gwin, Fwin

  ctab = color_table
  crev = color_reverse
  initct, 34  ; shows low values better in specplot

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill
  csz = 1.5
  device, window_state=ws

  dat = 0
  Twin = !d.window
  if (size(units,/type) ne 7) then units = 'eflux'
  if not keyword_set(mincnts) then mincnts = 30.
  if not keyword_set(energy) then eref = 125. else eref = float(energy)
  if not keyword_set(midpa) then midpa = 90. else midpa = float(midpa)
  if not keyword_set(olap) then olap = 10. else olap = float(olap)
  if not keyword_set(lon) then lon = 180.
  if not keyword_set(lat) then lat = 0.
  if not keyword_set(calnum) then calnum = 1
  if keyword_set(symdir) then begin
    dosym = 1
    get_data, 'Saz', data=Saz, index=i
    if (i eq 0) then dosym = 0
    get_data, 'Sel', data=Sel, index=i
    if (i eq 0) then dosym = 0
  endif else dosym = 0

  names = ['a0','a1','a2','a3','a4','a5']
  n = n_elements(order)
  if (n gt 0L) then name1 = names[0:(order[0]<5)>0] else name1 = names[0:4]
  if (n gt 1L) then name2 = names[0:(order[1]<5)>0] else name2 = names[0:4]

; Select 3D distributions for analysis

  swe_3d_snap,ddd=dat,units=units,sum=1,energy=eref
  if (size(dat,/type) ne 8) then begin
    print,"Abort!"
    initct, ctab, reverse=crev
    return
  endif
  if (size(scp,/type) ne 0) then scp = float(scp) else scp = dat.sc_pot
  if (~finite(scp)) then begin
    print,"No spacecraft potential!"
    initct, ctab, reverse=crev
    return
  endif
  
  trange = [dat.time - dat.delta_t/2D, dat.time + dat.delta_t/2D]

; Optionally replace the magnetic field vector with the symmetry direction

  if (dosym) then begin
    Bt = Saz.x
    Saz = Saz.y * !dtor
    Sel = Sel.y * !dtor
    Bamp = sqrt(total(dat.magf^2.))
    Bx = Bamp*cos(Saz)*cos(Sel)
    By = Bamp*sin(Saz)*cos(Sel)
    Bz = Bamp*sin(Sel)
    
    indx = where((Bt ge trange[0]) and (Bt le trange[1]), count)
    if (count gt 0L) then begin
      dat.magf[0] = average(Bx[indx],/nan)
      dat.magf[1] = average(By[indx],/nan)
      dat.magf[2] = average(Bz[indx],/nan)
    endif else print,"No symmetry direction!"
  endif

; Transform to plasma rest frame, where gyrotropy condition applies

  edat = dat
  time = edat.time
  idat = mvn_swia_get_3dc(time)
  ivel = v_3d(idat) ; SWIA coordinate frame
  vel = spice_vector_rotate(ivel, time, 'MAVEN_SWIA', 'MAVEN_SWEA', $
                            check_objects='MAVEN_SPACECRAFT',verbose=1)
  vmag = sqrt(total(vel*vel))
  vphi = atan(vel[1],vel[0])*!radeg
  vthe = asin(vel[2]/vmag)*!radeg

  valid = edat.valid
  str_element, edat, 'valid', 1B, /add_replace     ; kluge for convert_vframe
  data = convert_vframe(edat, vel, sc_pot=edat.sc_pot, /interpolate)
  str_element, data, 'valid', valid, /add_replace  ; replace valid array
  mvn_swe_convert_units, data, units
  dat = data

; Extract variables for fitting

  mvn_swe_padmap_3d, dat
  e = dat.energy[*,0]
  de = min(abs(e - eref),i_e)
  f = reform(dat.data[i_e,*])
  df = sqrt(reform(dat.var[i_e,*]))
  pa = reform(dat.pa[i_e,*])*!radeg

  c = dat
  mvn_swe_convert_units, c, 'counts'
  c = reform(c.data[i_e,*])
  indx = where(c gt 1.e6, count)
  if (count gt 0L) then c[indx] = !values.f_nan

; Mask blockage by spacecraft

  gud = where((swe_sc_mask[*,1] eq 1) and (f gt 0.) and (c gt mincnts), ngud)
  if (ngud lt 2) then begin
    print,"Not enough good data!"
    initct, ctab, reverse=crev
    return
  endif
  bad = where(swe_sc_mask[*,1] eq 0, nbad)
  mask = replicate(1.,96)
  mask[bad] = !values.f_nan

; Fit the 0-90-deg and 90-180-deg halves of the pitch angle distribution
; separately with polynomials.  The ratio of the residuals to the fitted
; curves is an estimate of the relative geometric factor (with noise).
; (Assumes that the polynomial fits are an accurate representation of the
; "true" pitch angle distribution.  Assumes that the pitch angle mapping
; over the field of view is accurate.)

  ok = 0
  if (size(Pwin,/type) gt 0) then begin
    if (ws[Pwin]) then begin
      wset, Pwin
      if ((!d.x_size eq 780) and (!d.y_size eq 710)) then ok = 1
    endif
  endif
  if (~ok) then begin
    win, /free, xsize=780, ysize=710, /secondary, dx=10, dy=10
    Pwin = !d.window
  endif

  !p.multi = [2,1,2,0,0]
    erase
    plot_io,pa[gud],f[gud],psym=3,xrange=[0,180],/xsty,xticks=6,xminor=3,charsize=csz,$
                 ytitle='Eflux',xmargin=[12,10]
    oploterr,pa[gud],f[gud],df[gud],3

    indx = where(pa[gud] le (midpa + olap))
    x1 = pa[gud[indx]]
    y1 = f[gud[indx]]
    dy1 = df[gud[indx]]
    p1 = {a0:double(min(y1)), a1:0d, a2:0d, a3:0d, a4:0d, a5:0d}
    fit,x1,y1,dy=dy1,func='polycurve',par=p1,names=name1
    npa = round(midpa)
    oplot,findgen(npa+1),polycurve(findgen(npa+1),par=p1),color=4,thick=2

    jndx = where(pa[gud] gt (midpa - olap))
    x2 = 180. - pa[gud[jndx]]
    y2 = f[gud[jndx]]
    dy2 = df[gud[jndx]]
    p2 = {a0:double(min(y2)), a1:0d, a2:0d, a3:0d, a4:0d, a5:0d}
    fit,x2,y2,dy=dy2,func='polycurve',par=p2,names=name2
    npa = round(180. - midpa)
    oplot,180.-findgen(npa+1),polycurve(findgen(npa+1),par=p2),color=6,thick=2

    indx = where(pa[gud] le midpa)  ; use midpa boundary for calculating RGF
    jndx = where(pa[gud] gt midpa)
    rgf = replicate(!values.f_nan, n_elements(f))
    rgf[gud[indx]] = f[gud[indx]]/polycurve(pa[gud[indx]],par=p1)
    rgf[gud[jndx]] = f[gud[jndx]]/polycurve(180. - pa[gud[jndx]],par=p2)
    plot,pa[gud],rgf[gud],psym=1,xrange=[0,180],/xsty,xticks=6,xminor=3,charsize=csz,$
         ytitle='Residual',xmargin=[12,10],xtitle='Pitch Angle (deg)'
    oplot,[0.,180.],[1.,1.],line=2,color=4,thick=2
  !p.multi = 0

; Relative geometric factor as a function of k3d

  ok = 0
  if (size(Gwin,/type) gt 0) then begin
    if (ws[Gwin]) then begin
      wset, Gwin
      if ((!d.x_size eq 600) and (!d.y_size eq 600)) then ok = 1
    endif
  endif
  if (~ok) then begin
    win, /free, xsize=600, ysize=600, relative=Pwin, dy=-10, /left
    Gwin = !d.window
  endif

  !p.multi = [2,1,2,0,0]
    erase
    k3d = findgen(96)
    plot,k3d,rgf,xrange=[0,96],/xsty,xticks=6,xminor=4,charsize=csz, $
         ytitle='Relative Geometric Factor',xtitle='Solid Angle Bin',psym=10
    for i=1,14 do oplot,[i*16,i*16],[0,100],line=1
    for i=0,5 do begin
      rgf_el = average(rgf[(i*16):(i*16+15)],/nan)
      oplot,[i*16,(i+1)*16],replicate(rgf_el,2),color=4,thick=3
    endfor

    plot_io,k3d,c,xrange=[0,96],/xsty,xticks=6,xminor=4,charsize=csz, $
            ytitle='Raw Counts',xtitle='Solid Angle Bin',psym=10
    for i=1,14 do oplot,[i*16,i*16],[1,1e5],line=1
    oplot,minmax(k3d),[mincnts,mincnts],line=2,color=6
  !p.multi = 0

; Relative geometric factor map along with measured distribution

  ok = 0
  if (size(Fwin,/type) gt 0) then begin
    if (ws[Fwin]) then begin
      wset, Fwin
      if ((!d.x_size eq 1200) and (!d.y_size eq 600)) then ok = 1
    endif
  endif
  if (~ok) then begin
    win, /free, xsize=1200, ysize=600, relative=Pwin, dx=10, /top
    Fwin = !d.window
  endif

    erase
    fovcal = dat
    indx = where(swe_sc_mask[*,1] eq 0B, count)
    mask = replicate(1.,96)
    if (count gt 0L) then mask[indx] = !values.f_nan
    fovcal.data[i_e,*] *= mask
    fovcal.data[i_e+1,*] = fovcal.data[i_e,*]/rgf                   ; current cal

    ogf = mvn_swe_flatfield(dat.time, /nominal, /silent)            ; nominal cal
    fovcal.data[i_e+2,*] = fovcal.data[i_e,*]/ogf
    ff = mvn_swe_flatfield(/off, /silent)                           ; no cal

    fovcal.data[i_e+3,*] = rgf
    plot3d_options,map='cyl'

    plot3d_new, fovcal, lat, lon, ebins=[i_e,i_e+1,i_e+2,i_e+3], $
                stack=[2,2], subtitle=['BEFORE','AFTER','NOMINAL','RGF']

    oplot, [vphi], [vthe], psym=8, color=5, symsize=2  ; solar wind velocity direction
  wset,Twin

  result = {time:time, rgf:rgf, trange:trange}
  initct, ctab, reverse=crev

  if keyword_set(killwins) then begin
    device, window_state=ws
    if (ws[Fwin]) then wdelete, Fwin
    if (ws[Gwin]) then wdelete, Gwin
    if (ws[Pwin]) then wdelete, Pwin
  endif

  return

end

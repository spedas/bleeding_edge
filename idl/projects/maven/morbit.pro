;+
;PROCEDURE:   morbit
;PURPOSE:
;  Given the orbit size and shape (based on 2 of 5 orbital parameters),
;  calculates the orbital position and velocity of a satellite around a
;  planet as a function of time.  This routine is very fast when the
;  orbital eccentricity is less than 0.95, but labors when it is very
;  close to unity.  This routine will not work at all for parabolic and
;  hyperbolic orbits.
;
;  Calculations assume a spherical central body with a spherically
;  symmetric mass distribution, and that the mass of the central body
;  dominates in the region of interest.
;
;  You can also specify an orientation for the orbit and then create a
;  'fly-through' in cartesian coordinates.
;
;USAGE:
;  morbit, param, dt=dt, result=dat
;
;INPUTS:
;       PARAM:     Orbit parameter structure, which has two of the
;                  following tags:
;
;                    period : orbital period (hours)
;                    sma    : semi-major axis (km)
;                    palt   : periapsis altitude (km)
;                    aalt   : apoapsis altitude (km)
;                    ecc    : eccentricity
;
;                  The two parameters you specify must define the
;                  size and shape of the orbit.  Any two will work,
;                  except for period and sma, which both define the
;                  orbit size.  The remaining parameters are
;                  calculated from the two you specify.
;
;KEYWORDS:
;       ORIENT:    A structure specifying the orientation of the
;                  orbit with three tags:
;
;                    lon    : longitude of periapsis (deg)
;                    lat    : latitude  of periapsis (deg)
;                    incl   : orbital inclination (deg)
;
;                  Lon and lat can be arrays, resulting in a grid of
;                  calculations.  Incl must be a scalar.
;
;                  Note that abs(lat) <= abs(incl) is required.
;
;                  Default = {lon:0, lat:0, incl:90}
;
;                  Normally, the longitude, latitude, and inclination
;                  are specified in planetocentric coordinates (i.e.,
;                  relative to the planet's spin axis); however, any
;                  coordinate system can be assumed, so long as all
;                  three parameters are in the SAME coordinate system.
;
;       FLYTHRU:   The name for a text output file containing the
;                  cartesian coordinates of the satellite vs. time
;                  for the orbit orientation specified in ORIENT.
;                  The columns for this table are:
;
;                     1 -> time (sec after apoapsis)
;                     2 -> X (km)
;                     3 -> Y (km)
;                     4 -> Z (km)
;                     5 -> orbital velocity (km/s)
;
;                  If you don't specify this keyword, then the
;                  fly-through is still calculated and saved in
;                  RESULT.
;
;       PLANET:    This can be a string to select one of the eight
;                  planets.  The following are also recognized: Moon,
;                  Sun, Pluto, Charon, Eris, and Ceres.  It can also
;                  be a structure with the following tags:
;
;                    Mass   : mass (g)
;                    Radius : radius (km)
;                    Name   : 'name'           [optional]
;
;                  Default = 'Mars'.  If PLANET is unrecognized, you
;                  will be prompted for mass and radius.  This routine
;                  is not expected to give good results for the Pluto-
;                  Charon system, because they have masses within a 
;                  factor of 10 of each other.
;
;       SHOCK:     If PLANET = 'Mars' or 'Earth', then setting this 
;                  keyword will show the nominal shock location on the
;                  orbit plots (see keyword OPLOT).  Default = no.
;
;       SHCOL:     Colors for the shock and MPB.
;
;       SHSTY:     Line style for the shock and MPB.
;
;       DT:        Time resolution (sec).  Default = PARAM.period/1000.
;
;       NORBIT:    Number of orbits for calculating the solution.
;                  Default = 1.
;
;       NMAX:      Maximum number of iterations for the orbit solver.
;                  Default = 400.  Larger numbers might be needed if
;                  the orbital eccentricity is greater than 0.95.
;
;       OERR:      Maximum error in orbit solution, which translates
;                  roughly into fractional error in the position.
;                  Default = 1.e-6.  Increase this only if you want a
;                  quicker solution at the expense of accuracy.
;
;       RESULT:    A structure containing the satellite altitude and
;                  true anomaly versus time.  The true anomaly is the
;                  angle in the plane of the orbit about the center
;                  of the planet, with zero degrees at periapsis. 
;                  The orbital velocity, and the orbit size and shape 
;                  parameters are also given.
;
;       OPLOT:     Plot the orbit with three orthogonal views.
;
;       TPLOT:     Show a time series of altitude and orbital velocity.
;                  (The dashed red line shows escape velocity.)
;
;       WSCALE:    Window size scale factor.  Default = 1.
;
;       XYPLANE:   Plot the orbit in the XY plane only.  Only works if
;                  OPLOT is set.
;
;       XYRANGE:   Axis plot ranges in planetary radii.  Default is to 
;                  fit the orbit on the plot.
;
;       NODOT:     Do not plot a symbol for periapsis.
;
;       PS:        Postscript plots are produced for OPLOT and TPLOT.
;
;       SILENT:    If set, then suppress output.
;
;       SEGMENTS:  Divide the orbit up into segments for color coding.  
;                  This keyword should contain the time in minutes 
;                  relative to apoapsis of each segment boundary.
;                  The first segment extends from APO to SEGMENTS[0].
;                  The last segment extends from SEGMENTS[N-1] to APO,
;                  where N is the number of segments.
;
;       SCOLORS:   Color for each segment.  Must have the same number of
;                  elements as SEGMENTS.
;
;       STHICK:    Line thickness for segments.
;
;       NOPLOT:    No text output, no plots.  Useful for calling this 
;                  routine within a loop.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-01-03 12:12:29 -0800 (Fri, 03 Jan 2025) $
; $LastChangedRevision: 33038 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/morbit.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro morbit, param, dt=dt, planet=planet, nmax=nmax, oerr=oerr, result=result, $
                   norbit=norbit, oplot=oplot, tplot=tplot, orient=orient, $
                   flythru=flythru, shock=shock, ps=ps, xyrange=xyrange, $
                   silent=silent, segments=segments, scolors=scolors, sthick=sthick, $
                   wscale=wscale, xyplane=xyplane, nodot=nodot, noplot=noplot, $
                   shcol=shcol, shsty=shsty

  if (size(param,/type) ne 8) then begin
    print, 'You must specify an orbit parameter structure.'
    return
  endif

  dtor = !dpi/180D
  dodot = ~keyword_set(nodot)
  xyflg = keyword_set(xyplane)
  if (size(wscale,/type) eq 0) then wscale = 1.
  if (xyflg) then wsize = round([535.,500.]*wscale) else wsize = round([326.,920.]*wscale)
  csize = 1.2*wscale
  if (size(shcol,/type) eq 0) then scol = 3 else scol = shcol[0]
  if (size(shsty,/type) eq 0) then ssty = 1 else ssty = shsty[0]
  
  nseg = n_elements(segments)
  if (n_elements(scolors) ne nseg) then begin
    print,"Each segment must have a color."
    return
  endif
  if (nseg gt 0) then begin
    doseg = 1
    tseg = segments*60D
    cseg = scolors
  endif else doseg = 0
  if (n_elements(sthick) eq 0) then sthick = 1. else sthick = float(sthick[0])

  if (size(orient,/type) eq 8) then begin
    str_element, orient, 'lon', lon, success=ok
    if (ok) then lon = double(lon)*dtor else lon = 0D

    str_element, orient, 'lat', lat, success=ok
    if (ok) then lat = double(lat)*dtor else lat = 0D

    str_element, orient, 'incl', incl, success=ok
    if (ok) then incl = double(incl)*dtor else incl = !dpi/2D
  endif else begin
    lon = 0D
    lat = 0D
    incl = !dpi/2D
  endelse

  indx = where(abs(lat) gt abs(incl), count)
  if (count gt 0L) then begin
    print, 'Periapsis latitude is greater than orbit inclination!'
    print, 'Fix the ORIENT keyword and try again.'
    return
  endif

  lat = lat < (0.99999D*incl)
  lat = lat > (-0.99999D*incl)

  nlon = n_elements(lon)
  nlat = n_elements(lat)

  lon = lon # replicate(1.,nlat)
  lat = replicate(1.,nlon) # lat  
  swfrac = replicate(0.,nlon,nlat)
  if (n_elements(swfrac) eq 1) then swfrac = swfrac[0]
  shfrac = swfrac

  if (size(planet,/type) eq 8) then begin
    str_element, planet, 'mass', M, success=ok
    if (not ok) then begin
      print, 'You must specify the planet''s mass (g).'
      return
    endif
    M = double(M)

    str_element, planet, 'radius', R, success=ok
    if (not ok) then begin
      print, 'You must specify the planet''s radius (km).'
      return
    endif
    R = double(R)

    str_element, planet, 'name', Name, success=ok
    if (not ok) then Name = ''

    planet = 'USERDEF'
  endif

  if (size(planet,/type) ne 7) then planet = 'MARS' $
                              else planet = strupcase(planet)

  if not keyword_set(norbit) then norbit = 1D else norbit = double(norbit)

  if not keyword_set(nmax) then nmax = 400L else nmax = long(nmax)

  if not keyword_set(oerr) then oerr = 1.d-6 else oerr = double(oerr)
  oerr = oerr*oerr

  if keyword_set(ps) then begin
    psflg = 1
    scol = 0
  endif else psflg = 0

  blab = ~keyword_set(noplot)

  wsave = !d.window

  if (size(oplot,/type) ne 0) then begin
    oflg = 1
    if (blab) then win,owin,/free,xsize=wsize[0],ysize=wsize[1],/secondary,dx=10,dy=-10
  endif else oflg = 0

  if (size(tplot,/type) ne 0) then begin
    tflg = 1
    if (blab) then begin
      if (oflg) then win,twin,/free,xsize=720,ysize=500,relative=owin,dx=10,/bottom $
                else win,twin,/free,xsize=720,ysize=500,/secondary,dx=10,dy=-10
    endif
  endif else tflg = 0

; Define some constants and change units ([M] = g, [R] = km)
; Source: https://nssdc.gsfc.nasa.gov/planetary/factsheet/index.html
; Last Update: 2016-12-09.

  sflg = 0
  mflg = 0

  case (planet) of
    'SUN'     : begin
                  M = 1.9885d33
                  R = 6.957d5          ; volumetric mean (photosphere)
                end
    'MERCURY' : begin
                  M = 3.3011d26
                  R = 2439.7D          ; volumetric mean (surface)
                end
    'VENUS'   : begin
                  M = 4.8675d27
                  R = 6051.8D          ; volumetric mean (surface)
                end
    'EARTH'   : begin
                  M = 5.9723d27
                  R = 6371.0D          ; volumetric mean (surface)

                  x0 = 3.5             ; shock
                  psi = 1.02
                  L = 22.1

                  sflg = 1
                end
    'MOON'    : begin
                  M = 7.346d25
                  R = 1737.4D          ; volumetric mean (surface)
                end
    'MARS'    : begin
                  M = 6.4171d26
                  R = 3389.5D          ; volumetric mean (surface)

                  x0 = 0.64            ; shock
                  psi = 1.03
                  L = 2.04

                  x0_p1  = 0.640       ; MPB-1 (sub-solar region)
                  psi_p1 = 0.770
                  L_p1   = 1.080

                  x0_p2  = 1.600       ; MPB-2 (flanks)
                  psi_p2 = 1.009
                  L_p2   = 0.528

                  sflg = 1
                  mflg = 1
                end
    'CERES'   : begin
                  M = 9.47d23
                  R = 469.3D           ; volumetric mean (surface)
                end
    'JUPITER' : begin
                  M = 1.8982d30
                  R = 69911D           ; volumetric mean (1 bar)
                end
    'SATURN'  : begin
                  M = 5.6834d29
                  R = 58232D           ; volumetric mean (1 bar)
                end
    'URANUS'  : begin
                  M = 8.6813d28
                  R = 25362D           ; volumetric mean (1 bar)
                end
    'NEPTUNE' : begin
                  M = 1.0241d29
                  R = 24622D           ; volumetric mean (1 bar)
                end
    'PLUTO'   : begin
                  print,"Warning: gravitational influence of Charon could be significant."
                  M = 1.303d25
                  R = 1186D
                end
    'CHARON'  : begin
                  print,"Warning: gravitational influence of Pluto could be significant."
                  M = 1.586d24
                  R = 606D
                end
    'ERIS'    : begin
                  M = 1.66d25
                  R = 1163D
                end
    'USERDEF' : begin
                  planet = strupcase(Name)
                end
    else      : begin
                  print, 'Unrecognized planet.'
                  planet = strupcase(planet)
                  M = 0D
                  R = 0D
                  print, 'Mass (g) ', format='(a,$)'
                  read, M, format='(f)'
                  print, 'Radius (km) ', format='(a,$)'
                  read, R, format='(f)'
                end
  endcase

  if not keyword_set(SHOCK) then begin
    sflg = 0
    mflg = 0
  endif

  twopi = 2D*!dpi
  GM = (6.673889d-8)*M
;           |
; Anderson, J.D., et al., EPL 110 (2015) 10002, doi:10.1209/0295-5075/110/10002

; Process the orbit parameter structure

  pflg = [0, 0, 0, 0, 0]

  str_element, param, 'period', period, success=ok
  if (ok) then pflg[0] = 1
  str_element, param, 'sma', sma, success=ok
  if (ok) then pflg[1] = 1
  str_element, param, 'ecc', ecc, success=ok
  if (ok) then pflg[2] = 1
  str_element, param, 'palt', palt, success=ok
  if (ok) then pflg[3] = 1
  str_element, param, 'aalt', aalt, success=ok
  if (ok) then pflg[4] = 1

; Determine the orbit size

  if (pflg[0]) then begin
    period = double(period)*3600D    ; orbital period (sec)
    k = twopi/period
    sma = (GM/(k*k))^(1D/3D)
    sma = sma/1.d5                   ; semi-major axis (km)
    goto, OSHAPE
  endif

  if (pflg[1]) then begin
    sma = double(sma)
    k = sqrt(GM/(sma*1.d5)^3D)
    period = twopi/k                 ; orbital period (sec)
    goto, OSHAPE
  endif

  if (pflg[2] eq 0) then begin
    if ((pflg[3] eq 0) or (pflg[4] eq 0)) then begin
      print, 'Insufficient orbit parameters.'
      return
    endif
    palt = double(palt)
    aalt = double(aalt)

    sma = R + (palt + aalt)/2D
    k = sqrt(GM/(sma*1.d5)^3D)
    period = twopi/k                 ; orbital period (sec)
    goto, OSHAPE
  endif

  if (pflg[3] eq 0) then begin
    if ((pflg[2] eq 0) or (pflg[4] eq 0)) then begin
      print, 'Insufficient orbit parameters.'
      return
    endif
    ecc = double(ecc)
    aalt = double(aalt)

    sma = (aalt + R)/(1D + ecc)
    k = sqrt(GM/(sma*1.d5)^3D)
    period = twopi/k                 ; orbital period (sec)
    goto, OSHAPE
  endif

  if (pflg[4] eq 0) then begin
    if ((pflg[2] eq 0) or (pflg[3] eq 0)) then begin
      print, 'Insufficient orbit parameters.'
      return
    endif
    ecc = double(ecc)
    palt = double(palt)

    sma = (palt + R)/(1D - ecc)
    k = sqrt(GM/(sma*1.d5)^3D)
    period = twopi/k                 ; orbital period (sec)
  endif

; Determine the orbit shape

OSHAPE:

  if (pflg[2]) then begin
    ecc = double(ecc)
    palt = sma*(1D - ecc) - R
    aalt = sma*(1D + ecc) - R
  endif else begin
    if (pflg[3]) then begin
      palt = double(palt)
      ecc = 1D - (palt + R)/sma
      aalt = sma*(1D + ecc) - R
    endif else begin
      if (pflg[4]) then begin
        aalt = double(aalt)
        ecc = (aalt + R)/sma - 1D
        palt = sma*(1D - ecc) - R
      endif else begin
        print, 'Insufficient orbit parameters.'
        return
      endelse
    endelse
  endelse

  sre = sqrt((1D + ecc)/(1D - ecc))

; Solve for the orbital position vs. time -- the method is described
; in Moulton, An Introduction to Celestial Mechanics, pp. 158-163.

  if not keyword_set(dt) then dt = period/1000D else dt = double(dt)

  npts = round(norbit*period/dt) + 1L
  t = dt*dindgen(npts)
  dist = dblarr(npts)
  thet = dist

  for i=0L,(npts-1L) do begin
    m = k*t[i] - !dpi

    eps1 = m + ecc*(sin(m) + ecc*sin(2D*m)/2D)
    eps = m + ecc*sin(eps1)
    x = eps - eps1

    n = 0
    while (x*x gt oerr) do begin
      eps1 = eps
      n = n + 1
      if (n gt nmax) then begin
        print, "Not converging!"
        print, "Percent complete: ", round(100D*double(i)/double(npts))
        print, "oerr = ", x*x
        return
      endif

      eps = m + ecc*sin(eps1)
      x = eps - eps1
    endwhile

    dist[i] = sma*(1D - ecc*cos(eps))
    thet[i] = 2D*atan(sre*tan(eps/2D))

  endfor

; Get orbital velocity from Vis-viva equation

  v = sqrt(GM*(2D/dist - 1D/sma)/1.d15)

  Vesc = sqrt(2D*GM/(1.d15*dist))

; Create a fly-through

  sc = replicate(0D,3,npts)
  sc[0,*] = dist*cos(thet)
  sc[1,*] = dist*sin(thet)

  for i=0L,(nlon-1L) do begin
    for j=0L,(nlat-1L) do begin

; Rotate about the Z axis to set the SS longitude of periapsis

    cphi = cos(lon[i,j])
    sphi = sin(lon[i,j])

    r1 = dblarr(3,3)

    r1[*,0] = [  cphi ,  sphi ,   0D  ]
    r1[*,1] = [ -sphi ,  cphi ,   0D  ]
    r1[*,2] = [   0D  ,   0D  ,   1D  ]

; Rotate about the Y axis to set the SS latitude of periapsis

    cphi = cos(lat[i,j])
    sphi = sin(lat[i,j])

    r2 = dblarr(3,3)

    r2[*,0] = [  cphi ,   0D  ,  sphi ]
    r2[*,1] = [   0D  ,   1D  ,   0D  ]
    r2[*,2] = [ -sphi ,   0D  ,  cphi ]

; Rotate about the X axis to set the orbital inclination

    cphi = cos(incl)/cos(lat[i,j])
    sphi = sqrt(1D - cphi*cphi)

    r3 = dblarr(3,3)

    r3[*,0] = [   1D  ,   0D  ,   0D  ]
    r3[*,1] = [   0D  ,  cphi ,  sphi ]
    r3[*,2] = [   0D  , -sphi ,  cphi ]

; Perform the three rotations

    ss = transpose(((r1 # r2) # r3) # sc)

; Output the fly-through to a text file

    if (size(flythru,/type) eq 7) then begin

      openw, lun, flythru, /get_lun

      for k=0L,(npts-1L) do $
        printf,lun,t[k],ss[k,0],ss[k,1],ss[k,2],v[k],$
               format='(4(f7.1,3x),f9.7)'

      free_lun,lun

    endif

; Orbit plots with three orthogonal views

    if (oflg) then begin
      phi = findgen(361)*!dtor
      xm = cos(phi)
      ym = sin(phi)

      rmin = min(dist, imin)
      imin = imin[0]
      rmax = ceil(aalt/R + 1D)

      case n_elements(xyrange) of
         0   : xrange = [-rmax, rmax]
         1   : xrange = [-xyrange, xyrange]
        else : xrange = minmax(xyrange)
      endcase
      yrange = xrange

      if (psflg) then begin
        popen,'morbit_oplot'
        if (xyflg) then !p.multi = 0 else !p.multi = [3,2,2]
      endif else begin
        if (blab) then wset, owin
        if (xyflg) then !p.multi = 0 else !p.multi = [3,1,3]
      endelse

      x = ss[*,0]/R
      y = ss[*,1]/R
      z = ss[*,2]/R
      s = sqrt(x*x + y*y)

      indx = where((s lt 0.) and (x lt 1.), count)
      if (count gt 0L) then oplot, x[indx], y[indx], color=4, psym=3
      swfrac[i,j] = float(npts - count)/float(npts)

; X-Y plane

      xo = x
      yo = y

      mndx = where((z lt 0.) and (s lt 1.), mcnt)
      if (mcnt gt 0L) then begin
        x[mndx] = !values.f_nan
        y[mndx] = !values.f_nan
      endif

      if (psflg) then begin
        plot,[xrange[0]],[yrange[0]],xrange=xrange,yrange=yrange,$
             /xsty,/ysty, xtitle='X (Rp)',ytitle='Y (Rp)',charsize=1.0, $
             ymargin=[8,9],title=planet
        oplot,xm,ym,color=6,thick=2
        if (doseg) then begin
          tstart = tseg
          tstop = shift(tseg,-1)
          tstop[nseg-1] = max(t)
          for k=0,(nseg-1) do begin
            sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
            if (count gt 0) then oplot,x[sndx],y[sndx],color=cseg[k],thick=sthick
          endfor
        endif else oplot,x,y
        if (dodot) then oplot,[x[imin]],[y[imin]],psym=4,color=4,thick=2
      endif else begin
        if (blab) then begin
          plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
               xtitle='X (Rp)',ytitle='Y (Rp)',charsize=2.0,title=planet
          oplot,xm,ym,color=6
          if (doseg) then begin
            tstart = tseg
            tstop = shift(tseg,-1)
            tstop[nseg-1] = max(t)
            for k=0,(nseg-1) do begin
              sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
              if (count gt 0) then oplot,x[sndx],y[sndx],color=cseg[k],thick=sthick
            endfor
          endif else oplot,x,y
          if (dodot) then oplot,[x[imin]],[y[imin]],psym=4,color=4,thick=2
        endif
      endelse

; Shock conic

      if (sflg) then begin

        phm = 160.*!dtor
        phi = (-150. + findgen(301))*!dtor
        rho = L/(1. + psi*cos(phi))

        xs = x0 + rho*cos(phi)
        ys = rho*sin(phi)
        if (blab) then oplot,xs,ys,color=scol,line=ssty

        s = sqrt(yo*yo + z*z)
        phi = atan(s,(xo - x0))
        rho = sqrt((xo - x0)^2. + s*s)
        indx = where(rho lt L/(1. + psi*cos(phi < phm)), count)
        if (count gt 0L and blab) then oplot, x[indx], y[indx], color=4, psym=3

        swfrac[i,j] = float(npts - count)/float(npts)

; Shadow

        s = sqrt(y*y + z*z)
        indx = where((s lt 1.) and (x lt 0.), count)
        if (count gt 0L and blab) then oplot, x[indx], y[indx], color=2, psym=3
        shfrac[i,j] = float(count)/float(npts)

      endif

; MPB conic

      if (mflg) then begin

        phi = (-160. + findgen(160))*!dtor

        rho = L_p1/(1. + psi_p1*cos(phi))
        x1 = x0_p1 + rho*cos(phi)
        y1 = rho*sin(phi)

        rho = L_p2/(1. + psi_p2*cos(phi))
        x2 = x0_p2 + rho*cos(phi)
        y2 = rho*sin(phi)

        indx = where(x1 ge 0)
        jndx = where(x2 lt 0)
        xpileup = [x2[jndx], x1[indx]]
        ypileup = [y2[jndx], y1[indx]]

        phi = findgen(161)*!dtor

        rho = L_p1/(1. + psi_p1*cos(phi))
        x1 = x0_p1 + rho*cos(phi)
        y1 = rho*sin(phi)

        rho = L_p2/(1. + psi_p2*cos(phi))
        x2 = x0_p2 + rho*cos(phi)
        y2 = rho*sin(phi)

        indx = where(x1 ge 0)
        jndx = where(x2 lt 0)
        xpileup = [xpileup, x1[indx], x2[jndx]]
        ypileup = [ypileup, y1[indx], y2[jndx]]

        if (blab) then oplot,xpileup,ypileup,color=scol,line=ssty
      endif

; X-Z plane

      if (~xyflg) then begin
        x = ss[*,0]/R
        y = ss[*,1]/R
        z = ss[*,2]/R
        s = sqrt(x*x + z*z)

        indx = where((y gt 0.) and (s lt 1.), count)
        if (count gt 0L) then begin
          x[indx] = !values.f_nan
          z[indx] = !values.f_nan
        endif

        if (psflg) then begin
          plot,[xrange[0]],[yrange[0]],xrange=xrange,yrange=yrange,$
               /xsty,/ysty,xtitle='X (Rp)',ytitle='Z (Rp)',charsize=1.0,$
               ymargin=[16,1]
          oplot,xm,ym,color=6, thick=2
          if (doseg) then begin
            tstart = tseg
            tstop = shift(tseg,-1)
            tstop[nseg-1] = max(t)
            for k=0,(nseg-1) do begin
              sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
              if (count gt 0) then oplot,x[sndx],z[sndx],color=cseg[k],thick=sthick
            endfor
          endif else oplot,x,z
          if (dodot) then oplot,[x[imin]],[z[imin]],psym=4,color=4,thick=2
        endif else begin
          if (blab) then begin
            plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
                 xtitle='X (Rp)',ytitle='Z (Rp)',charsize=2.0
            oplot,xm,ym,color=6
            if (doseg) then begin
              tstart = tseg
              tstop = shift(tseg,-1)
              tstop[nseg-1] = max(t)
              for k=0,(nseg-1) do begin
                sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
                if (count gt 0) then oplot,x[sndx],z[sndx],color=cseg[k],thick=sthick
              endfor
            endif else oplot,x,z
            if (dodot) then oplot,[x[imin]],[z[imin]],psym=4,color=4,thick=2
          endif
        endelse

; Shock conic

        if (sflg) then begin

          phm = 160.*!dtor 
          phi = (-150. + findgen(301))*!dtor
          rho = L/(1. + psi*cos(phi))

          xs = x0 + rho*cos(phi)
          zs = rho*sin(phi)
          if (blab) then oplot,xs,zs,color=scol,line=ssty

          s = sqrt(y*y + z*z)
          phi = atan(s,(x - x0))
          rho = sqrt((x - x0)^2. + s*s)
          indx = where(rho lt L/(1. + psi*cos(phi < phm)), count)
          if (count gt 0L and blab) then oplot, x[indx], z[indx], color=4, psym=3

; Shadow

          indx = where((s lt 1.) and (x lt 0.), count)
          if (count gt 0L and blab) then oplot, x[indx], z[indx], color=2, psym=3

        endif

; MPB conic

        if (mflg) then begin

          phi = (-160. + findgen(160))*!dtor

          rho = L_p1/(1. + psi_p1*cos(phi))
          x1 = x0_p1 + rho*cos(phi)
          y1 = rho*sin(phi)

          rho = L_p2/(1. + psi_p2*cos(phi))
          x2 = x0_p2 + rho*cos(phi)
          y2 = rho*sin(phi)

          indx = where(x1 ge 0)
          jndx = where(x2 lt 0)
          xpileup = [x2[jndx], x1[indx]]
          ypileup = [y2[jndx], y1[indx]]

          phi = findgen(161)*!dtor

          rho = L_p1/(1. + psi_p1*cos(phi))
          x1 = x0_p1 + rho*cos(phi)
          y1 = rho*sin(phi)

          rho = L_p2/(1. + psi_p2*cos(phi))
          x2 = x0_p2 + rho*cos(phi)
          y2 = rho*sin(phi)

          indx = where(x1 ge 0)
          jndx = where(x2 lt 0)
          xpileup = [xpileup, x1[indx], x2[jndx]]
          ypileup = [ypileup, y1[indx], y2[jndx]]

          if (blab) then oplot,xpileup,ypileup,color=scol,line=ssty

        endif

; Y-Z plane

        x = ss[*,0]/R
        y = ss[*,1]/R
        z = ss[*,2]/R
        s = sqrt(y*y + z*z)
        indx = where((x lt 0.) and (s lt 1.), count)
        if (count gt 0L) then begin
          y[indx] = !values.f_nan
          z[indx] = !values.f_nan
        endif

        if (psflg) then begin
          plot,[xrange[0]],[yrange[0]],xrange=xrange,yrange=yrange,$
               /xsty,/ysty,xtitle='Y (Rp)',ytitle='Z (Rp)',charsize=1.0, $
               ymargin=[16,1]
          oplot,xm,ym,color=6,thick=2
          if (doseg) then begin
            tstart = tseg
            tstop = shift(tseg,-1)
            tstop[nseg-1] = max(t)
            for k=0,(nseg-1) do begin
              sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
              if (count gt 0) then oplot,y[sndx],z[sndx],color=cseg[k],thick=sthick
            endfor
          endif else oplot,y,z
          if (dodot) then oplot,[y[imin]],[z[imin]],psym=4,color=4,thick=2
        endif else begin
          if (blab) then begin
            plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty, $
                 xtitle='Y (Rp)',ytitle='Z (Rp)',charsize=2.0
            oplot,xm,ym,color=6
            if (doseg) then begin
              tstart = tseg
              tstop = shift(tseg,-1)
              tstop[nseg-1] = max(t)
              for k=0,(nseg-1) do begin
                sndx = where((t ge tstart[k]) and (t lt tstop[k]), count)
                if (count gt 0) then oplot,y[sndx],z[sndx],color=cseg[k],thick=sthick
              endfor
            endif else oplot,y,z
            if (dodot) then oplot,[y[imin]],[z[imin]],psym=4,color=4,thick=2
          endif
        endelse

; Shock conic

        if (sflg) then begin

          phm = 160.*!dtor
          L0 = sqrt((L + psi*x0)^2. - x0*x0)
          oplot,L0*xm,L0*ym,color=scol,line=ssty

          s = sqrt(y*y + z*z)
          phi = atan(s,(x - x0))
          rho = sqrt((x - x0)^2. + s*s)
          indx = where(rho lt L/(1. + psi*cos(phi < phm)), count)
          if (count gt 0L and blab) then oplot, y[indx], z[indx], color=4, psym=3

; Shadow

          indx = where((s lt 1.) and (x lt 0.), count)
          if (count gt 0L and blab) then oplot, x[indx], z[indx], color=2, psym=3

        endif

; MPB conic

        if (mflg) then begin

          L0 = sqrt((L_p1 + psi_p1*x0_p1)^2. - x0_p1*x0_p1)
          if (blab) then oplot,L0*xm,L0*ym,color=scol,line=1
          
        endif

      endif

      if (psflg) then pclose

      !p.multi = 0

    endif

; Time series plot

    if (tflg) then begin
      store_data,'alt',data={x:t, y:(dist-R)}
      ylim,'alt',0,0,0
      options,'alt','ynozero',1
      options,'alt','ytitle','Altitude (km)'
      if (aalt/palt gt 10D) then ylim,'alt',0,0,1

      store_data,'vel',data={x:t, y:v}
      options,'vel','ynozero',1
      options,'vel','ytitle','Velocity (km/s)'
      
      store_data,'Vesc',data={x:t, y:Vesc}
      options,'Vesc','color',6
      options,'Vesc','linestyle',2
      
      store_data,'Velocity',data=['vel','Vesc']

      tplot_options,'charsize',1.2
      tplot_options,'title',planet

      wset, twin
      timespan,[min(t),max(t)],/sec
      if (blab) then tplot,['alt','Velocity']

      tplot_options,'title',''
      tplot_options,'charsize',1.0
    endif
  
    endfor
  endfor

; Package the result

  wset, wsave

  period = period/3600D
  lon = lon/dtor
  lat = lat/dtor
  incl = incl/dtor

  result = {t      : t         , $       ; time from apoapsis (sec)
            dist   : dist      , $       ; radial distance (km)
            thet   : thet      , $       ; true anomaly (radians)
            x      : ss        , $       ; cartesian coord. (km)
            alt    : dist - R  , $       ; altitude (km)
            vel    : v         , $       ; orbital velocity (km/s)
            period : period    , $       ; orbital period (hours)
            sma    : sma       , $       ; semi-major axis (km)
            palt   : palt      , $       ; periapsis altitude (km)
            plon   : lon       , $       ; periapsis longitude (deg)
            plat   : lat       , $       ; periapsis latitude (deg)
            aalt   : aalt      , $       ; apoapsis altitude (km)
            ecc    : ecc       , $       ; orbital eccentricity
            incl   : incl      , $       ; orbital inclination (deg)
            swfrac : swfrac    , $       ; fraction of time in solar wind
            shfrac : shfrac    , $       ; fraction of time in shadow
            planet : planet    , $       ; planet name
            radius : R         , $       ; planet radius (km)
            Vesc   : Vesc         }      ; escape velocity (km/s)

; Output the orbit parameters

  if not keyword_set(silent) then begin
    print,''
    print,'Planet : ',result.planet
    print,'  orbital period (hr)     : ',result.period,format='(a,f9.4)'
    print,'  semi-major axis (km)    : ',result.sma,format='(a,f9.1)'
    print,'  periapsis altitude (km) : ',result.palt,format='(a,f9.1)'
    print,'  apoapsis altitude (km)  : ',result.aalt,format='(a,f9.1)'
    print,'  eccentricity            : ',result.ecc,format='(a,f9.4)'
    print,''
  endif

  return

end

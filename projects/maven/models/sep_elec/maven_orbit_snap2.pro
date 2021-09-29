;+
;PROCEDURE:   maven_orbit_snap
;PURPOSE:
;  After running maven_orbit_tplot, this routine plots the orbit as viewed
;  along each of the MSO axes.  Optionally, the orbit can be superimposed on
;  models of the solar wind interaction with Mars.  Also optionally, the 
;  position of the spacecraft can be plotted (in GEO coordinates) on a map
;  of Mars' topography and magnetic field based on MGS MOLA and MAG data.
;
;  All plots are generated at times selected with the cursor on the TPLOT
;  window.  Hold down the left mouse button and drag for a movie effect.
;
;USAGE:
;  maven_orbit_snap
;INPUTS:
;
;KEYWORDS:
;       PREC:     Plot the position of the spacecraft at the selected time,
;                 superimposed on the orbit.  Otherwise, the periapsis 
;                 location for each orbit is plotted.  For time ranges less
;                 than one day, the default is PREC = 1.  Otherwise the 
;                 default is 0.
;
;       MHD:      Plot the orbit superimposed on an image of an MHD simulation
;                 of the solar wind interaction with Mars (from Ma).
;                   1 : Plot the XY projection
;                   2 : Plot the XZ projection
;
;       HYBRID:   Plot the orbit superimposed on an image of a hybrid simulation
;                 of the solar wind interaction with Mars (from Brecht).
;                   1 : Plot the XZ projection
;                   2 : Invert Z in the model, then plot the XZ projection
;
;       LATLON:   Plot MSO longitudes and latitudes of periapsis (PREC=0) or 
;                 the spacecraft (PREC=1) in a separate window.
;
;       CYL:      Plot MSO cylindrical projection (x vs. sqrt(y^2 + z^2)).
;
;       XZ:       Plot only the XZ projection.
;
;       MARS:     Plot the position of the spacecraft (PREC=1) or periapsis 
;                 (PREC=0) on an image of Mars topography and magnetic field
;                 based on MGS data (from Connerney).
;                   1 : Use a small image
;                   2 : Use a large image
;
;       NPOLE:    Plot the position of the spacecraft (PREC=1) or periapsios
;                 (PREC=0) on a north polar projection (lat > 55 deg).  The
;                 background image is the north polar magnetic anomalies observed
;                 at 180-km altitude by MGS (from Acuna).
;
;       ALT:      If set and keywords MARS and/or NPOLE are set, then indicate the
;                 spacecraft altitude next its symbol.
;
;       TERMINATOR: Overplot the terminator and sub-solar point onto the Mars
;                   topography plots (see MARS and NPOLE above).  SPICE must be 
;                   installed and initialized (e.g., mvn_swe_spice_init) before 
;                   using this keyword.  The following values are recognized:
;                      0 : Do not plot any shadow boundary.  (default)
;                      1 : Plot optical shadow boundary at surface.
;                      2 : Plot optical shadow boundary at s/c altitude.
;                      3 : Plot EUV shadow boundary at s/c altitude.
;
;       NOERASE:  Don't erase previously plotted positions.  Can be used to build
;                 up a visual representation of sampling.
;
;       NODOT:    Do not plot a filled circle at periapsis or spacecraft location.
;
;       RESET:    Initialize all plots.
;
;       COLOR:    Symbol color index.
;
;       KEEP:     Do not kill the plot windows on exit.
;
;       TIMES:    An array of times for snapshots.  Snapshots are overlain onto
;                 a single version of the plot.  For evenly spaced times, this
;                 produces a "spirograph" effect.  This overrides the interactive
;                 entry of times with the cursor.  Sets KEEP, NOERASE, and RESET.
;
;       BDIR:     Set keyword to show magnetic field direction in three planes,
;                 In each plane, the same two components of B in MSO coordinates 
;                 are shown, i.e. in XY plane, plotting Bx-By. The color shows 
;                 if the third component (would be Bz in XY plane) is positive 
;                 (red) or negative (blue).
;
;       BCLIP:    Maximum amplitude for plotting B whisker.
;
;       SCALE:    To change the scale/length of field lines, the default value is
;                 set to 0.05
;
;       THICK:    Line thickness.
;
;       MAGNIFY:  Change size of plot windows.
;
;       PSNAME:   Name of a postscript plot.  Works only for orbit plots.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2017-10-02 17:58:29 -0700 (Mon, 02 Oct 2017) $
; $LastChangedRevision: 24100 $
; $URL: file:///disks/socware/thmsvn/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_snap.pro $
;
;CREATED BY:	David L. Mitchell  10-28-11
;-
pro maven_orbit_snap2, prec=prec, mhd=mhd, hybrid=hybrid, latlon=latlon, xz=xz, mars=mars, $
    npole=npole, noerase=noerase, keep=keep, color=color, reset=reset, cyl=cyl, times=times, $
    nodot=nodot, terminator=terminator, thick=thick, Bdir=Bdir, scale=scale, scsym=scsym, $
    magnify=magnify, Bclip=Bclip, alt=doalt, psname=psname, bcomp=bcomp, bmap=bmap, sep=sep

  @maven_orbit_common
  @swe_snap_common
  
  if keyword_set(bcomp) then get_data,'mvn_B_comp_(nT)',dat=bcomp

  if (size(time,/type) ne 5) then begin
    print, "You must run maven_orbit_tplot first!"
    return
  endif
  
  if (size(snap_index,/type) eq 0) then swe_snap_layout, 0

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill
  if (size(thick,/type) eq 0) then thick = 1
  
  if not keyword_set(scsym) then scsym = 1

  tplot_options, get_opt=topt
  delta_t = abs(topt.trange[1] - topt.trange[0])
  if ((size(prec,/type) eq 0) and (delta_t lt (7D*86400D))) then prec = 1

  if keyword_set(prec) then pflg = 1 else pflg = 0
  if (size(color,/type) gt 0) then cflg = 1 else cflg = 0  
  if keyword_set(noerase) then noerase = 1 else noerase = 0
  if keyword_set(reset) then reset = 1 else reset = 0
  if keyword_set(nodot) then dodot = 0 else dodot = 1
  if (size(terminator,/type) gt 0) then doterm = fix(round(terminator)) < 3 else doterm = 0
  if not keyword_set(magnify) then mag = 1. else mag = float(magnify)
  csize = 2.0*mag
  if (size(Bclip,/type) eq 0) then Bclip = 1.e9

  if keyword_set(Bdir) then dob = 1 else dob = 0
  doalt = keyword_set(doalt)

  if keyword_set(times) then begin
    times = time_double(times)
    ntimes = n_elements(times)
    reset = 1
    noerase = 1
    keep = 1
    tflg = 1
  endif else begin
    ntimes = 1L
    tflg = 0
  endelse
  
  if keyword_set(xz) then xzflg = 1 else xzflg = 0

  if keyword_set(mhd) then begin
    if (mhd gt 1) then begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xz
      nflg = 2
    endif else begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xy
      nflg = 1
    endelse
  endif else nflg = 0

  if keyword_set(hybrid) then begin
    if (hybrid eq 1) then begin
      if (~noerase or reset) then hybrid_orbit_new, [-10.], [-10.], /reset, /xz
      bflg = 1
    endif else begin
      if (~noerase or reset) then hybrid_orbit_new, [-10.], [-10.], /reset, /xz, /flip
      bflg = 2
    endelse
  endif else bflg = 0

  if keyword_set(npole) then begin
    if (~noerase or reset) then mag_npole_orbit, [0.], [0.], /reset
    npflg = 1
  endif else npflg = 0

  if keyword_set(latlon) then gflg = 1 else gflg = 0
  
  if keyword_set(mars) then begin
    mflg = mars
    if (mflg gt 1) then mbig = 1 else mbig = 0
  endif else mflg = 0
  
  if keyword_set(orbit) then oflg = 1 else oflg = 0
  
  if keyword_set(cyl) then cyflg = 1 else cyflg = 0

  Twin = !d.window

; Mars shock parameters

  R_m = 3389.9D
  x0  = 0.600
  psi = 1.026
  L   = 2.081

; Mars MPB parameters

  x0_p1  = 0.640
  psi_p1 = 0.770
  L_p1   = 1.080

  x0_p2  = 1.600
  psi_p2 = 1.009
  L_p2   = 0.528

; Create snapshot windows

  if (size(psname,/type) eq 7) then begin
    psflg = 1
  endif else begin
    psflg = 0
    if (xzflg) then begin
      window,26,xsize=round(600.*mag),ysize=round(538.*mag)
      Owin = !d.window
    endif else begin
      device, get_screen_size=scr
      oscale = 0.965*(scr[1]/943.) < 1.06

      xsize = round(350.*oscale*mag)
      ysize = round(943.*oscale*mag)
      xpos = 0
      ypos = 0

      if (snap_index gt 0) then begin
        xsize = round(Oopt.xsize*mag)
        ysize = round(Oopt.ysize*mag)
        xpos = Oopt.xpos
        ypos = Oopt.ypos
      endif

      window,26,xsize=xsize,ysize=ysize,xpos=xpos,ypos=ypos
      Owin = !d.window
    endelse
  endelse

  if (gflg) then begin
    window,/free,xsize=round(600.*mag),ysize=round(280.*mag)
    Gwin = !d.window
  endif

  if (cyflg) then begin
    if (snap_index gt 0) then begin
      xsize = round(OCopt.xsize*mag)
      ysize = round(OCopt.ysize*mag)
      xpos = OCopt.xpos
      ypos = OCopt.ypos
    endif else begin
      xsize = round(600.*mag)
      ysize = round(350.*mag)
      xpos = 0
      ypos = 0
    endelse
    window,/free,xsize=xsize,ysize=ysize,xpos=xpos,ypos=ypos
    Cwin = !d.window
  endif

  if (mflg gt 0) then begin
    if (~noerase or reset) then mag_mola_orbit2, -100., -100., big=mbig, /reset, bmap=bmap
  endif

; Get the orbit closest the selected time

  print,'Use button 1 to select time; button 3 to quit.'

  if (tflg) then begin
    k = 0L
    if (k ge ntimes) then begin
      wdelete,Owin
      if (gflg) then wdelete, Gwin
      if (cyflg) then wdelete, Cwin
      if (npflg gt 0) then wdelete, 27
      if (mflg gt 0)  then wdelete, 29
      if (nflg gt 0)  then wdelete, 30
      if (bflg gt 0)  then wdelete, 31
      wset,Twin
      return
    endif
    trange = times[k]
  endif else begin
    wset,Twin
    ctime2,trange,npoints=1,/silent,button=button
    if (size(trange,/type) eq 2) then begin
      wdelete,Owin
      if (gflg) then wdelete, Gwin
      if (cyflg) then wdelete, Cwin
      if (npflg gt 0) then wdelete, 27
      if (mflg gt 0)  then wdelete, 29
      if (nflg gt 0)  then wdelete, 30
      if (bflg gt 0)  then wdelete, 31
      wset,Twin
      return
    endif
  endelse

  tref = trange[0]
  dt = min(abs(time - tref), iref, /nan)
  tref = time[iref]
  oref = orbnum[iref]
  ndays = (tref - time[0])/86400D

  dt = min(abs(torb - tref), jref, /nan)
  dj = round(double(period[jref])*3600D/(time[1] - time[0]))
  
  ok = 1
  first = 1
  
  if (psflg) then popen, psname

  while (ok) do begin
    title = string(time_string(tref),oref,format='(a19,2x,"(Orbit ",i4,")")')
    if (noerase) then title = ''

    if (~psflg) then begin
      wset, Owin
      if (first) then erase
    endif

    npts = n_elements(ss[*,0])

    imid = dj/2L
    rndx = iref + lindgen(dj+1L) - imid

    imin = min(rndx)
    if (imin lt 0L) then rndx = rndx - imin

    imax = max(rndx)
    if (imax gt (npts-1L)) then rndx = rndx - (imax-npts-1L)

    xo = ss[rndx,0]
    yo = ss[rndx,1]
    zo = ss[rndx,2]
    ro = ss[rndx,3]

    xs = sheath[rndx,0]
    ys = sheath[rndx,1]
    zs = sheath[rndx,2]

    xp = pileup[rndx,0]
    yp = pileup[rndx,1]
    zp = pileup[rndx,2]

    xw = wake[rndx,0]
    yw = wake[rndx,1]
    zw = wake[rndx,2]

; Orbit plots with three orthogonal views

    rmin = min(ro, imin)
    imin = imin[0]
    rmax = ceil(max(ro) + 1D)

    if (first) then begin
      phi = findgen(361)*!dtor
      xm = cos(phi)
      ym = sin(phi)

      xrange = [-rmax,rmax]
      yrange = xrange
    endif
    
    if (dob eq 1) then begin
        get_data,'mvn_B_1sec_maven_mso',data=bmso
        bb0=bmso.y
        bt=bmso.x
        bdt=60 ;smooth over seconds
        for i=0,2 do bb0[*,i]=smooth(bb0[*,i],bdt)

        bmag = sqrt(total(bb0*bb0,2,/nan))
        indx = where(bmag gt Bclip, count)
        if (count gt 0L) then bb0[indx,*] = !values.f_nan

        bb=fltarr(n_elements(rndx),3)
        bb[*,0]=interpol(bb0[*,0],bt,time[rndx])
        bb[*,1]=interpol(bb0[*,1],bt,time[rndx])
        bb[*,2]=interpol(bb0[*,2],bt,time[rndx])
        if ~(keyword_set(scale)) then scale=0.05
        nskp=5
    endif

; X-Y Projection

    if (xzflg eq 0) then begin
      !p.multi = [3,1,3]

      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + y*y)

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      mlon = atan(yo[i],xo[i])
      mlat = asin(zo[i]/ro[i])
      alt = (ro[i] - 1D)*R_m
      szaref = acos(cos(mlon)*cos(mlat))

      plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty,/noerase, $
           xtitle='X (Rp)',ytitle='Y (Rp)',charsize=csize,title=title,thick=thick
      oplot,xm,ym,color=6,thick=thick
      oplot,x,y,thick=thick

      if (dodot) then oplot,[x[i]],[y[i]],psym=8,color=5

      if (dob) then begin
        cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=x[i]
              y1=y[i]
              x2=scale*bb[i,0]+x1
              y2=scale*bb[i,1]+y1
              if bb[i,2] le 0 then clr=64 $
              else clr=254
              oplot,[x1,x2],[y1,y2],color=clr
          endfor
      endif
      

      x = xs
      y = ys
      z = zs

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=rcols[0],thick=thick

      x = xp
      y = yp
      z = zp

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=rcols[1],thick=thick

      x = xw
      y = yw
      z = zw

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,x,y,color=rcols[2],thick=thick

; Shock conic

      phi = (-150. + findgen(301))*!dtor
      rho = L/(1. + psi*cos(phi))

      xshock = x0 + rho*cos(phi)
      yshock = rho*sin(phi)
      oplot,xshock,yshock,color=3,line=1,thick=thick

; MPB conic

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

      oplot,xpileup,ypileup,color=3,line=1,thick=thick

    endif

; X-Z Projection

    if (xzflg) then !p.multi = [1,1,1] else !p.multi = [2,1,3]

    x = xo
    y = yo
    z = zo
    s = sqrt(x*x + z*z)

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif

    if (xzflg) then msg = title else msg = ''

    plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty,/noerase, $
         xtitle='X (Rp)',ytitle='Z (Rp)',charsize=csize,title=msg,thick=thick
    oplot,xm,ym,color=6,thick=thick
    oplot,x,z,thick=thick

    if (pflg) then i = imid else i = imin
    if (dodot) then oplot,[x[i]],[z[i]],psym=8,color=5,thick=thick

    if (dob) then begin
        cts = n_elements(rndx)
        for i=0,cts-1,nskp do begin
            x1=x[i]
            y1=z[i]
            x2=scale*bb[i,0]+x1
            y2=scale*bb[i,2]+y1
            if bb[i,1] le 0 then clr=64 $
            else clr=254
            oplot,[x1,x2],[y1,y2],color=clr
        endfor
    endif

    x = xs
    y = ys
    z = zs

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif
    oplot,x,z,color=rcols[0],thick=thick

    x = xp
    y = yp
    z = zp

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      y[indx] = !values.f_nan
    endif
    oplot,x,z,color=rcols[1],thick=thick

    x = xw
    y = yw
    z = zw

    indx = where((y gt 0.) and (s lt 1.), count)
    if (count gt 0L) then begin
      x[indx] = !values.f_nan
      z[indx] = !values.f_nan
    endif
    oplot,x,z,color=rcols[2],thick=thick

; Shock conic

    phi = (-150. + findgen(301))*!dtor
    rho = L/(1. + psi*cos(phi))

    xshock = x0 + rho*cos(phi)
    zshock = rho*sin(phi)
    oplot,xshock,zshock,color=3,line=1,thick=thick

; MPB conic

    phi = (-160. + findgen(160))*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [x2[jndx], x1[indx]]
    zpileup = [z2[jndx], z1[indx]]

    phi = findgen(161)*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [xpileup, x1[indx], x2[jndx]]
    zpileup = [zpileup, z1[indx], z2[jndx]]

    oplot,xpileup,zpileup,color=3,line=1,thick=thick

; Y-Z Projection

    if (xzflg eq 0) then begin
      !p.multi = [1,1,3]

      x = xo
      y = yo
      z = zo
      s = sqrt(y*y + z*z)

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty,/noerase, $
           xtitle='Y (Rp)',ytitle='Z (Rp)',charsize=csize,thick=thick
      oplot,xm,ym,color=6,thick=thick
      oplot,y,z,thick=thick

      if (pflg) then i = imid else i = imin
      if (dodot) then oplot,[y[i]],[z[i]],psym=8,color=5,thick=thick

      if (dob) then begin
          cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=y[i]
              y1=z[i]
              x2=scale*bb[i,1]+x1
              y2=scale*bb[i,2]+y1
              if bb[i,0] le 0 then clr=64 $
              else clr=254
              oplot,[x1,x2],[y1,y2],color=clr
          endfor
      endif

      x = xs
      y = ys
      z = zs

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      oplot,y,z,color=rcols[0],thick=thick

      x = xp
      y = yp
      z = zp

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      oplot,y,z,color=rcols[1],thick=thick

      x = xw
      y = yw
      z = zw

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      oplot,y,z,color=rcols[2],thick=thick

      L0 = sqrt((L + psi*x0)^2. - x0*x0)
      oplot,L0*xm,L0*ym,color=3,line=1,thick=thick

      L0 = sqrt((L_p1 + psi_p1*x0_p1)^2. - x0_p1*x0_p1)
      oplot,L0*xm,L0*ym,color=3,line=1,thick=thick

    endif

    !p.multi = 0

; Put up cylindrical projection

   if (cyflg) then begin
     wset, Cwin
     if (first) then erase

     x = xo
     y = yo
     z = zo
     s = sqrt(y*y + z*z)

     plot,xm,ym,xrange=xrange,yrange=[0,yrange[1]],/xsty,/ysty,/noerase, $
          xtitle='X (Rp)',ytitle='S (Rp)',charsize=csize,title=title,thick=thick
     oplot,xm,ym,color=6,thick=thick
     oplot,x,s,thick=thick

    if (pflg) then i = imid else i = imin
    if (dodot) then oplot,[x[i]],[s[i]],psym=8,color=5,thick=thick

    oplot,xs,sqrt(ys*ys + zs*zs),color=rcols[0],thick=thick
    oplot,xp,sqrt(yp*yp + zp*zp),color=rcols[1],thick=thick
    oplot,xw,sqrt(yw*yw + zw*zw),color=rcols[2],thick=thick

; Shock conic

    phi = (-150. + findgen(301))*!dtor
    rho = L/(1. + psi*cos(phi))

    xshock = x0 + rho*cos(phi)
    zshock = rho*sin(phi)
    oplot,xshock,zshock,color=3,line=1,thick=thick

; MPB conic

    phi = (-160. + findgen(160))*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [x2[jndx], x1[indx]]
    zpileup = [z2[jndx], z1[indx]]

    phi = findgen(161)*!dtor

    rho = L_p1/(1. + psi_p1*cos(phi))
    x1 = x0_p1 + rho*cos(phi)
    z1 = rho*sin(phi)

    rho = L_p2/(1. + psi_p2*cos(phi))
    x2 = x0_p2 + rho*cos(phi)
    z2 = rho*sin(phi)

    indx = where(x1 ge 0)
    jndx = where(x2 lt 0)
    xpileup = [xpileup, x1[indx], x2[jndx]]
    zpileup = [zpileup, z1[indx], z2[jndx]]

    oplot,xpileup,zpileup,color=3,line=1,thick=thick

   endif

; Put up the ground track

    if (gflg) then begin
      wset, Gwin
      if (first) then erase
      mlon = mlon*!radeg
      mlat = mlat*!radeg
      szaref = szaref*!radeg

      title = string(mlon,mlat,alt,szaref,$
                format='("Lon = ",f6.1,2x,"Lat = ",f5.1,2x,"Alt = ",f5.0,2x,"SZA = ",f5.1)')

      plot,[mlon],[mlat],xrange=[-180,180],/xsty,yrange=[-90,90],/ysty,$
           xticks=12,xminor=3,yticks=6,yminor=4,title=title,/noerase,$
           xtitle='MSO Longitude',ytitle='MSO Latitude',psym=3
      oplot,[-90,-90],[-90,90],color=4,line=1
      oplot,[90,90],[-90,90],color=4,line=1
      oplot,[0],[0],psym=8,color=5,symsize=2.0
      oplot,[mlon],[mlat],psym=8,color=6,symsize=2.0
    endif

; Put up the MHD simulation plot

    if (nflg eq 1) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + y*y)

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 0

      mhd_orbit, x, y, x[i], y[i], color=j, psym=0, /xy
    endif

    if (nflg eq 2) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + z*z)

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 0

      mhd_orbit, x, z, x[i], z[i], color=j, psym=0, /xz
    endif

; Put up the hybrid simulation plot

    if (bflg gt 0) then begin
      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + z*z)

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      if (pflg) then i = imid else i = imin
      if (cflg) then j = color else j = 255

      if (bflg eq 1) then hybrid_orbit_new, x, z, x[i], z[i], color=j, psym=0, /xz $
                     else hybrid_orbit_new, x, z, x[i], z[i], color=j, psym=0, /xz, /flip
    endif

; Put up Mars orbit

    if (mflg gt 0) then begin
      if (pflg) then i = iref else i = rndx[imin]
      title = ''
      if (cflg) then j = color else j = 2
      if (doterm gt 0) then ttime = trange[0] else ttime = 0
      if (doalt) then sc_alt = hgt[i] else sc_alt = 0
      mag_mola_orbit2, lon[i], lat[i], big=mbig, noerase=noerase, title=title, color=j, $
                      terminator=ttime, psym=scsym, shadow=(doterm - 1), alt=sc_alt, bcomp=bcomp2
    endif

; Put up Mars North polar plot

    if (npflg) then begin
      if (pflg) then i = iref else i = rndx[imin]
      title = ''
      if (cflg) then j = color else j = 2
      if (doterm) then ttime = trange[0] else ttime = 0
      if (doalt) then sc_alt = hgt[i] else sc_alt = 0
      mag_Npole_orbit, lon[i], lat[i], noerase=noerase, title=title, color=j, $
                       terminator=ttime, alt=sc_alt
    endif

; Get the next button press

    if (psflg) then pclose

    if (tflg) then begin
      k++
      if (k lt ntimes) then begin
        trange = times[k]
        first = 0
      endif else ok = 0
    endif else begin
      wset,Twin
      ctime2,trange,npoints=1,/silent,button=button
      if (size(trange,/type) ne 5) then ok = 0
    endelse

    if (ok) then begin
      dt = min(abs(time - trange[0]), iref)
      tref = time[iref]
      oref = orbnum[iref]
      ndays = (tref - time[0])/86400D
      
      if keyword_set(bcomp) then begin
        bcompdt = min(abs(bcomp.x - trange[0]), biref)
        bcomp2=reform(bcomp.y[biref,*])
      endif
    endif

  endwhile

  if not keyword_set(keep) then begin
    wdelete, Owin
    if (gflg) then wdelete, Gwin
    if (cyflg) then wdelete, Cwin
    if (npflg gt 0) then wdelete, 27
    if (mflg gt 0)  then wdelete, 29
    if (nflg gt 0)  then wdelete, 30
    if (bflg gt 0)  then wdelete, 31
  endif

  !p.multi = 0

  return

end

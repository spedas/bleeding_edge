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
;                 than seven days, the default is PREC = 1.  Otherwise the 
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
;       XZ:       Plot only the XZ projection (view from side).
;
;       XY:       Plot only the XY projection (view from ecliptic north).
;
;       YZ:       Plot only the YZ projection (view from Sun)
;
;       MARS:     Plot the position of the spacecraft (PREC=1) or periapsis 
;                 (PREC=0) on an image of Mars topography (colors from MOLA)
;                 and radial magnetic field (contours from Connerney et al. 
;                 2001).  Alternatively, use an image of dBr/dt that better
;                 filters out solar wind influences (Connerney et al. 2004),
;                 on top of a greyscale topo map with elevation contours.
;                   1 : Use a small MAG-MOLA image
;                   2 : Use a large MAG-MOLA image
;                   3 : Use a large dBr-topology image
;
;       NPOLE:    Plot the position of the spacecraft (PREC=1) or periapsis
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
;                      4 : Plot EUV shadow at electron absorption altitude.
;
;       NOERASE:  Don't erase previously plotted positions.  Can be used to build
;                 up a visual representation of sampling.
;
;       NODOT:    Do not plot a filled circle at periapsis or spacecraft location.
;
;       NOORB:    Do not plot the orbit.
;
;       SCSYM:    Symbol for the spacecraft.  Default = 1 (plus symbol).
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
;       TCOLORS:  Color index for every element of TIMES.
;
;       BDIR:     Set keyword to show magnetic field direction in three planes,
;                 In each plane, the same two components of B in MSO coordinates 
;                 are shown, i.e. in XY plane, plotting Bx-By. The color shows 
;                 if the third component (would be Bz in XY plane) is positive 
;                 (red) or negative (blue).
;
;       BCLIP:    Maximum amplitude for plotting B whisker.
;
;       MSCALE:   To change the scale/length of magnetic field lines, the default
;                 value is set to 0.05
;
;       VDIR:     Set keyword to a tplot variable containing MSO vectors for a whisker
;                 plot (like BDIR).
;
;       VCLIP:    Maximum amplitude for plotting V whisker.
;
;       VRANGE:   Time range for plotting vectors.
;
;       VSCALE:   To change the scale/length of vector lines, the default value is
;                 set to 0.05.
;
;       THICK:    Line thickness.
;
;       WSCALE:   Scale factor for sizing plot windows.  Default = 1.
;                 Has no effect when plotting orbit projections over images, which
;                 have fixed sizes.
;
;       MAGNIFY:  Synonym for WSCALE.  (WSCALE takes precedence.)
;
;       NOLABEL:  Omit text labels showing altitude and solar zenith angle.
;
;       PSNAME:   Name of a postscript plot.  Works only for orbit plots.
;
;       LANDERS:  Plot the locations of landers.  Can also be an 2 x N array
;                 of surface locations (lon, lat) in the IAU_Mars frame.
;
;       SLAB:     Text labels for each of the landers.  If LANDERS is a scalar,
;                 then this provides a 1- or 2-character label for each lander.
;                 If LANDERS is a 2 x N array, SLAB should be an N-element string
;                 array.  Set SLAB to zero to disable text labels and just plot
;                 symbols instead.  Text labels are centered in longitude with
;                 the baseline at latitude.
;
;       SCOL:     Color(s) for the lander labels or symbols.  If there are more
;                 landers than colors, then additional landers are all given the
;                 last color.  Default is 6 (red) for all.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-04-20 11:40:58 -0700 (Tue, 20 Apr 2021) $
; $LastChangedRevision: 29893 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_snap.pro $
;
;CREATED BY:	David L. Mitchell  10-28-11
;-
pro maven_orbit_snap, prec=prec, mhd=mhd, hybrid=hybrid, latlon=latlon, xz=xz, mars=mars, $
    npole=npole, noerase=noerase, keep=keep, color=color, reset=reset, cyl=cyl, times=times, $
    nodot=nodot, terminator=terminator, thick=thick, Bdir=Bdir, mscale=mscale, scsym=scsym, $
    magnify=magnify, Bclip=Bclip, Vdir=Vdir, Vclip=Vclip, Vscale=Vscale, Vrange=Vrange, $
    alt=alt2, psname=psname, nolabel=nolabel, xy=xy, yz=yz, landers=landers, slab=slab, $
    scol=scol, tcolors=tcolors, noorb=noorb, monitor=monitor, wscale=wscale

  @maven_orbit_common
  @putwin_common

  if (size(time,/type) ne 5) then begin
    print, "You must run maven_orbit_tplot first!"
    return
  endif

  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill
  if (size(thick,/type) eq 0) then thick = 1

  tplot_options, get_opt=topt
  delta_t = abs(topt.trange[1] - topt.trange[0])
  if ((size(prec,/type) eq 0) and (delta_t lt (7D*86400D))) then prec = 1

; Load any keyword defaults

  maven_orbit_options, get=key, /silent
  ktag = tag_names(key)
  tlist = ['PREC','MHD','HYBRID','LATLON','XZ','MARS','NPOLE','NOERASE','KEEP', $
           'COLOR','RESET','CYL','TIMES','NODOT','TERMINATOR','THICK','BDIR', $
           'MSCALE','SCSYM','MAGNIFY','BCLIP','VDIR','VCLIP','VSCALE','VRANGE', $
           'ALT2','PSNAME','NOLABEL','XY','YZ','LANDERS','SLAB','SCOL','TCOLORS', $
           'NOORB','MONITOR','WSCALE']
  for j=0,(n_elements(ktag)-1) do begin
    i = strmatch(tlist, ktag[j]+'*', /fold)
    case (total(i)) of
        0  : ; keyword not recognized -> do nothing
        1  : begin
               kname = (tlist[where(i eq 1)])[0]
               ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
               if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
             end
      else : print, "Keyword ambiguous: ", ktag[j]
    endcase
  endfor

; Process keywords

  if not keyword_set(scsym) then scsym = 1
  if keyword_set(prec) then pflg = 1 else pflg = 0
  if (size(color,/type) gt 0) then begin
    color = color[0]
    cflg = 1
  endif else begin
    color = 5
    cflg = 0
  endelse
  if keyword_set(noerase) then noerase = 1 else noerase = 0
  if keyword_set(reset) then reset = 1 else reset = 0
  if keyword_set(nodot) then dodot = 0 else dodot = 1
  if keyword_set(noorb) then doorb = 0 else doorb = 1
  if (size(terminator,/type) gt 0) then doterm = fix(round(terminator)) < 3 else doterm = 0
  if keyword_set(wscale) then begin
    wscale = float(wscale[0])
  endif else begin
    wscale = 1.
    if keyword_set(magnify) then wscale = float(magnify[0])
  endelse
  csize = 2.0*wscale
  if (size(Bclip,/type) eq 0) then Bclip = 1.e9
  if (size(Vclip,/type) eq 0) then Vclip = 1.e3

  if keyword_set(Bdir) then dob = 1 else dob = 0
  if keyword_set(Vdir) then dov = 1 else dov = 0

  doalt = keyword_set(alt2)
  dolab = ~keyword_set(nolabel)

  ok = 0
  sites = 0
  nsites = 0
  sz = size(landers)
  if (((sz[0] eq 1) or (sz[0] eq 2)) and (sz[1] eq 2)) then begin
    sites = landers
    nsites = n_elements(landers)/2
    if (size(slab,/type) eq 7) then begin
      nlab = n_elements(slab)
      if (nlab ne nsites) then begin
        slab2 = replicate('',nsites)
        slab2[0:(nlab-1)<(nsites-1)] = slab[0:(nlab-1)<(nsites-1)]
        slab = slab2
      endif
    endif else slab = 0
    ok = 1
  endif
  if ((not ok) and keyword_set(landers)) then begin
    nsites = 9
    sites = fltarr(2,nsites)
    sites[*,0] = [311.778,  22.697]  ; Viking 1 Lander (1976-1982)
    sites[*,1] = [134.010,  48.269]  ; Viking 2 Lander (1976-1980)
    sites[*,2] = [326.450,  19.330]  ; Pathfinder (Sojourner Rover Jul-Sep 1997)
    sites[*,3] = [175.479, -14.572]  ; Spirit Rover (2004-2010)
    sites[*,4] = [354.473,  -1.946]  ; Opportunity Rover (2004-2018)
    sites[*,5] = [234.100,  68.150]  ; Phoenix Lander (May-Nov 2008)
    sites[*,6] = [137.200,  -4.600]  ; Curiosity Rover (MSL 2012-)
    sites[*,7] = [135.000,   4.500]  ; InSight Lander (2018-)
    sites[*,8] = [ 77.500,  18.400]  ; Perserverence Rover (2021-)
    if (size(slab,/type) gt 0) then dolab = keyword_set(slab) else dolab = 1
    if (dolab) then slab = ['V1','V2','Pa','S','O','Ph','C','I','Pe'] else slab = 0
  endif
  ncol = n_elements(scol)
  if (ncol eq 1) then defcol = scol else defcol = 6
  scol2 = replicate(defcol,nsites>1)
  if (ncol gt 1) then scol2[0:(ncol-1)<(nsites-1)] = scol[0:(ncol-1)<(nsites-1)]
  scol = scol2

  if keyword_set(times) then begin
    times = time_double(times)
    ntimes = n_elements(times)
    if (n_elements(tcolors) ne ntimes) then tcolors = replicate(color, ntimes)
    reset = 1
    noerase = 1
    keep = 1
    tflg = 1
  endif else begin
    ntimes = 1L
    if (n_elements(tcolors) eq 0) then tcolors = color else tcolors = tcolors[0]
    tflg = 0
  endelse

  xzflg = 1  ; view from side
  xyflg = 1  ; view from ecliptic north
  yzflg = 1  ; view from Sun
  npans = 3

  if keyword_set(xz) then begin
    xyflg = 0
    yzflg = 0
    xy = 0
    yz = 0
    npans = 1
    csize *= 0.75
  endif

  if keyword_set(xy) then begin
    xzflg = 0
    yzflg = 0
    xz = 0
    yz = 0
    npans = 1
    csize *= 0.75
  endif

  if keyword_set(yz) then begin
    xzflg = 0
    xyflg = 0
    xz = 0
    yz = 0
    npans = 1
    csize *= 0.75
  endif

  if keyword_set(latlon) then gflg = 1 else gflg = 0
  
  dbr = 0
  if (size(mars,/type) gt 0) then begin
    mflg = mars
    case mflg of
        1  : mbig = 0
        2  : mbig = 1
        3  : dbr = 1
      else : mflg = 0
    endcase
  endif else mflg = 0
  
  if keyword_set(orbit) then oflg = 1 else oflg = 0
  
  if keyword_set(cyl) then cyflg = 1 else cyflg = 0

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

  Twin = !d.window

  undefine, mnum
  if (size(monitor,/type) gt 0) then begin
    if (size(windex,/type) eq 0) then putwin, /config $
                                 else if (windex eq -1) then putwin, /config
    mnum = fix(monitor[0])
  endif else begin
    if (size(windex,/type) gt 0) then if (windex gt -1) then mnum = secondarymon
  endelse

  if (size(psname,/type) eq 7) then begin
    psflg = 1
  endif else begin
    psflg = 0
    if (npans eq 1) then begin
      putwin, /free, monitor=mnum, xsize=500, ysize=473, dx=10, dy=10, scale=wscale  ; MSO projections 1x1
      Owin = !d.window
    endif else begin                                                                 ; MSO projections 1x3
      if (windex eq -1) then begin
        putwin, /free, monitor=mnum, xsize=281, ysize=800, scale=wscale, dx=10
      endif else putwin, /free, monitor=mnum, /yfull, aspect=0.351, dx=10
      Owin = !d.window
      csize = float(!d.x_size)/175.
    endelse
  endelse

  if (gflg) then begin
    putwin, /free, monitor=mnum, xsize=600, ysize=280, dx=-10, dy=-10, scale=wscale  ; MSO Lat-Lon
    Gwin = !d.window
  endif

  if (cyflg) then begin
    putwin, /free, xsize=600, ysize=350, rel=Owin, dx=10, scale=wscale  ; MSO cylindrical
    Cwin = !d.window
  endif

  if (mflg gt 0) then begin                                          ; GEO Lat-Lon on MAG-MOLA map
    if (~noerase or reset) then mag_mola_orbit, -100., -100., big=mbig, dbr=dbr, rwin=Owin, /reset
  endif

  if keyword_set(mhd) then begin                                     ; MHD simulation
    if (mhd gt 1) then begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xz, monitor=mnum
      nflg = 2
    endif else begin
      if (~noerase or reset) then mhd_orbit, [-10.], [-10.], /reset, /xy, monitor=mnum
      nflg = 1
    endelse
  endif else nflg = 0

  if keyword_set(hybrid) then begin                                  ; Hybrid simulation
    if (hybrid eq 1) then begin
      if (~noerase or reset) then hybrid_orbit, [-10.], [-10.], /reset, /xz, monitor=mnum
      bflg = 1
    endif else begin
      if (~noerase or reset) then hybrid_orbit, [-10.], [-10.], /reset, /xz, /flip, monitor=mnum
      bflg = 2
    endelse
  endif else bflg = 0

  if keyword_set(npole) then begin                                   ; North pole projection
    if (~noerase or reset) then mag_npole_orbit, [0.], [0.], monitor=mnum, /reset
    npflg = 1
  endif else npflg = 0

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
    k = 0L
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
  zref = sza[iref]*!radeg
  href = hgt[iref]
  ndays = (tref - time[0])/86400D

  dt = min(abs(torb - tref), jref, /nan)
  dj = round(double(period[jref])*3600D/(time[1] - time[0]))
  
  ok = 1
  first = 1
  
  if (psflg) then popen, psname

  while (ok) do begin
    title = string(time_string(tref),oref,format='(a19,2x,"(Orbit ",i5,")")')
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
    
    if (dob) then begin
        get_data,'mvn_B_1sec_maven_mso',data=bmso
        bb0=bmso.y
        bt=bmso.x
        bdt=60 ;smooth over seconds
        for i=0,2 do bb0[*,i]=smooth(bb0[*,i],bdt,/nan)

        bmag = sqrt(total(bb0*bb0,2,/nan))
        indx = where(bmag gt Bclip, count)
        if (count gt 0L) then bb0[indx,*] = !values.f_nan

        bb=fltarr(n_elements(rndx),3)
        bb[*,0]=interpol(bb0[*,0],bt,time[rndx])
        bb[*,1]=interpol(bb0[*,1],bt,time[rndx])
        bb[*,2]=interpol(bb0[*,2],bt,time[rndx])
        if ~(keyword_set(mscale)) then mscale=0.05
        nskp=5
    endif
    
    if (dov) then begin
        vv=fltarr(n_elements(rndx),3)
        get_data,Vdir,data=vmso,index=iv
        if (iv gt 0) then begin
          if (n_elements(Vrange) ne 2) then Vrange = minmax(vmso.x)
          vndx = where((vmso.x ge min(Vrange)) and (vmso.x le max(Vrange)), count)
          if (count gt 0L) then begin
            vv0=vmso.y[vndx,*]
            vt=vmso.x[vndx]
            vdt=60 ;smooth over seconds
            for i=0,2 do vv0[*,i]=smooth(vv0[*,i],vdt)

            vmag = sqrt(total(vv0*vv0,2,/nan))
            indx = where(vmag gt Vclip, count)
            if (count gt 0L) then vv0[indx,*] = !values.f_nan

            vndx = where((time[rndx] ge min(Vrange)) and (time[rndx] le max(Vrange)), count)
            if (count gt 0L) then begin
              vv[vndx,0]=interpol(vv0[*,0],vt,time[rndx[vndx]])
              vv[vndx,1]=interpol(vv0[*,1],vt,time[rndx[vndx]])
              vv[vndx,2]=interpol(vv0[*,2],vt,time[rndx[vndx]])
              if ~(keyword_set(Vscale)) then Vscale=0.05
              nskp=5
            endif
          endif
        endif else begin
          print,'Velocity variable not found: ',Vdir
          dov = 0
        endelse
    endif

; X-Y Projection

    pan = npans
    msg = title

    if (xyflg) then begin
      !p.multi = [pan, 1, npans]

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
           xtitle='X (Rp)',ytitle='Y (Rp)',charsize=csize,title=msg,thick=thick
      msg = ''
      oplot,xm,ym,color=6,thick=thick
      if (doorb) then oplot,x,y,thick=thick

      if (dodot) then oplot,[x[i]],[y[i]],psym=8,color=tcolors[k]

      if (dob) then begin
        cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=x[i]
              y1=y[i]
              x2=mscale*bb[i,0]+x1
              y2=mscale*bb[i,1]+y1
              if bb[i,2] le 0 then clr=64 $
              else clr=254
              oplot,[x1,x2],[y1,y2],color=clr
          endfor
      endif

      if (dov) then begin
        cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=x[i]
              y1=y[i]
              x2=Vscale*vv[i,0]+x1
              y2=Vscale*vv[i,1]+y1
              if vv[i,2] le 0 then clr=64 $
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
      if (doorb) then oplot,x,y,color=rcols[0],thick=thick

      x = xp
      y = yp
      z = zp

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      if (doorb) then oplot,x,y,color=rcols[1],thick=thick

      x = xw
      y = yw
      z = zw

      indx = where((z lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      if (doorb) then oplot,x,y,color=rcols[2],thick=thick

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

      if (dolab) then begin
        if (npans eq 1) then begin
          xyouts, 0.70, 0.87, "View from Pole", /norm, charsize=csize
          xyouts, 0.70, 0.82, "ALT = " + string(round(href), format='(i4)'), /norm, charsize=csize
          xyouts, 0.70, 0.77, "SZA = " + string(round(zref), format='(i4)'), /norm, charsize=csize
        endif else begin
          xyouts, 0.73, 0.95, "ALT = " + string(round(href), format='(i4)'), /norm, charsize=csize/2.
          xyouts, 0.73, 0.93, "SZA = " + string(round(zref), format='(i4)'), /norm, charsize=csize/2.
          xyouts, 0.67, 0.62, "View from Side", /norm, charsize=csize/2.
          xyouts, 0.67, 0.285, "View from Sun", /norm, charsize=csize/2.
        endelse
      endif

      pan--
    endif

; X-Z Projection

    if (xzflg) then begin
      !p.multi = [pan, 1, npans]

      x = xo
      y = yo
      z = zo
      s = sqrt(x*x + z*z)

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif

      plot,xm,ym,xrange=xrange,yrange=yrange,/xsty,/ysty,/noerase, $
           xtitle='X (Rp)',ytitle='Z (Rp)',charsize=csize,title=msg,thick=thick
      msg = ''
      oplot,xm,ym,color=6,thick=thick
      if (doorb) then oplot,x,z,thick=thick

      if (pflg) then i = imid else i = imin
      if (dodot) then oplot,[x[i]],[z[i]],psym=8,color=tcolors[k],thick=thick

      if (dob) then begin
          cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
            x1=x[i]
            y1=z[i]
            x2=mscale*bb[i,0]+x1
            y2=mscale*bb[i,2]+y1
            if bb[i,1] le 0 then clr=64 else clr=254
            oplot,[x1,x2],[y1,y2],color=clr
          endfor
      endif

      if (dov) then begin
        cts = n_elements(rndx)
        for i=0,cts-1,nskp do begin
          x1=x[i]
          y1=z[i]
          x2=Vscale*vv[i,0]+x1
          y2=Vscale*vv[i,2]+y1
          if vv[i,1] le 0 then clr=64 $
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
      if (doorb) then oplot,x,z,color=rcols[0],thick=thick

      x = xp
      y = yp
      z = zp

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      if (doorb) then oplot,x,z,color=rcols[1],thick=thick

      x = xw
      y = yw
      z = zw

      indx = where((y gt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      if (doorb) then oplot,x,z,color=rcols[2],thick=thick

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

      if (dolab and (npans eq 1)) then begin
        xyouts, 0.70, 0.87, "View from Side", /norm, charsize=csize
        xyouts, 0.70, 0.82, "ALT = " + string(round(href), format='(i4)'), /norm, charsize=csize
        xyouts, 0.70, 0.77, "SZA = " + string(round(zref), format='(i4)'), /norm, charsize=csize
      endif

      pan--
    endif

; Y-Z Projection

    if (yzflg) then begin
      !p.multi = [pan, 1, npans]

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
           xtitle='Y (Rp)',ytitle='Z (Rp)',title=msg,charsize=csize,thick=thick
      msg = ''
      oplot,xm,ym,color=6,thick=thick
      if (doorb) then oplot,y,z,thick=thick

      if (pflg) then i = imid else i = imin
      if (dodot) then oplot,[y[i]],[z[i]],psym=8,color=tcolors[k],thick=thick

      if (dob) then begin
          cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=y[i]
              y1=z[i]
              x2=mscale*bb[i,1]+x1
              y2=mscale*bb[i,2]+y1
              if bb[i,0] le 0 then clr=64 $
              else clr=254
              oplot,[x1,x2],[y1,y2],color=clr
          endfor
      endif

      if (dov) then begin
          cts = n_elements(rndx)
          for i=0,cts-1,nskp do begin
              x1=y[i]
              y1=z[i]
              x2=Vscale*vv[i,1]+x1
              y2=Vscale*vv[i,2]+y1
              if vv[i,0] le 0 then clr=64 $
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
      if (doorb) then oplot,y,z,color=rcols[0],thick=thick

      x = xp
      y = yp
      z = zp

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        x[indx] = !values.f_nan
        y[indx] = !values.f_nan
      endif
      if (doorb) then oplot,y,z,color=rcols[1],thick=thick

      x = xw
      y = yw
      z = zw

      indx = where((x lt 0.) and (s lt 1.), count)
      if (count gt 0L) then begin
        y[indx] = !values.f_nan
        z[indx] = !values.f_nan
      endif
      if (doorb) then oplot,y,z,color=rcols[2],thick=thick

      L0 = sqrt((L + psi*x0)^2. - x0*x0)
      oplot,L0*xm,L0*ym,color=3,line=1,thick=thick

      L0 = sqrt((L_p1 + psi_p1*x0_p1)^2. - x0_p1*x0_p1)
      oplot,L0*xm,L0*ym,color=3,line=1,thick=thick

      if (dolab and (npans eq 1)) then begin
        xyouts, 0.70, 0.87, "View from Sun", /norm, charsize=csize
        xyouts, 0.70, 0.82, "ALT = " + string(round(href), format='(i4)'), /norm, charsize=csize
        xyouts, 0.70, 0.77, "SZA = " + string(round(zref), format='(i4)'), /norm, charsize=csize
      endif

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
            xtitle='X (Rp)',ytitle='S (Rp)',charsize=csize/2.,title=title,thick=thick
       oplot,xm,ym,color=6,thick=thick
       if (doorb) then oplot,x,s,thick=thick

      if (pflg) then i = imid else i = imin
      if (dodot) then oplot,[x[i]],[s[i]],psym=8,color=tcolors[k],thick=thick

      if (doorb) then oplot,xs,sqrt(ys*ys + zs*zs),color=rcols[0],thick=thick
      if (doorb) then oplot,xp,sqrt(yp*yp + zp*zp),color=rcols[1],thick=thick
      if (doorb) then oplot,xw,sqrt(yw*yw + zw*zw),color=rcols[2],thick=thick

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

      if (bflg eq 1) then hybrid_orbit, x, z, x[i], z[i], color=j, psym=0, /xz $
                     else hybrid_orbit, x, z, x[i], z[i], color=j, psym=0, /xz, /flip
    endif

; Put up Mars orbit

    if (mflg gt 0) then begin
      if (pflg) then i = iref else i = rndx[imin]
      title = ''
      if (cflg) then j = color else j = 2
      if (ntimes gt 0) then j = tcolors[k]
      if (doterm gt 0) then ttime = trange[0] else ttime = 0
      if (doalt) then sc_alt = hgt[i] else sc_alt = 0
      mag_mola_orbit, lon[i], lat[i], big=mbig, noerase=noerase, title=title, color=j, $
                      terminator=ttime, psym=scsym, shadow=(doterm - 1), alt=sc_alt, $
                      sites=sites, slab=slab, scol=scol, dbr=dbr
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
      zref = sza[iref]*!radeg
      href = hgt[iref]
      ndays = (tref - time[0])/86400D
      dt = min(abs(torb - tref), jref, /nan)
      dj = round(double(period[jref])*3600D/(time[1] - time[0]))
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

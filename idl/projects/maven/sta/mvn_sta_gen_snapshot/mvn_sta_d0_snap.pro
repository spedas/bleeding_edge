;+
;PROCEDURE:   mvn_sta_d0_snap
;PURPOSE:
;  Creates/refreshes tplot variables of the deflector coverage for O+ 
;  and O2+ from STATIC d0/d1 data.  Also creates tplot variables with 
;  two metrics for evaluating whether the O+ and O2+ distributions are 
;  "mostly" in the field of view:
;
;     Metric 1: ratio of the peak counts in the two equatorial
;               deflection bins to the counts in the adjacent
;               polar bin (isotropic = 1)
;
;     Metric 2: ratio of the total counts in the two equatorial
;               bins to the total counts in all deflection bins
;               (isotropic = 0.5)
;
;     Just An Idea: create a metric that uses the distribution of
;               counts in azimuth to estimate how much signal is
;               missing outside the deflection range -- assumes the
;               distributions of counts in azimuth and elevation are
;               not too different
;
;  Once the above tplot variables are created, shows the measured 
;  distribution of counts for O+ or O2+ as a function of azimuth and 
;  elevation at times selected by the cursor.  A plot of the deflector 
;  distribution (integrated over azimuth) is also shown as a line plot 
;  with the value of the above FOV metric.
;
;  Unless keyword SUM is set, you can hold down the left mouse button 
;  and drag for a movie effect.  Click the right mouse button at any 
;  time to exit.
;
;USAGE:
;  mvn_sta_d0_snap
;
;INPUTS:
;
;KEYWORDS:
;       NAVG:     Number of times to average centered on the selected time.
;                 This is forced to be an odd number, less than or equal to
;                 the value provided.  Default = 1 (no averaging).
;
;       SUM:      Average all times between two selected times.  Occasionally,
;                 ctime does not capture the second time selection and appears
;                 to hang.  If this happens, just click again.
;
;       APID:     APID to use: 'd0' or 'd1'.  Default = 'd0'.
;
;       MASS:     Integer specifying which mass bin to make snapshots for:
;
;                           bin     mass/charge        species
;                         -------------------------------------------
;                            0         1.04            H+
;                            1         2.13            He++, H2+
;                            2         4.49
;                            3         9.10
;                            4        16.89            O+
;                 default -> 5        31.44            O2+
;                            6        45.73            CO2+
;                            7        74.84
;
;                 You can choose only one mass bin for this.
;
;       TMASS:    Integer array specifying which mass bins to make deflector
;                 FOV tplot panels for.  You can make up to eight panels.
;                 If available, the Sun and magnetic field directions will be
;                 overplotted onto the fov spectrogram.  Default = [4,5].
;
;       ERANGE:   Energy range (eV) for testing the field of view.  Applies to
;                 both the tplot panels and the snapshots.  Default = [0,1000].
;
;       KEEP:     Do not close the snapshot windows on exit.
;
;       LASTCUT:  Named variable to hold data for the last snapshots.  Use this
;                 to make your own fancy plots for a publication.
;
;       TMARK:    On the time series window, mark the currently selected time or
;                 time interval with transient timebar(s).
;
;       REFRESH:  Refresh the FOV common block and FOV tplot panels.  Use this 
;                 when you change between 'd0' and 'd1', change ERANGE, or when
;                 you load data for a new date.
;
;       SHOWDIR:  Show the directions and anti-directions of the Sun and the 
;                 magnetic field in the deflector tplot panels and the az-el 
;                 snapshots.  Default = 1 (yes).
;
;       SHOWMASS: Show the mass distribution in a separate window.  Default = 1.
;
;       MINCOUNTS: Minimum number of counts/deflection bin to calculate metrics.
;                  Use this to mask values with poor statistics.  Default = 3.
;
;       BKG:      If set, subtract background counts.  This requires v3 L2 data
;                 or v2 L2 data with the IV_LEVEL keyword set.  Otherwise, it
;                 will have no effect.  Default = 1 (yes).
;
;       Passes many keywords to WIN (e.g. MONITOR, DX, DY, etc.).  If WIN is
;       enabled (win, /config), then by default the snapshot window will be 
;       placed in the secondary monitor.
;
;       Passes many keywords to PLOT (e.g., XSIZE, YTITLE, etc.).  If not set,
;       TITLE becomes the time or time range of the snapshot.
;
;       KEY:      Alternate method for setting keywords.  Structure containing
;                 keyword(s) for this routine, plus many keywords for WIN and
;                 PLOT.  Unrecognized or ambiguous keywords are ignored, but 
;                 they will generate error messages.
;
;                      {KEYWORD: value, KEYWORD: value, ...}
;
;                 This allows you to gather keywords into a single structure and
;                 use them multiple times without a lot of typing.  In case of 
;                 conflict, keywords set explicitly take precedence over KEY.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-09-07 18:22:21 -0700 (Mon, 07 Sep 2026) $
; $LastChangedRevision: 34875 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_gen_snapshot/mvn_sta_d0_snap.pro $
;
;BASED ON:      tsnap.pro
;CREATED BY:    David L. Mitchell
;-
pro mvn_sta_d0_snap, navg=navg, sum=sum, apid=apid, mass=mass, tmass=tmass, erange=erange, keep=keep, $
                     refresh=refresh, key=key, lastcut=lastcut, tmark=tmark, showdir=showdir, $
                     showmass=showmass, mincounts=mincounts, bkg=bkg, $

              ; WIN
                monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
                corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, norm=norm, $
                xpos=xpos, ypos=ypos, full=full, xfull=xfull, yfull=yfull, $

              ; PLOT
                title=title, xtitle=xtitle, ytitle=ytitle, xlog=xlog, ylog=ylog, xrange=xrange, $
                yrange=yrange, xstyle=xstyle, ystyle=ystyle, linestyle=linestyle, psym=psym, $
                symsize=symsize, thick=thick, ticklen=ticklen, charsize=charsize, xmargin=xmargin, $
                ymargin=ymargin, xminor=xminor, yminor=yminor, xthick=xthick, ythick=ythick, $
                xtickformat=xtickformat, ytickformat=ytickformat, xtickinterval=xtickinterval, $
                ytickinterval=ytickinterval, xticklen=xticklen, yticklen=yticklen, xticks=xticks, $
                yticks=yticks

  common sta_fov_com, time, delta_t, counts, phi, theta, energy, mass_arr, sphi, sthe, bphi, bthe

; Set keywords using the KEY structure

  if (size(key,/type) eq 8) then begin
    ktag = tag_names(key)
    tlist = ['NAVG','SUM','APID','MASS','ERANGE','KEEP','REFRESH','LASTCUT','TMARK','SHOWDIR', $
             'SHOWMASS','MINCOUNTS','BKG', $
             'MONITOR','SECONDARY','XSIZE','YSIZE','DX','DY','CORNER','CENTER','XCENTER','YCENTER', $
             'NORM','XPOS','YPOS','FULL','XFULL','YFULL', $
             'TITLE','XTITLE','YTITLE','XLOG','YLOG','XRANGE','YRANGE','XSTYLE','YSTYLE','LINESTYLE', $
             'PSYM','SYMSIZE','THICK','TICKLEN','CHARSIZE','XMARGIN','YMARGIN','XMINOR','YMINOR', $
             'XTHICK','YTHICK','XTICKFORMAT','YTICKFORMAT','XTICKINTERVAL','YTICKINTERVAL', $
             'XTICKLEN','YTICKLEN','XTICKS','YTICKS']
    for j=0,(n_elements(ktag)-1) do begin
      i = strmatch(tlist, ktag[j]+'*', /fold)
      case (total(i)) of
          0  : print, "Keyword unrecognized: ", ktag[j]
          1  : begin
                 kname = (tlist[where(i eq 1)])[0]
                 ok = execute('kset = size(' + kname + ',/type) gt 0',0,1)
                 if (not kset) then ok = execute(kname + ' = key.(j)',0,1)
               end
        else : print, "Keyword ambiguous: ", ktag[j]
      endcase
    endfor
  endif

; Set some defaults

  npts = keyword_set(sum) ? 2 : 1
  if ((n_elements(navg) gt 0) and (npts eq 1)) then k = (round(navg[0]) - 1)/2 > 0 else k = 0

  keep = keyword_set(keep)
  tmark = keyword_set(tmark)
  dx = (n_elements(dx) gt 0) ? fix(dx[0]) : 10
  dy = (n_elements(dy) gt 0) ? fix(dy[0]) : 10
  secondary = (n_elements(secondary) gt 0) ? keyword_set(secondary) : 1
  showdir = (n_elements(showdir) gt 0) ? keyword_set(showdir) : 1
  showmass = (n_elements(showmass) gt 0) ? keyword_set(showmass) : 1
  bkg = (n_elements(bkg) gt 0) ? keyword_set(bkg) : 1
  mincounts = (n_elements(mincounts) gt 0) ? float(mincounts[0]) : 3.
  symthick = (n_elements(thick) gt 0) ? thick[0] : 2.

  line_colors, 11, previous_lines=plines
  cols = [1, 2, 3, 5, 4, 6, 5, 3]  ; line color for each mass bin

  if (size(apid,/type) eq 7) then begin
    apid = strlowcase(apid[0])
    if ((apid ne 'd0') and (apid ne 'd1')) then begin
      print, "Invalid APID: ", apid
      return
    endif
  endif else apid = 'd0'
  routine = 'mvn_sta_get_' + apid

  erange = (n_elements(erange) lt 2) ? [0.,1000.] : minmax(erange)
  mass = (n_elements(mass) eq 0) ? 5 : fix(mass[0]) < 7 > 0
  tmass = (n_elements(tmass) eq 0) ? [4,5] : fix(tmass) < 7 > 0
  tmass = tmass[uniq(tmass, sort(tmass))]  ; make each panel only once

; Make sure d0/d1 data are loaded

  dtime = call_function(routine, /times)  ; data times in STATIC common block
  ndtimes = n_elements(dtime)
  if (size(dtime,/type) ne 5) then begin
    print,"No " + apid + " data loaded.  Abort!"
    line_colors, plines
    return
  endif

  if (showdir) then begin

; Check to see if sufficient SPICE information exists to transform the Sun
; and magnetic field directions into the STATIC frame

    mvn_spice_stat, check=dtime, summary=sinfo, /silent
    if (~sinfo.all_check) then begin
      print,"  SPICE not initialized or insufficient coverage."
      yn = 'N'
      read, yn, prompt='  Initialize SPICE now (y|n) ? ', format='(a1)'
      if (strupcase(yn) eq 'Y') then begin
        tstart = time_string(min(dtime) - 86400D, prec=-3)
        tstop = time_string(max(dtime) + (2D*86400D), prec=-3)
        mvn_swe_spice_init, trange=[tstart,tstop], /force
        mvn_spice_stat, check=dtime, summary=sinfo, /silent
      endif
    endif
    gotspice = sinfo.all_check

; Check to see if MAG 1-sec data are loaded

    if (~find_handle('mvn_B_1sec')) then begin
      print,"  MAG 1-sec data not loaded."
      yn = 'N'
      read, yn, prompt='  Load MAG data now (y|n) ? ', format='(a1)'
      if (strupcase(yn) eq 'Y') then begin
        tstart = time_string(min(dtime), prec=-3)
        tstop = time_string(max(dtime) + 86400D, prec=-3)
        mvn_mag_load, 'L2_1SEC', trange=[tstart,tstop]
      endif
    endif
    gotmag = find_handle('mvn_B_1sec')

  endif else begin
    gotspice = 0
    gotmag = 0
  endelse

; Compare currently loaded STATIC data with the fov common block
; Refresh the fov common block if necessary

  ntimes = n_elements(time)  ; data times in fov common block

  if (n_elements(refresh) eq 0L) then refresh = 0
  if (ntimes gt 0L) then begin
    i = nn2(dtime, time, maxdt=4D, /valid, vindex=j)
    if (n_elements(j) lt ndtimes) then refresh = 1
  endif else refresh = 1

  if (refresh) then begin
    time = dtime
    ntimes = ndtimes
    counts = fltarr(ntimes,32,64,8)  ; 32e64a2m at each time
    phi = counts
    theta = counts
    energy = fltarr(ntimes,32)       ; not a function of angle or mass
    mass_arr = fltarr(32,8)          ; not a function of time or angle

    for i=0L,(ntimes-1L) do begin
      dat = call_function(routine, time[i])
      counts[i,*,*,*] = bkg ? (dat.data - dat.bkg) > 0. : dat.data
      phi[i,*,*,*] = dat.phi
      theta[i,*,*,*] = dat.theta
      energy[i,*] = dat.energy[*,0,0]
    endfor
    mass_arr = mean(dat.mass_arr, dim=2)
    undefine, dat
  endif

; Make sure the tplot variables exist and have the standard tags and correct dimensions
; Refresh the tplot variables if necessary

  tplot_names, /current, names=names, /silent
  addnames = ['']
  sname = ['H+', 'He++', 'M4+', 'M9+', 'O+', 'O2+', 'CO2+', 'M75+']
  var = 'sta_' + apid + '_theta_' + sname  ; fov panel
  var1 = 'sta_' + apid + '_edge_' + sname  ; edge metric
  var2 = 'sta_' + apid + '_cntr_' + sname  ; center metric

  for j=0,(n_elements(tmass)-1) do begin
    if (~find_handle(var[tmass[j]]) or refresh) then begin
      y = replicate(!values.f_nan, ntimes, 6)
      v = y
      for i=0L,(ntimes-1L) do begin
        endx = where((energy[i,*] ge erange[0]) and (energy[i,*] le erange[1]), count)
        if (count gt 0L) then begin
          the0 = reform(theta[i,endx,*,tmass[j]])
          the0 = reform(mean(the0, dim=1), 4, 16)   ; average over erange
          v[i,1:4] = the0[*,0]                      ; theta not a function of phi
          cnt0 = reform(counts[i,endx,*,tmass[j]])    
          cnt0 = reform(total(cnt0, 1), 4, 16)      ; sum over erange
          y[i,1:4] = total(cnt0, 2)                 ; sum over phi
        endif
      endfor
      dy = sqrt(y) > (0.01*y)                       ; uncertainty estimate
      v[*,0] = v[*,1] - (v[*,2] - v[*,1])           ; padding so spectrogram displays properly
      v[*,5] = v[*,4] + (v[*,4] - v[*,3])

      vname = var[tmass[j]]
      store_data, vname, data={x:time, y:y, dy:dy, v:v}
      ylim, vname, -45, 45, 0
      options, vname, 'spec', 1
      options, vname, 'yticks', 2
      options, vname, 'yminor', 3
      options, vname, 'ytitle', 'sta ' + apid + '!cTheta ' + sname[tmass[j]]
      options, vname, 'x_no_interp', 1
      options, vname, 'y_no_interp', 1
      zpeak = 10.^(round(alog10(max(y,/nan)) > 4))  ; allow some saturation
      zlim, vname, zpeak/1e4, zpeak, 1
      options, vname, 'ztickformat', 'mvn_ql_pfp_tplot_ytickname_plus_log'
      options, vname, 'ztitle', 'Counts'

      m = where(y[*,3] ge y[*,2], mcount, complement=n, ncomplement=ncount)
      metric1 = replicate(!values.f_nan, ntimes)
      if (mcount gt 0L) then begin
        metric1[m] = y[m,3]/(y[m,4] > 0.5)
        indx = where(y[m,4] lt mincounts, count)
        if (count gt 0L) then metric1[m[indx]] = !values.f_nan
      endif
      if (ncount gt 0L) then begin
        metric1[n] = y[n,2]/(y[n,1] > 0.5)
        indx = where(y[n,1] lt mincounts, count)
        if (count gt 0L) then metric1[n[indx]] = !values.f_nan
      endif
      vname = var1[tmass[j]]
      store_data, vname, data={x:time, y:metric1}
      ylim, vname, 0.1, 100., 1
      options, vname, 'ytitle', 'sta ' + apid + ' ' + sname[j+4] + '!cEdge Metric '
      options, vname, 'constant', 1.0

      v = total(y[*,1:4], 2)
      metric2 = total(y[*,2:3], 2)/(v > 0.5)
      indx = where(v lt 4.*mincounts, count)
      if (count gt 0L) then metric2[indx] = !values.f_nan
      vname = var2[tmass[j]]
      store_data, vname, data={x:time, y:metric2}
      ylim, vname, 0., 1., 0
      options, vname, 'ytitle', 'sta ' + apid + ' ' + sname[j+4] + '!cCntr Metric '
      options, vname, 'yticks', 2
      options, vname, 'yminor', 5
      options, vname, 'constant', 0.5
    endif
  endfor

; Get the directions of the Sun and magnetic field in the STATIC frame

  if (gotspice) then begin
    if (~find_handle('Sun_STATIC_The') or refresh) then begin
      mvn_sundir, frame='sta', /pol, dt=4
      ylim, 'Sun_STATIC_The', -45, 45, 0
      options, 'Sun_STATIC_The', 'colors', 1
      options, 'Sun_STATIC_The', 'psym', 3

      get_data, 'Sun_MAVEN_STATIC', data=sun
      x = spline(sun.x, sun.y[*,0], time)
      y = spline(sun.x, sun.y[*,1], time)
      z = spline(sun.x, sun.y[*,2], time)
      sphi = atan(y,x)*!radeg             ; sun direction is a unit vector
      sthe = asin(z > (-1.) < 1.)*!radeg  ; prevent round-off errors
      undefine, sun
    endif

    if (gotmag) then begin
      if (~find_handle('Mag_STATIC_The') or refresh) then begin
        if (~find_handle('mvn_B_1sec_MAVEN_STATIC')) then spice_vector_rotate_tplot, 'mvn_B_1sec', 'MAVEN_STATIC'
        get_data, 'mvn_B_1sec_MAVEN_STATIC', data=mag
        bamp = sqrt(total(mag.y^2.,2))
        bphi = atan(mag.y[*,1],mag.y[*,2])*!radeg
        bthe = asin(mag.y[*,2]/bamp > (-1.) < 1.)*!radeg  ; prevent round-off errors
        store_data,'Mag_STATIC_Phi',data={x:mag.x, y:bphi}
        store_data,'Mag_STATIC_The',data={x:mag.x, y:bthe}
        ylim, 'Mag_STATIC_The', -45, 45, 0
        options, 'Mag_STATIC_The', 'colors', 0
        options, 'Mag_STATIC_The', 'psym', 3

        x = spline(mag.x, mag.y[*,0], time)
        y = spline(mag.x, mag.y[*,1], time)
        z = spline(mag.x, mag.y[*,2], time)
        bamp = sqrt(x*x + y*y + z*z)
        bphi = atan(y,x)*!radeg
        bthe = asin(z/bamp > (-1.) < 1.)*!radeg  ; prevent round-off errors
        undefine, mag
      endif
    endif else print,"No MAG data.  Skipping."
  endif else print,"Insufficient SPICE coverage to calculate Sun and MAG angles.  Skipping."

; Make tplot variables

  for j=0,(n_elements(tmass)-1) do begin
    vname = var[tmass[j]] + '_sm'
    if (~find_handle(vname) or refresh) then begin
      cname = var[tmass[j]]
      if gotspice then cname = [cname, 'Sun_STATIC_The']
      if gotmag then cname = [cname, 'Mag_STATIC_The']
      store_data, vname, data=cname
      ylim, vname, -45, 45, 0
      i = where(names eq vname, count)
      if (count eq 0L) then addnames = [addnames, vname]
    endif
  endfor

; Include tplot variables for the FOV metrics

  vname = 'sta_' + apid + '_fov_edge'
  if (~find_handle(vname) or refresh) then begin
    store_data, vname, data=var1[tmass]
    ylim, vname, 0.1, 100., 1
    options, vname, 'ytitle', 'sta ' + apid + '!cEdge Metric'
    options, vname, 'colors', cols[tmass]
    options, vname, 'labels', sname[tmass]
    options, vname, 'labflag', 1
    i = where(names eq vname, count)
    if (count eq 0L) then addnames = [addnames, vname]
  endif

  vname = 'sta_' + apid + '_fov_cntr'
  if (~find_handle(vname) or refresh) then begin
    store_data, vname, data=var2[tmass]
    options, vname, 'ytitle', 'sta ' + apid + '!cCntr Metric'
    options, vname, 'colors', cols[tmass]
    options, vname, 'labels', sname[tmass]
    options, vname, 'labflag', 1
    i = where(names eq vname, count)
    if (count eq 0L) then addnames = [addnames, vname]
  endif

  if (n_elements(addnames) gt 1L) then tplot, addnames[1:*], /add

; Now make snapshots of the 3D distribution at time(s) selected by the cursor
; Data are obtained from the fov common block and not from a tplot variable

  lim = {xtitle:'Azimuth (deg)', xrange:[-180.,180.+22.5], xticks:4, xminor:3, xstyle:1, $
         ytitle:'Elevation (deg)', yrange:[-90,90], yticks:2, yminor:3, ystyle:1, $
         ztitle:(sname[mass] + ' Counts'), zrange:[1,10000], zlog:1, x_no_interp:1, $
         y_no_interp:1, charsize:1.5, xmargin:[10,12], xtickv:[-180,-90,0,90,180], $
         ztickformat:'mvn_ql_pfp_tplot_ytickname_plus_log'}

  if (size(title,/type) eq 7) then str_element, lim, 'title', title, /add
  if (n_elements(ticklen) gt 0L) then str_element, lim, 'ticklen', ticklen, /add
  if (n_elements(charsize) gt 0L) then str_element, lim, 'charsize', charsize, /add
  if (n_elements(xmargin) gt 0L) then str_element, lim, 'xmargin', xmargin, /add
  if (n_elements(ymargin) gt 0L) then str_element, lim, 'ymargin', ymargin, /add

; Create snapshot windows

  win, /stat, /silent, config=config
  if config.enable then begin
    if ((n_elements(secondary) eq 0) and (n_elements(monitor) eq 0)) then secondary = 1
    if (n_elements(dx) eq 0) then dx = 10
    if (n_elements(dy) eq 0) then dy = 10
  endif
  if (n_elements(xsize) eq 0) then xsize = 800
  if (n_elements(ysize) eq 0) then ysize = 400

  Twin = !d.window
  win, /free, monitor=monitor, secondary=secondary, xsize=xsize, ysize=ysize, dx=dx, dy=dy, $
       corner=corner, center=center, xcenter=xcenter, ycenter=ycenter, xpos=xpos, ypos=ypos, $
       norm=norm, full=full, xfull=xfull, yfull=yfull
  Swin = !d.window

  win, /free, xsize=(1.0675*ysize), ysize=ysize, relative=Swin, /top, dx=10
  Dwin = !d.window

  win, /free, clone=Swin, relative=Swin, /left, dy=-10
  Awin = !d.window

  if (showmass) then begin
    win, /free, clone=Dwin, relative=Awin, /top, dx=10
    Mwin = !d.window
  endif

; Make snapshot(s)

  wset, Twin
  if (npts eq 1) then print,"Select time(s).  Right button any time to exit." $
                 else print,"Select start and stop time(s).  Right button any time to exit."
  ctime,t,npoints=npts,silent=2  ; on first call to ctime, don't wait for button up transition

  if (size(t,/type) eq 2) then begin
    wdelete,Swin
    wdelete,Dwin
    wdelete,Awin
    if (showmass) then wdelete,Mwin
    line_colors, plines
    return
  endif

  dt = time - shift(time,1)
  dt[0] = dt[1]
  dt /= 2D
  imax = n_elements(time) - 1L
  keepgoing = 1

  while (keepgoing) do begin
    i = (nn2(time, t) + [-k,k]) > 0L < imax
    i = min(i, max=j)
    if (tmark) then timebar, [time[i]-dt[i], time[j]+dt[j]], /line, /transient
    if (i eq j) then begin
      endx = where((energy[i,*] ge erange[0]) and (energy[i,*] le erange[1]), count)
      if (count gt 0L) then begin
        phi0 = reform(phi[i,endx,*,mass])
        phi0 = reform(mean(phi0, dim=1), 4, 16)       ; average over erange
        x = reform(phi0[0,*])                         ; phi not a function of theta
        the0 = reform(theta[i,endx,*,mass])
        the0 = reform(mean(the0, dim=1), 4, 16)       ; average over erange
        y = the0[*,0]                                 ; theta not a function of phi
        cnt0 = reform(counts[i,endx,*,mass])    
        z = transpose(reform(total(cnt0, 1), 4, 16))  ; sum over erange
        dz = sqrt(z) > (0.01*z)                       ; uncertainty estimate
        zthe = total(z, 1)                            ; sum over phi
        dzthe = sqrt(zthe) > (0.01*zthe)              ; uncertainty estimate
        zphi = total(z, 2)                            ; sum over theta
        dzphi = sqrt(zphi) > (0.01*zphi)              ; uncertainty estimate
        cnt1 = reform(counts[i,endx,*,*])
        cnt1 = total(cnt1, 1)                         ; sum over energy
        cnt1 = total(cnt1, 1)                         ; sum over angle
        dcnt1 = sqrt(cnt1) > (0.01*cnt1)              ; uncertainty estimate
        u = mean(mass_arr[endx,*], dim=1)             ; average over energy
      endif
    endif else begin
      emean = mean(energy[i:j,*], dim=1)
      endx = where((emean ge erange[0]) and (emean le erange[1]), count)
      if (count gt 0L) then begin
        phi0 = reform(phi[i:j,endx,*,mass])
        phi0 = mean(phi0, dim=1)                      ; average over time
        phi0 = reform(mean(phi0, dim=1), 4, 16)       ; average over erange
        x = reform(phi0[0,*])                         ; phi not a function of theta
        the0 = reform(theta[i:j,endx,*,mass])
        the0 = mean(the0, dim=1)                      ; average over time
        the0 = reform(mean(the0, dim=1), 4, 16)       ; average over erange
        y = the0[*,0]                                 ; theta not a function of phi
        cnt0 = reform(counts[i:j,endx,*,mass])
        cnt0 = reform(total(cnt0, 1))                 ; sum over time
        z = transpose(reform(total(cnt0, 1), 4, 16))  ; sum over erange
        dz = sqrt(z) > (0.01*z)                       ; uncertainty estimate
        zthe = total(z, 1)                            ; sum over phi
        dzthe = sqrt(zthe) > (0.01*zthe)              ; uncertainty estimate
        zphi = total(z, 2)                            ; sum over theta
        dzphi = sqrt(zphi) > (0.01*zphi)              ; uncertainty estimate
        cnt1 = reform(counts[i:j,endx,*,*])
        cnt1 = total(cnt1, 1)                         ; sum over time
        cnt1 = total(cnt1, 1)                         ; sum over energy
        cnt1 = total(cnt1, 1)                         ; sum over angle
        dcnt1 = sqrt(cnt1) > (0.01*cnt1)              ; uncertainty estimate
        u = mean(mass_arr[endx,*], dim=1)             ; average over energy
      endif
    endelse

; Recalculate the metrics based on the (possibly averaged) data

    zmin = (zthe[1] gt zthe[2]) ? zthe[0] : zthe[3]
    m1 = (zmin ge mincounts) ? max(zthe[1:2], /nan)/zmin : !values.f_nan
    ztot = total(zthe, /nan)
    m2 = (ztot ge 4.*mincounts) ? total(zthe[1:2], /nan)/ztot : !values.f_nan

; Add padding for the spectrogram and histograms so they display properly

    xp = replicate(!values.f_nan, 18)
    yp = replicate(!values.f_nan, 6)
    zp = replicate(!values.f_nan, 18, 6)
    dzp = zp
    zthep = yp
    dzthep = yp
    zphip = xp
    dzphip = xp
    up = replicate(!values.f_nan, 10)
    cnt1p = up
    dcnt1p = up

    xp[1:16] = x
    xp[0] = xp[1] - (xp[2] - xp[1])
    xp[17] = xp[16] + (xp[16] - xp[15])
    yp[1:4] = y
    yp[0] = yp[1] - (yp[2] - yp[1])
    yp[5] = yp[4] + (yp[4] - yp[3])
    zp[1:16,1:4] = z
    dzp[1:16,1:4] = dz
    zthep[1:4] = zthe
    dzthep[1:4] = dzthe
    zphip[1:16] = zphi
    dzphip[1:16] = dzphi
    up[1:8] = u
    up[0] = (up[1] - (up[2] - up[1])) > 0.001
    up[9] = up[8] + (up[8] - up[7])
    cnt1p[1:8] = cnt1
    dcnt1p[1:8] = dcnt1

    x = temporary(xp)
    y = temporary(yp)
    z = temporary(zp)
    dz = temporary(dzp)
    zthe = temporary(zthep)
    dzthe = temporary(dzthep)
    zphi = temporary(zphip)
    dzphi = temporary(dzphip)
    u = temporary(up)
    cnt1 = temporary(cnt1p)
    dcnt1 = temporary(dcnt1p)

    hpeak = 10.^(ceil(alog10(max(z,/nan) > max(zthe,/nan) > max(zphi,/nan))) > 4)
    hrange = [hpeak/1e4, hpeak]
    zpeak = 10.^(round(alog10(max(z,/nan) > max(zthe,/nan) > max(zphi,/nan))) > 4)
    str_element, lim, 'zrange', [zpeak/1e4, zpeak], /add
    mpeak = 10.^(ceil(alog10(max(cnt1,/nan))) > 4)
    mrange = [mpeak/1e4, mpeak]

; Put up the snapshots

    wset, Swin
      if (size(title,/type) ne 7) then begin
        tmsg = time_string(time[i])
        if (i ne j) then tmsg += ' - ' + strmid(time_string(time[j]),11)
      endif else tmsg = title[0]
      str_element, lim, 'title', apid + ' : ' + tmsg, /add
      specplot, x, y, z, limits=lim
      ssize = 2.0
      if (showdir) then begin
        if (gotspice) then begin
          xyouts, [sphi[i]], [sthe[i]-4.0], "!9n!1H", charsize=ssize, charthick=2, color=1, align=0.5
          msphi = (sphi[i] gt 0.) ? sphi[i] - 180. : sphi[i] + 180.
          xyouts, [msphi+0.5], [-sthe[i]-3.5], "+", charsize=ssize, charthick=2, color=1, align=0.5
        endif
        if (gotmag) then begin
          xyouts, [bphi[i]-4.5], [bthe[i]-4.5], "+B", charsize=ssize, charthick=2, color=!p.color, align=0.5
          mbphi = (bphi[i] gt 0.) ? bphi[i] - 180. : bphi[i] + 180.
          xyouts, [mbphi-5.0], [-bthe[i]-4.5], "-B", charsize=ssize, charthick=2, color=!p.color, align=0.5
        endif
      endif
      xyouts, 93., 0., 'H A R N E S S', align=0.5, orient=90, charsize=1.5
      msg = strtrim(strcompress(string(erange, format='(i3," - ",i5," eV")')),2)
      xyouts, 0.15, 0.85, msg, align=0.0, charsize=1.5, /norm

      lastcut = {time:[time[i],time[j]], x:x, y:y, z:z, dz:dz, navg:(j-i+1), erange:erange}
    wset, Dwin
      msg1 = string(m1, format='("edge : ", f5.2)')
      msg2 = string(m2, format='("cntr : ", f5.2)')

      plot, y, zthe, psym=10, xtitle='Elevation (deg)', ytitle=(sname[mass]+' Counts'), $
                     xrange=[-90,90], /xsty, xticks=2, xminor=3, charsize=1.5, $
                     yrange=hrange, /ylog, /ysty, title=(msg1+'    '+msg2), $
                     ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
      errplot, y, zthe-dzthe, zthe+dzthe, width=0

      str_element, lastcut, 'metric1', m1, /add
      str_element, lastcut, 'metric2', m2, /add
      str_element, lastcut, 'zthe', zthe, /add
      str_element, lastcut, 'dzthe', dzthe, /add
    wset,Awin
      plot, x, zphi, psym=10, xtitle='Azimuth (deg)', ytitle=(sname[mass]+' Counts'), $
                     xrange=[-180,180+22.5], /xsty, xticks=4, xminor=3, charsize=1.5, $
                     yrange=hrange, /ylog, /ysty, title=lim.title, xmargin=[10,12], $
                     xtickv=[-180,-90,0,90,180], ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
      errplot, x, zphi-dzphi, zphi+dzphi, width=0
      xyouts, 93., 100.*hrange[0], 'H A R N E S S', align=0.5, orient=90, charsize=1.5

      str_element, lastcut, 'zphi', zphi, /add
      str_element, lastcut, 'dzphi', dzphi, /add

    if (showmass) then begin
      wset,Mwin
      plot, u, cnt1, psym=10, xtitle='Mass (amu)', ytitle='Counts', charsize=1.5, title=lim.title, $
                     xrange=[0.7,100.], /xlog, /xsty, yrange=mrange, /ylog, /ysty, $
                     ytickformat='mvn_ql_pfp_tplot_ytickname_plus_log'
      errplot, u, cnt1-dcnt1, cnt1+dcnt1, width=0
      cnt2 = 0.5*cnt1
      if (cnt2[1] gt mrange[0]) then xyouts, u[1], cnt2[1], sname[0], align=0.5, charsize=1.2
      if (cnt2[5] gt mrange[0]) then xyouts, u[5], cnt2[5], sname[4], align=0.5, charsize=1.2
      if (cnt2[6] gt mrange[0]) then xyouts, u[6], cnt2[6], sname[5], align=0.5, charsize=1.2
    endif

    wset, Twin
    ctime,tnext,npoints=npts,silent=2
    if (npts gt 1) then cursor, cx, cy, /norm, /up
    if (size(tnext,/type) eq 2) then keepgoing = 0
    if (tmark) then timebar, [time[i]-dt[i], time[j]+dt[j]], /line, /transient
    t = tnext
  endwhile

  if (~keep) then begin
    wdelete,Swin
    wdelete,Dwin
    wdelete,Awin
    if (showmass) then wdelete,Mwin
  endif

  line_colors, plines  ; restore original line colors

end

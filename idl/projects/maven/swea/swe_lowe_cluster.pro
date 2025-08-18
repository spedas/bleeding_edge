;+
;PROCEDURE:   swe_lowe_cluster
;PURPOSE:
;  Sporadic low-energy anomaly cluster analysis.
;
;USAGE:
;  swe_lowe_cluster [, KEYWORD=value, ...]
;
;INPUTS:
;
;KEYWORDS:
;       TRANGE:   Process data over this time range.
;
;       WIDTH:    Boxcar width in points for performing cluster analysis.
;                 Odd number.  Default = 75.
;
;       NPTS:     Half-width of boxcar for calculating upper envelope.
;                 Default = 16.
;
;       LAMBDA:   Smoothing parameter for spline_smooth.  Default = 1.
;
;       FRAC:     Fraction of lowest points to ignore in calculating smooth
;                 curve through upper envelope of data.  Default = 0 (use
;                 all points).
;
;       OUTLIER:  With one-cluster analysis, this discard outliers more than
;                 this many standard deviations from the mean.
;
;       MINPTS:   If OUTLIER is set, this specifies the minimum number of 
;                 points remaining after discarding outliers.  If too many
;                 points are flagged as outliers, then cluster analysis is
;                 preferred.  Default = WIDTH - 5.
;
;       TSTOP:    Times of shadow boundaries.
;
;       BUFFER:   Buffer zone at shadow boundaries.  All quality flags within
;                 BUFFER seconds of the boundary are set to unity.  The buffer
;                 zone is asymmetric about the shadow boundary because the flux
;                 changes more gradually on the dark side of the boundary.
;                 Default [sun,dark] = [8,16] seconds.
;
;       MINDELTA: Minimum cluster separation for identifying anomalous spectra.
;                 Default = 1 (sigma).
;
;       MAXRATIO: Maximum variance ratio for identifying anomalous spectra.
;                 Default = 0.4 (minvar/maxvar).
;
;       MAXBAD:   The maximum fraction of points within a boxcar to flag as bad.
;                 Default = 0.7.
;
;       MOBETAH:  For the low energy band, the cluster with more points is taken
;                 to be "good".  Not recommended.
;
;       MINSUP:   Minimum density suppression. The low-energy anomaly usually
;                 results in a suppression of 0.4-0.8 for both the low and high
;                 energy bands.  Larger apparent suppression factors can be caused
;                 by attempting to use cluster analysis on large real density 
;                 changes, such as during discrete precipitation events in shadow.
;                 This keyword sets the quality flag to 1 (unknown) whenever the
;                 suppression falls below MINSUP.  Default = 0.3
;
;       FLAG:     Quality flag: (2 = good, 1 = unknown, 0 = bad).
;
;       QUALITY:  Structure containing the time and flag.
;
;       DIAG:     Returns structure of diagnostic information.
;
;       TPLOT:    Make tplot panels of diagnostics.
;
;       SETFLAG:  Set the quality flag in the SPEC, PAD, and 3D data structures.
;
;       QUIET:    Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-05-01 09:13:11 -0700 (Wed, 01 May 2024) $
; $LastChangedRevision: 32542 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_lowe_cluster.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro swe_lowe_cluster, width=width, npts=npts, lambda=lambda, frac=frac, diag=diag, $
                      outlier=outlier, minpts=minpts, tstop=tstop, buffer=buffer, $
                      mindelta=mindelta, maxratio=maxratio, maxbad=maxbad, flag=flag, $
                      mobetah=mobetah, trange=trange, quality=quality, setflag=setflag, $
                      tplot=doplot, minsup=minsup, quiet=quiet

  @mvn_swe_com

  tstart = systime(/utc,/sec)
  cret = string("15b) ;"
  blab = ~keyword_set(quiet)

; Boxcar and outlier analysis parameters

  width = (n_elements(width) eq 0) ? 75L : round(width[0])           ; boxcar width
  if (~(width mod 2)) then width++                                   ; make sure width is odd
  halfwidth = width/2
  buff = [8,16]                                                      ; shadow boundary buffer [sun,dark]
  case n_elements(buffer) of
     0   : ; accept default
     1   : buff[*] = buffer[0]
    else : buff = buffer[0:1]
  endcase
  minpts = (n_elements(minpts) eq 0) ? width - 5 : fix(minpts[0])    ; minimum points in a cluster
  outlier = (n_elements(outlier) eq 0) ? 3.5 : float(outlier[0])     ; outlier threshold (stddevs)
  mindelta = (n_elements(mindelta) eq 0) ? 1.0 : float(mindelta[0])  ; minimum cluster separation
  maxratio = (n_elements(maxratio) eq 0) ? 0.4 : float(maxratio[0])  ; minimum variance improvement
  minsup = (n_elements(minsup) eq 0) ? 0.3 : float(minsup[0])        ; minimum density suppression
  maxbad = (n_elements(maxbad) eq 0) ? 0.7 : float(maxbad[0])        ; maximum fraction of bad spectra
  mobetah = keyword_set(mobetah)                                     ; assume the larger cluster is good
  maxdt = 0.25                                                       ; nn2 tolerance used with MOBETAH
  quality = 0                                                        ; initialize quality as non-structure

; Spline-smooth parameters

  npts = (n_elements(npts) eq 0) ? 8 : fix(npts[0])                  ; number of points for each spline
  lambda = (n_elements(lambda) eq 0) ? 1D : double(lambda[0])        ; tension on the spline (0 = cubic)
  frac =  (n_elements(frac) eq 0) ? 0.30 : float(frac[0]) < 1.       ; fraction of lowest points to ignore

; Make sure data are loaded

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"Cannot find SPEC data."
    return
  endif
  ut = mvn_swe_engy.time
  if (n_elements(trange) gt 1) then trange = minmax(time_double(trange)) else trange = minmax(ut)
  indx = where((ut ge trange[0]) and (ut lt trange[1]), nspec)
  if (nspec eq 0) then begin
    print,"No SPEC data within trange: ", time_string(trange)
    return
  endif
  ut = ut[indx]
  flag = replicate(1B, nspec)  ; quality flag (2B = valid, 1B = unknown, 0B = invalid)
  dark = replicate(1, nspec)   ; darkness flag (1 = dark, 0 = light)

; Check the time range against the ephemeris coverage -- bail if there's a problem

  bail = 0
  mk = spice_test('*', verbose=-1)
  indx = where(mk ne '', count)
  if (count eq 0) then begin
    print,"You must initialize SPICE first."
    bail = 1
  endif else begin
    mvn_spice_stat, summary=sinfo, check=minmax(ut), /silent
    if (~sinfo.spk_check) then begin
      print,"Insufficient SPICE coverage for the requested time range."
      print,"  -> Reinitialize SPICE to include your time range."
      bail = 1
    endif
  endelse

  if (bail) then return

; Determine when spacecraft is in darkness

  R_m = 3389.50D            ; +/- 0.2 (volumetric, MGS-MOLA)
  shadow = 1D + (150D/R_m)  ; EUV shadow
  timestr = time_string(ut,prec=5)
  cspice_str2et, timestr, et
  cspice_spkezr, 'MAVEN', et, 'MAVEN_MSO', 'NONE', 'MARS', svec, ltime
  x = reform(svec[0,*])/R_m
  y = reform(svec[1,*])/R_m
  z = reform(svec[2,*])/R_m
  s = sqrt(y*y + z*z)
  indx = where((x gt 0D) or (s gt shadow), count)
  if (count gt 0L) then dark[indx] = 0

  dd = dark - shift(dark,1)
  dd[0] = 0                      ; don't stop at the beginning
  istop = where(dd ne 0, nstop)  ; time indices of shadow boundaries (intermediate stops)
  istop = [istop, (nspec-1L)]    ; stop at the end
  if (nstop eq 0) then istop = istop[1]
  tstop = ut[istop]

; Calculate pseudo density (for zero s/c potential)

  var = ['N_lo','N_hi']
  vart = var + '_topsmooth'
  varc = var + '_cmp'
  varn = var + '_norm'
  erange = [0,6,12]  ; eV
  lab = ['< 6 eV','6-12 eV']
  col = [4,6]
  sc_pot = mvn_swe_engy.sc_pot
  for i=0,1 do begin
    mvn_swe_engy.sc_pot = 0.
    mvn_swe_n1d, /mom, erange=erange[i:(i+1)], minden=1.e-5
    get_data, 'mvn_swe_spec_dens', data=dat, alim=lim
    j = where((dat.x ge trange[0]) and (dat.x lt trange[1]))
    dat = {x:dat.x[j], y:dat.y[j], dy:dat.dy[j]}
    store_data, var[i], data=dat, lim=lim

; Spline smooth pseudo density, ignoring lowest FRAC of values, then normalize

    topsmooth, var[i], npts=npts, frac=frac, lambda=lambda, interp=0

    store_data,varc[i],data=[var[i], vart[i]]
    options,varc[i],'colors',[!p.color,col[i]]
    options,varc[i],'ytitle','Ne [cm!u-3!n]!c' + lab[i]
    ylim,varc[i],0.02,20,1

    div_data, var[i], vart[i], newname=varn[i]
    options,varn[i],'psym',3
    options,varn[i],'colors',col[i]
    options,varn[i],'ytitle','Norm!c' + lab[i]
  endfor
  mvn_swe_engy.sc_pot = sc_pot

; Perform cluster analysis on the normalized data in a moving boxcar.  The idea is to 
; look for changes in the pseudo density that are significantly larger than the standard 
; deviation of the measurements away from the large jumps.

  imin = 0L
  imax = nspec - 1L
  imid = imin + halfwidth  ; midpoint of first boxcar

  lz = replicate(0L,4)
  fz = replicate(0.,4)
  diag = {time:0D, trange:[0D,0D], npts0:lz, avg0:fz, sdev0:fz, skew0:fz, $
          npts1:lz, avg1:fz, sdev1:fz, skew1:fz, delta:fz, frac:fz, vratio:fz, $
          dratio:fz, edge:lz}
  diag = replicate(diag, imax+1L)
  j = 0L

  jnorm = float(nspec - (nstop + 1)*width)/100.
  jp = 0.

  for i=0,nstop do begin

    while (imid le (istop[i]-halfwidth)) do begin

      tmid = ut[imid]
      ilo = imid - halfwidth
      ihi = imid + halfwidth
      tsp = ut[[ilo, ihi]]

;   Calculate 1- and 2-cluster statistics within window

      result1 = 0 & result2 = 0 & result3 = 0 & result4 = 0
      diag1 = 0 & diag2 = 0 & diag3 = 0 & diag4 = 0
;     tmean, varn[0], trange=tmid, npts=width, result=result1, diag=diag1, outlier=outlier, minpts=minpts, $
;                     t0=t0a, t1=t1a, /silent
;     tmean, varn[1], trange=tmid, npts=width, result=result2, diag=diag2, outlier=outlier, minpts=minpts, $
;                     t0=t0b, t1=t1b, /silent
      tmean, varn[0], trange=tmid, npts=width, result=result3, /cluster, diag=diag3, t0=t0c, t1=t1c, /silent
      tmean, varn[1], trange=tmid, npts=width, result=result4, /cluster, diag=diag4, t0=t0d, t1=t1d, /silent

      diag[j].time = tmid
      diag[j].trange = tsp

      if (size(result1,/type) eq 8) then begin  ; outlier analysis (< 6 eV)
        diag[j].npts0[0] = diag1.npts0          ; core
        diag[j].avg0[0]  = result1[0].mean      ; core stats
        diag[j].sdev0[0] = result1[0].stddev
        diag[j].skew0[0] = result1[0].skew
        diag[j].npts1[0] = diag1.npts1          ; outliers
        diag[j].avg1[0]  = !values.f_nan        ; no stats for outliers
        diag[j].sdev1[0] = !values.f_nan
        diag[j].skew1[0] = !values.f_nan
        diag[j].delta[0] = diag1.delta          ; outlier diagnostics
        diag[j].frac[0] = diag1.frac
      endif

      if (size(result2,/type) eq 8) then begin  ; outlier analysis (6-12 eV)
        diag[j].npts0[1] = diag2.npts0          ; core
        diag[j].avg0[1]  = result2[0].mean      ; core stats
        diag[j].sdev0[1] = result2[0].stddev
        diag[j].skew0[1] = result2[0].skew
        diag[j].npts1[1] = diag2.npts1          ; outliers
        diag[j].avg1[1]  = !values.f_nan        ; no stats for outliers
        diag[j].sdev1[1] = !values.f_nan
        diag[j].skew1[1] = !values.f_nan
        diag[j].delta[1] = diag2.delta          ; outlier diagnostics
        diag[j].frac[1] = diag2.frac
      endif

      if (size(result3,/type) eq 8) then begin  ; cluster analysis (< 6 eV)
        diag[j].npts0[2] = diag3.npts0          ; cluster 0
        diag[j].avg0[2]  = result3[0].mean      ; stats for cluster 0
        diag[j].sdev0[2] = result3[0].stddev
        diag[j].skew0[2] = result3[0].skew
        diag[j].npts1[2] = diag3.npts1          ; cluster 1
        diag[j].avg1[2]  = result3[1].mean      ; stats for cluster 1
        diag[j].sdev1[2] = result3[1].stddev
        diag[j].skew1[2] = result3[1].skew
        diag[j].delta[2] = diag3.delta          ; cluster diagnostics
        diag[j].frac[2] = diag3.frac
        diag[j].vratio[2] = diag3.minvar/diag3.maxvar
        diag[j].dratio[2] = result3[0].mean/result3[1].mean
        diag[j].edge[2] = diag3.edge
      endif

      if (size(result4,/type) eq 8) then begin  ; cluster analysis (6-12 eV)
        diag[j].npts0[3] = diag4.npts0          ; cluster 0
        diag[j].avg0[3]  = result4[0].mean      ; stats for cluster 0
        diag[j].sdev0[3] = result4[0].stddev
        diag[j].skew0[3] = result4[0].skew
        diag[j].npts1[3] = diag4.npts1          ; cluster 1
        diag[j].avg1[3]  = result4[1].mean      ; stats for cluster 1
        diag[j].sdev1[3] = result4[1].stddev
        diag[j].skew1[3] = result4[1].skew
        diag[j].delta[3] = diag4.delta          ; cluster diagnostics
        diag[j].frac[3] = diag4.frac
        diag[j].vratio[3] = diag4.minvar/diag4.maxvar
        diag[j].dratio[3] = result4[0].mean/result4[1].mean
        diag[j].edge[3] = diag4.edge
      endif

;   Update the quality flag
;     delta[0] = low energy, outlier analysis
;     delta[1] = high energy, outlier analysis
;     delta[2] = low energy, cluster analysis
;     delta[3] = high energy, cluster analysis
;

      delta = diag[j].delta[2:3]
      ratio = diag[j].vratio[2:3]
      edge = diag[j].edge[2:3]
      frac = diag[j].frac[2:3]
      drat = diag[j].dratio[2:3]
      gud = ((delta gt mindelta) and (ratio lt maxratio) and (drat gt minsup) and (edge gt 1))
      case total(gud) of
        0 : k = -1
        1 : k = where(gud)
        2 : dmax = max(delta,k)
      endcase
      case k of
        0 : begin                             ; low energy band
              if (mobetah) then begin
                if (frac[0] gt 0.5) then begin
                  igud = nn2(ut, t0c, maxdt=maxdt, /valid)
                  ibad = nn2(ut, t1c, maxdt=maxdt, /valid)
                  fbad = 1. - frac[0]
                endif else begin
                  igud = nn2(ut, t1c, maxdt=maxdt, /valid)
                  ibad = nn2(ut, t0c, maxdt=maxdt, /valid)
                  fbad = frac[0]
                endelse
              endif else begin
                if (dark[imid]) then begin
                  igud = nn2(ut, t0c, maxdt=maxdt, /valid)
                  ibad = nn2(ut, t1c, maxdt=maxdt, /valid)
                  fbad = 1. - frac[0]
                endif else begin
                  igud = nn2(ut, t1c, maxdt=maxdt, /valid)
                  ibad = nn2(ut, t0c, maxdt=maxdt, /valid)
                  fbad = frac[0]
                endelse
              endelse
              if (fbad lt maxbad) then begin
                flag[igud] = 2B
                flag[ibad] = 0B
              endif
            end
        1 : begin                             ; high energy band
              igud = nn2(ut, t1d, maxdt=maxdt, /valid)
              ibad = nn2(ut, t0d, maxdt=maxdt, /valid)
              fbad = frac[1]
              if (fbad lt maxbad) then begin
                flag[igud] = 2B
                flag[ibad] = 0B
              endif
            end
        else : ; do nothing
      endcase

;   Slide the boxcar

      imid++
      j++
      pct = float(j)/jnorm
      if (pct gt jp) then begin
        if (blab) then print, cret, pct, format='(a,"  ",i3," % ",$)'
        jp++
      endif
    endwhile

    imid = istop[i] + halfwidth  ; midpoint of first boxcar in next section

  endfor

  if (blab) then print, cret, format='(a,"  100 % ")'

  indx = where(diag.trange[0] gt 1D, count)
  if (count gt 0L) then diag = diag[indx]

; Set quality flag to unity near shadow boundaries.  The buffer zone is asymmetric about the
; shadow boundary because the flux changes more gradually on the dark side of the boundary.

  for j=0,(nstop-1) do begin
    sunset = dd[j] gt 0
    if (sunset) then indx = where((ut ge (tstop[j] - buff[0])) and (ut le (tstop[j] + buff[1])), count) $
                else indx = where((ut ge (tstop[j] - buff[1])) and (ut le (tstop[j] + buff[0])), count)
    if (count gt 0L) then flag[indx] = 1B  ; too close to shadow boundary, so unable to determine quality
  endfor

  tend = systime(/utc,/sec)
  dt = tend - tstart
  print,"Elapsed time (hh:mm:ss): ",strmid(time_string(dt),11)

; Package the result: one quality flag for each SPEC, with parameters used to control processing

  quality = {time:ut, flag:flag, width:width, npts:npts, lambda:lambda, frac:frac, buffer:buff, $
             minpts:minpts, mindelta:mindelta, maxratio:maxratio, minsup:minsup, maxbad:maxbad, $
             mobetah:mobetah, date_processed:tend}

; Make tplot variables for the diagnostics

  if keyword_set(doplot) then begin
    tt = average(diag.trange,1)
    store_data,'cluster_sep',data={x:tt, y:transpose(diag.delta[2:3]), v:[0,1]}
    options,'cluster_sep','ytitle','Cluster Sep'
    options,'cluster_sep','constant',[0.5,mindelta]
    options,'cluster_sep','colors',[4,6]
    options,'cluster_sep','labels',['< 6 eV','6-12 eV']
    options,'cluster_sep','labflag',1
    options,'cluster_sep','datagap',30D
    ylim,'cluster_sep',mindelta,30,1

    store_data,'variance_ratio',data={x:tt, y:transpose(diag.vratio[2:3]), v:[0,1]}
    options,'variance_ratio','ytitle','Variance Ratio'
    options,'variance_ratio','constant',[maxratio]
    options,'variance_ratio','colors',[4,6]
    options,'variance_ratio','labels',['< 6 eV','6-12 eV']
    options,'variance_ratio','labflag',1
    options,'variance_ratio','datagap',30D
    ylim,'variance_ratio',0,maxratio,0

    store_data,'density_ratio',data={x:tt, y:transpose(diag.avg0[2:3]/diag.avg1[2:3]), v:[0,1]}
    options,'density_ratio','ytitle','Density Ratio'
    options,'density_ratio','constant',[0.1,minsup]
    options,'density_ratio','colors',[4,6]
    options,'density_ratio','labels',['< 6 eV','6-12 eV']
    options,'density_ratio','labflag',1
    options,'density_ratio','datagap',30D
    ylim,'density_ratio',0.03,1,1

    if (0) then begin
      store_data,'outlier_sep',data={x:tt, y:transpose(diag.delta[0:1]), v:[0,1]}
      options,'outlier_sep','ytitle','Outlier Sep'
      options,'outlier_sep','constant',[3]
      options,'outlier_sep','colors',[4,6]
      options,'outlier_sep','labels',['< 6 eV','6-12 eV']
      options,'outlier_sep','labflag',1
      options,'outlier_sep','datagap',30D
      ylim,'outlier_sep',1,30,1
    endif

; Update the pseudo-density and energy spectrum panels to show the anomalous points.

    i = where(flag eq 0B, count)

    vname = 'N_hi'
    get_data,vname,data=nhi
    vname += '_bad'
    if (count gt 0L) then store_data,vname,data={x:nhi.x[i], y:nhi.y[i], dy:nhi.dy[i]} $
                     else store_data,vname,data={x:minmax(nhi.x), y:[0.001,0.001]}
    options,vname,'psym',3
    store_data,'N_hi_cmp',data=['N_hi','N_hi_topsmooth','N_hi_bad']
    options,'N_hi_cmp','colors',[!p.color,6,1]

    vname = 'N_lo'
    get_data,vname,data=nlo
    vname += '_bad'
    indx = where(flag eq 0B, count)
    if (count gt 0L) then store_data,vname,data={x:nlo.x[i], y:nlo.y[i], dy:nlo.dy[i]} $
                     else store_data,vname,data={x:minmax(nlo.x), y:[0.001,0.001]}
    options,vname,'psym',3
    store_data,'N_lo_cmp',data=['N_lo','N_lo_topsmooth','N_lo_bad']
    options,'N_lo_cmp','colors',[!p.color,4,1]

    y = replicate(!values.f_nan, nspec)
    if (count gt 0L) then y[i] = 4.4
    store_data,'flag',data={x:ut, y:y}
    options,'flag','psym',7
    options,'flag','colors',0
    options,'flag','symsize',0.6
    store_data,'swe_a4_mask',data=['swe_a4','flag']
    ylim,'swe_a4_mask',3,4627.5,1
  endif

; Set the quality flag in the SPEC, PAD, and 3D data structures

  if keyword_set(setflag) then begin
    i = nn2(mvn_swe_engy.time, quality.time, maxdt=0.25D, /valid, vindex=j, badindex=k)
    mvn_swe_engy[i].quality = quality.flag[j]
    print,"Setting quality flag for SPEC data."

    delta_t = 1.95D/2D  ; start time to center time for PAD and 3D packets

    if (size(a2,/type) eq 8) then begin
      str_element, a2, 'quality', replicate(1B,n_elements(a2.time)), /add
      i = nn2(a2.time + delta_t, quality.time, maxdt=0.6D, /valid, vindex=j, badindex=k)
      a2[i].quality = quality.flag[j]
      print,"Setting quality flag for PAD survey data."
    endif else print,"No PAD survey data.  Cannot set quality flag."

    if (size(a3,/type) eq 8) then begin
      str_element, a3, 'quality', replicate(1B,n_elements(a3.time)), /add
      i = nn2(a3.time + delta_t, quality.time, maxdt=0.6D, /valid, vindex=j, badindex=k)
      a3[i].quality = quality.flag[j]
      print,"Setting quality flag for PAD archive data."
    endif else print,"No PAD archive data.  Cannot set quality flag."

    if (size(swe_3d,/type) eq 8) then begin
      str_element, swe_3d, 'quality', replicate(1B,n_elements(swe_3d.time)), /add
      i = nn2(swe_3d.time + delta_t, quality.time, maxdt=0.6D, /valid, vindex=j, badindex=k)
      swe_3d[i].quality = quality.flag[j]
      print,"Setting quality flag for 3D survey data."
    endif else print,"No 3D survey data.  Cannot set quality flag."

    if (size(swe_3d_arc,/type) eq 8) then begin
      str_element, swe_3d_arc, 'quality', replicate(1B,n_elements(swe_3d_arc.time)), /add
      i = nn2(swe_3d_arc.time + delta_t, quality.time, maxdt=0.6D, /valid, vindex=j, badindex=k)
      swe_3d_arc[i].quality = quality.flag[j]
      print,"Setting quality flag for 3D archive data."
    endif else print,"No 3D archive data.  Cannot set quality flag."
  endif

end

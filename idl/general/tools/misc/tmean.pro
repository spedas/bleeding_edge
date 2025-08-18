;+
;PROCEDURE:   tmean
;PURPOSE:
;  Calculate the mean, median, and standard deviation of a 1-D or 2-D
;  tplot variable over a specified time range.  The variable and time range
;  are selected with the cursor or via keyword.  Skew and kurtosis are also
;  calculated:
;
;    skewness: = 0 -> distribution is symmetric about the maximum
;              < 0 -> distribution is skewed to the left
;              > 0 -> distribution is skewed to the right
;
;    kurtosis: = 0 -> distribution is peaked like a Gaussian
;              < 0 -> distribution is less peaked than a Gaussian
;              > 0 -> distribution is more peaked than a Gaussian
;
;  This routine can optionally perform cluster analysis to divide the data
;  into two groups (Jenks natural breaks optimization).  Statistics are given
;  for each group separately.
;
;USAGE:
;  tmean, var
;
;INPUTS:
;       var:     Tplot variable name or number.  If not specified, determine
;                based on which panel the mouse is in when clicked.
;
;                If the variable has two dimensions in y (time and some other
;                parameter), then you must specify which indices of the second
;                dimension to calculate statistics for.  Data can be either 
;                summed or averaged over the second dimension.  See keywords
;                IND and AVG.
;
;                The variable cannot be compound (list of variables to plot
;                in the same panel).  You must specify which variable in the 
;                list you are interested in.
;
;KEYWORDS:
;       TRANGE:  Use this time range instead of getting it interactively
;                with the cursor.  In this case, you must specify var.
;
;       IND:     If y has two dimensions (time and some other parameter), this
;                keyword specifies the indices of the second dimension to
;                calculate statistics for.  No default.
;
;       AVG:     If IND is set and this keyword is also set, then average over
;                the second dimension.  Otherwise, sum over the second dimension.
;                NaN's are treated as missing data (see MEAN and TOTAL).
;
;       ZERO:    Treat NaN's as zeroes.  This affects the mean but not the sum.
;
;       OFFSET:  Value to subtract from the data before calculating statistics.
;                Default = 0.
;
;       OUTLIER: Ignore values more than OUTLIER sigma from the mean.
;                Default = infinity.
;
;       MINPTS:  If OUTLIER is set, this specifies the minimum number of 
;                points remaining after discarding outliers.  Default = 3.
;
;       CLUSTER: Perform 1-D cluster analysis to separate the data into two
;                groups.  Statistics are calculated for each cluster separately.
;                Diagnostics of the quality of the cluster separation are also
;                provided (see keyword DIAG).  Disables OUTLIER.
;
;       MAXDZ:   Use largest break between clusters near minimum variance
;                to divide the clusters.  Default = 1.
;
;       RESULT:  Named variable to hold the result.
;
;       HIST:    Plot a histogram of the distribution in a separate window.
;
;       KEEP:    Keep the last histogram window open on exit.
;
;       RANGE:   Range of values for the histogram.
;
;       NBINS:   If HIST is set, number of bins in the histogram.
;
;       NPTS:    If this is set, then statistics are calculated for NPTS centered
;                on the time nearest the cursor when clicked (as opposed to 
;                selecting a time range with two clicks).
;
;       DST:     Retain the distribution.  Does not allow compiling multiple
;                results.
;
;       T0:      Times in cluster 0.
;
;       T1:      Times in cluster 1.
;
;       DIAG:    Return outlier and cluster analysis diagnostics:
;                  minvar : minimum total variance for both clusters
;                  maxvar : maximum total variance for both clusters
;                  maxsep : separation between the clusters
;                  sepval : value of optimal separation between the clusters
;                  edge   : distance between sepval and the edge of the distribution
;                  ngud   : number of points in the main distribution
;                  nbad   : number of outliers
;                  delta  : separation* between the core and outliers in SDEV units
;                                             -or-
;                           separation# between the clusters in SDEV units
;                  frac   : fraction of "bad" points (nbad/(nbad+ngud))
;
;                  * separation is the distance between the 2-sigma level of the core
;                    distribution and the closest outlier
;
;                  # separation is the closest distance between the 2-sigma levels of the
;                    clusters
;
;       SILENT:  Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-04-19 08:29:46 -0700 (Fri, 19 Apr 2024) $
; $LastChangedRevision: 32527 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/tmean.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro tmean, var, trange=trange, offset=offset, outlier=outlier, result=result, hist=hist, $
                nbins=nbins, npts=npts, silent=silent, minpts=minpts, dst=dst, cluster=cluster, $
                t0=t0, t1=t1, maxdz=maxdz, diag=diag, keep=keep, ind=dndx, avg=doavg, zero=zero, $
                range=hrange

; Determine if routine is being used without a window server

  xwin = strupcase(!d.name) eq 'X'
  if (~xwin) then begin
    ok = 1
    if (size(var,/type) eq 0) then begin
      print,"% tmean: VAR is required without a window server"
      ok = 0
    endif
    if (n_elements(trange) lt 1) then begin
      print,"% tmean: TRANGE is required without a window server"
      ok = 0
    endif
    if (not ok) then return
    hist = 0  ; disable histogram and variance plots
  endif

; Process keywords

  oflg = keyword_set(outlier)
  blab = ~keyword_set(silent)
  minpts = (n_elements(minpts) eq 0) ? 3 : round(minpts)
  nbins = (n_elements(nbins) eq 0) ? 32 : fix(nbins[0])
  hist = keyword_set(hist)
  keep = keyword_set(keep)
  core = keyword_set(cluster)
  if (core) then oflg = 0  ; disable OUTLIER removal for cluster analysis
  dst = keyword_set(dst)
  if (dst) then undefine, result
  maxdz = (size(maxdz,/type) eq 0) ? 1 : keyword_set(maxdz)
  offset = (size(offset,/type) eq 0) ? 0. : float(offset[0])
  t0 = 0D
  t1 = 0D

  if (n_elements(trange) lt 1) then begin
    if keyword_set(npts) then ctime, tsp, panel=p, npoints=1, prompt='Choose a variable/time' $
                         else ctime, tsp, panel=p, npoints=2, prompt='Choose a variable/time range'
    cursor,cx,cy,/norm,/up  ; make sure mouse button is released
    if (size(tsp,/type) ne 5) then return
  endif else begin
    if (size(var,/type) eq 0) then begin
      print,"Keyword TRANGE requires the tplot variable to be specified."
      return
    endif
    tsp = minmax(time_double(trange))
  endelse

  if (size(var,/type) eq 0) then begin
    tplot_options, get=topt
    var = topt.varnames[p[0]]
  endif

; Make sure variable exists and can be interpreted

  get_data, var, data=dat, alim=lim, index=i
  if (i eq 0) then begin
    print,'Variable not defined: ',var
    return
  endif
  if (size(dat,/type) eq 7) then begin
    print,'Variable "',var,'" is compound: ',dat
    print,'You must specify a single variable.'
    return
  endif
  str_element, dat, 'x', success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  str_element, dat, 'y', success=ok
  if (not ok) then begin
    print,'Cannot interpret variable: ',var
    return
  endif
  ydim = size(dat.y)
  if (ydim[0] gt 2) then begin
    print,'Y has more than 2 dimensions.  Abort!'
    return
  endif
  if (ydim[0] eq 2) then begin
    if (n_elements(dndx) eq 0) then begin
      print,'You must specify indices to sum for the second dimension.'
      return
    endif
    if ((min(dndx) lt 0) || (max(dndx) ge ydim[2])) then begin
      print,'Indices for the second dimension are out of bounds!'
      return
    endif
    dimsum = 1
  endif else dimsum = 0
  doavg = keyword_set(doavg)

  if keyword_set(zero) then begin
    zndx = where(~finite(dat.y), count)
    if (count gt 0L) then dat.y[zndx] = 0.
  endif

; Create plot window(s)

  if (xwin) then begin
    twin = !d.window
    if (hist) then begin
      win, /free, /secondary, xsize=800, ysize=600, dx=10, dy=10
      hwin = !d.window
      if (core) then begin
        win, /free, clone=hwin, relative=hwin, dx=10, /top
        vwin = !d.window
      endif
    endif
  endif

; Select data

  keepgoing = 1

  while (keepgoing) do begin
    result = 0
    diag = 0

    if keyword_set(npts) then begin
      i = nn2(dat.x, tsp[0])
      indx = lindgen(npts) + (i - npts/2)
      j = where((indx ge 0L) and (indx le (n_elements(dat.x)-1L)), ntot)
      if (ntot gt 0L) then begin
        indx = indx[j]
        tmin = min(dat.x[indx], max=tmax)
      endif
    endif else begin
      tmin = min(tsp, max=tmax)
      indx = where((dat.x ge tmin) and (dat.x le tmax), ntot)
    endelse

    if (ntot eq 0L) then begin
      print,"No data within range."
      if (hist) then begin
        wdelete, hwin
        if (core) then wdelete, vwin
      endif
      if (xwin) then wset, twin
      return
    endif

    x = dat.x[indx]
    y = dat.y[indx,*]
    if (dimsum) then begin
      if (n_elements(dndx) gt 1) then begin
        if (doavg) then y = mean(y[*,dndx], dim=2, /nan) $
                   else y = total(y[*,dndx], 2, /nan)
      endif else y = y[*,dndx]
    endif
    y -= offset

    kndx = where(finite(y), ntot)
    if (ntot lt minpts) then begin
      print,"Fewer than ",strtrim(string(minpts),2)," good points."
      if (hist) then begin
        wdelete, hwin
        if (core) then wdelete, vwin
      endif
      if (xwin) then wset, twin
      return
    endif
    if (ntot gt 0L) then begin
      x = x[kndx]
      y = y[kndx]
    endif

    if (hist) then timebar,[tmin,tmax],/transient,line=2

; Group the data into two clusters (Jenks natural breaks optimization)

    if (core) then begin
      z = y[sort(y)]
      nz = n_elements(z)
      avg1 = replicate(!values.f_nan,ntot)
      avg2 = avg1
      var1 = avg1
      var2 = avg1
      for i=2,(ntot-4) do begin            ; minimum of 3 points per cluster
        mom  = moment(z[0:i], maxmoment=2, /nan)
        avg1[i]  = mom[0]
        var1[i]  = mom[1]
        mom  = moment(z[i+1:ntot-1], maxmoment=2, /nan)
        avg2[i]  = mom[0]
        var2[i]  = mom[1]
      endfor

      v = var1 + var2
      dv = v - shift(v,1)
      dv[0] = !values.f_nan
      sign = dv * shift(dv,1)
      sign /= abs(sign)
      indx = where(sign lt 0., count) - 1L  ; local extrema (excludes endpoints)
      if (count eq 0L) then begin
        diag = {minvar: min(v), $
                maxvar: max(v), $
                maxsep: 0.    , $
                sepval: max(z), $
                edge  : 0        }

        if (blab) then print,"Cluster analysis found no local minimum in the variance."
        if (hist && ~keep) then begin
          wdelete, hwin
          if (core) then wdelete, vwin
          wset, twin
        endif
        if (hist) then timebar,[tmin,tmax],/transient,line=2
        return
      endif
      minvar = min(v[indx], j)              ; deepest local minimum
      icut = indx[j]

      if (maxdz) then begin
        dz = z - shift(z,1)
        dz[[0,(nz-1)]] = !values.f_nan
        nj = (nz - icut)/4 > 3
        mdz = max(dz[icut:(icut+nj)], jcut)
        icut += (jcut - 1)
      endif
      ycut = (z[icut] + z[icut+1])/2.
      edge = min([icut-1, nz-icut-4])
      nclusters = 2

      diag = {minvar: minvar , $
              maxvar: max(v) , $
              maxsep: mdz    , $
              sepval: ycut   , $
              edge  : edge      }

    endif else begin
      icut = ntot - 1  ; put all points into cluster 0
      ycut = max(y)
      nclusters = 1

      if (oflg) then diag = {outlier:outlier[0], minpts:minpts} else diag = {outlier:1000.}
    endelse

; Calculate the mean and standard deviation within requested time range

    for i=0,(nclusters-1) do begin
      if (i eq 0) then begin
        j = where(y le ycut, count)
        xc = x[j]
        yc = y[j]
        t0 = xc
      endif else begin
        j = where(y gt ycut, count)
        xc = x[j]
        yc = y[j]
        t1 = xc
      endelse

      mom  = moment(yc, mdev=adev, /nan)
      avg  = mom[0]
      rms  = sqrt(mom[1])

      if (oflg) then begin                  ; remove outliers (only for nclusters = 1)
        xo = [-1D]
        yo = [-1.]
        maxdev = float(outlier[0])*rms
        jndx = where(abs(yc - avg) le maxdev, ngud, complement=kndx, ncomplement=nbad)
        while ((nbad gt 0) and (ngud ge minpts)) do begin
          xo = [xo, xc[kndx]]
          yo = [yo, yc[kndx]]
          xc = xc[jndx]
          yc = yc[jndx]
          mom  = moment(yc, mdev=adev, /nan)
          avg  = mom[0]
          rms  = sqrt(mom[1])
          maxdev = float(outlier[0])*rms
          jndx = where(abs(yc - avg) le maxdev, ngud, complement=kndx, ncomplement=nbad)
        endwhile
        nbad = n_elements(xo) - 1L
        ngud = n_elements(xc)
        if (nbad ge 1L) then begin
          xo = xo[1:*]
          yo = yo[1:*]
          delta = min((yo - avg)/rms, /abs)
          frac = float(n_elements(xo))/float(ngud+nbad)
        endif else begin
          delta = 0.
          frac = 0.
        endelse
        t0 = xc
        t1 = xo
      endif else begin
        delta = 0.
        frac = 0.
      endelse

      skew = mom[2]
      kurt = mom[3]
      med  = median([yc])
      lim = minmax([yc])

; Report the result

      tmp = {varname : var            , $
             cluster : i              , $
             time    : mean(xc)       , $
             trange  : [tmin, tmax]   , $
             offset  : offset         , $
             lim     : lim            , $
             median  : med            , $
             mean    : avg            , $
             stddev  : rms            , $
             rerr    : abs(rms/avg)   , $
             skew    : skew           , $
             kurt    : kurt           , $
             npts    : n_elements(yc)    }

      if (dst) then str_element, tmp, 'y', yc, /add

      str_element, result, 'varname', success=ok
      if (ok) then result = [result, tmp] else result = tmp

      if (blab) then begin
        print,"Cluster  : ",strtrim(string(i),2)
        print,"Variable : ",var
        print,"  ",time_string(tmin)," --> ",strmid(time_string(tmax),11)
        print,"  # points : ",n_elements(yc)
        print,"  Offset   : ",offset
        print,"  Minimum  : ",lim[0]
        print,"  Maximum  : ",lim[1]
        print,"  Median   : ",med
        print,"  Average  : ",avg
        print,"  Stddev   : ",rms
        print,"  Rel Err  : ",abs(rms/avg)
        print,"  Skew     : ",skew
        print,"  Kurtosis : ",kurt
        print,""
      endif
    endfor

; More diagnostic information

    if (core) then begin
      str_element, diag, 'npts0', result[0].npts, /add
      str_element, diag, 'npts1', result[1].npts, /add
      z0 = result[0].mean + 2.*result[0].stddev
      z1 = result[1].mean - 2.*result[1].stddev
      delta = (z1 - z0)/max(result.stddev)
      str_element, diag, 'delta', delta, /add
      frac = float(result[0].npts)/float(result[0].npts + result[1].npts)
      str_element, diag, 'frac', frac, /add
      if (blab) then begin
        msg = strtrim(string(ycut, format='(f14.2)'),2)
        print,"Clusters divide at: ",msg,format='(a,a)'
        msg = strtrim(string(diag.edge, format='(i14)'),2)
        print,"Distance from edge: ",msg,format='(a,a)'
        msg = strtrim(string(diag.delta, format='(f14.2)'),2)
        print,"Cluster separation: " + msg + " sigma"
        msg = strtrim(string(result[0].mean/result[1].mean, format='(f14.2)'),2)
        print,"Cluster center ratio: " + msg
        msg = strtrim(string(diag.minvar/diag.maxvar, format='(f14.2)'),2)
        print,"Variance improvement: " + msg
        msg = strtrim(string(diag.frac,format='(f14.2)'),2)
        print,"N(cluster 0)/N(total): ",msg,format='(a,a,/)'
      endif
    endif
    if (oflg) then begin
      str_element, diag, 'npts0', ngud, /add   ; core points -> npts0
      str_element, diag, 'npts1', nbad, /add   ; outliers -> npts1
      str_element, diag, 'delta', delta, /add  ; delta is signed
      str_element, diag, 'frac', frac, /add
      if (blab) then begin
        print,strtrim(string(diag.npts0,format='(i)'),2) + ' core points'
        print,strtrim(string(diag.npts1,format='(i)'),2) + ' outliers'
        msg = strtrim(string(diag.delta, format='(f14.2)'),2)
        print,"Outlier separation: ", msg + " sigma"
        msg = strtrim(string(diag.frac,format='(f14.2)'),2)
        print,"N(outlier)/N(core): ",msg,format='(a,a,/)'
      endif
    endif

; Plot the distribution

    if (hist) then begin
      if (core) then begin
        wset, vwin
        z0 = result[0].mean + 2.*result[0].stddev
        z1 = result[1].mean - 2.*result[1].stddev
        msg = strtrim(string((z1 - z0)/result[1].stddev, format='(f14.2)'),2)
        vtitle = 'Cluster Separation: ' + msg + " !4r!1H"
        plot,z,(var1+var2),psym=-4,xtitle=var,ytitle='Total Variance',charsize=1.8,title=vtitle
        oplot,[ycut,ycut],[0.,2.*max(var1+var2)],line=2,color=6
      endif
      wset, hwin
      yrange = minmax(y)
      if (n_elements(hrange) ge 2) then range = minmax(hrange) else range = yrange
      dy = (yrange[1] - yrange[0])/float(nbins)
      h = histogram(y, binsize=dy, loc=hy, min=range[0], max=range[1])
      title = 'N = ' + strtrim(string(round(total(h))),2)

      hy = [min(hy)-dy, hy, max(hy) + dy]  ; complete drawing of first and last bins
      h  = [0, h, 0]

      plot,hy,h,psym=10,charsize=1.8,xtitle=var,ytitle='Sample Number',title=title,_extra=extra
      for i=1,5 do begin
        oplot,[avg,avg]+(i*rms),[0,2.*max(h)],linestyle=1,color=4
        oplot,[avg,avg]-(i*rms),[0,2.*max(h)],linestyle=1,color=4
      endfor
      ; oplot,[med,med],[0,2.*max(h)],linestyle=2,color=6

      if (oflg) then begin
        msg = strtrim(string(ngud,format='(i)'),2) + ' core points'
        xyouts,0.18,0.88,/norm,msg,charsize=1.4
        msg = strtrim(string(nbad,format='(i)'),2) + ' outliers'
        xyouts,0.18,0.83,/norm,msg,charsize=1.4
        msg = 'skew = ' + strtrim(string(result[0].skew,format='(f14.2)'),2)
        xyouts,0.18,0.78,/norm,msg,charsize=1.4
      endif

      if (core) then begin
        oplot,[ycut,ycut],[0,2.*max(h)],linestyle=2,color=6
        fcol = 1  ; color for cluster 1
        avg = result[1].mean
        rms = result[1].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        j = where(hy gt ycut)
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h[j])/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2
        msg = strtrim(string(1.-diag.frac,format='(f14.2)'),2)
        xyouts,(avg+rms/2.),max(s*f)*0.95,msg,color=fcol,charsize=1.5

        fcol = 4  ; color for cluster 0
        avg = result[0].mean
        rms = result[0].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        j = where(hy lt ycut)
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h[j])/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2
        msg = strtrim(string(diag.frac,format='(f14.2)'),2)
        xyouts,(avg+rms/2.),max(s*f)*0.95,msg,color=fcol,charsize=1.5
      endif else begin
        fcol = 1
        avg = result[0].mean
        rms = result[0].stddev
        oplot,[avg,avg],[0,2.*max(h)],linestyle=2,color=fcol
        x = range[0] + (dy/10.)*findgen(nbins*10 + 1)
        f = exp(-(x - avg)^2./(2.*rms*rms))/sqrt(2.*!pi*rms*rms)
        s = 10.*total(h)/total(f) ; equal areas
        oplot,x,s*f,color=fcol,thick=2
      endelse

      wset, twin
    endif

; Get the next time range

    if (n_elements(trange) lt 1) then begin
      if keyword_set(npts) then ctime, tsp, panel=p, npoints=1, prompt='Choose a variable/time' $
                           else ctime, tsp, panel=p, npoints=2, prompt='Choose a variable/time range'
      cursor,cx,cy,/norm,/up  ; make sure mouse button is released
      if (size(tsp,/type) ne 5) then keepgoing = 0
    endif else keepgoing = 0

    if (hist) then timebar,[tmin,tmax],/transient,line=2

  endwhile

  if (hist && ~keep) then begin
    wdelete, hwin
    if (core) then wdelete, vwin
  endif
  if (xwin) then wset, twin

end

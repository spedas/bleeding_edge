;+
;PROCEDURE:   mvn_sta_cio_snap
;PURPOSE:
;  Makes plots of statistics within individual pixels in maps created with
;  mvn_sta_cio_plot.
;
;USAGE:
;  mvn_sta_cio_snap, data
;
;INPUTS:
;       data:       A data structure returned by mvn_sta_cio_plot.
;
;KEYWORDS:
;       KEEP:       Keep the last snapshot window on exit.
;
;       RESULT:     Structure to hold the last distribution on exit.
;
;       RANGE:      Range for binning the data.  Default = minmax(data).
;
;       NBINS:      Number of bins.  Default = 30.
;
;       LPOS:       Legend position [X,Y], relative coordinates.
;
;       ALLSTAT:    Include skewness and kurtosis in legend.
;
;       CONSTANT:   Plot a vertical dashed line at this position.
;                   Sets NOLINES = 1.
;
;       CLABEL:     Labels across the top for each element of CONSTANT.
;
;       NOLINES:    Do not plot lines for mean and median.
;
;       This routine also passes keywords to PLOT.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-04-07 15:27:02 -0700 (Mon, 07 Apr 2025) $
; $LastChangedRevision: 33238 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_snap.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_snap.pro
;-
pro mvn_sta_cio_snap, data, keep=keep, result=result, range=range, nbins=nbins, lpos=lpos, $
                      allstat=allstat, nostat=nostat, constant=constant, nolines=nolines, $
                      clabel=clabel, _extra=extra

  result = 0
  str_element, data, 'x', success=ok
  if (ok) then str_element, data, 'y', success=ok
  if (not ok) then begin
    print, "Can't interpret input data structure."
    return
  endif

  dorange = n_elements(range) eq 2
  if (dorange) then range = range(sort(range))
  dostat = ~keyword_set(nostat)
  doline = ~keyword_set(nolines)
  maxcst = n_elements(constant) - 1
  if (maxcst ge 0) then doline = 0
  label = replicate(' ',(maxcst+1) > 1)
  if (size(clabel,/type) eq 7) then begin
    maxlab = n_elements(clabel) - 1
    label[0:(maxlab < maxcst)] = clabel[0:(maxlab < maxcst)]
  endif
  if not keyword_set(nbins) then nbins = 30
  str_element, data, 'z', success=pmode
  if (pmode) then str_element, data, 'avg', data.z, /add $
             else str_element, data, 'avg', data.y, /add

  case n_elements(lpos) of
     0   : lpos = [0.70, 0.85]
     1   : lpos = [lpos, 0.85]
    else : lpos = lpos[0:1]
  endcase

; Remember the graphics settings of the original plot

  pwin = !d.window
  xsys = !x
  ysys = !y
  zsys = !z
  psys = !p

; Make a new window, if necessary, to hold the snapshot

  if (not execute('wset,29',2,1)) then $
    win, 29, xsize=700, ysize=500, relative=pwin, dx=10, /middle
  swin = !d.window

; Get a point on the original plot

  ok = 1
  wset, pwin
  crosshairs, cx, cy, /nolegend, /silent, /oneclick, lastbutton=button
  if (button eq 4) then ok = 0

  while (ok) do begin
    dx = min(abs(data.x - cx), i)
    xi = data.x[i]
    if (pmode) then begin
      dy = min(abs(data.y - cy), j)
      yj = data.y[j]
      z = reform(data.dist[i,j,*])
      indx = where(finite(z), count)
      valid = data.valid[i,j]
      xtitle = data.zvar
      ij = i + n_elements(data.x)*j
    endif else begin
      z = reform(data.dist[i,*])
      indx = where(finite(z), count)
      valid = data.valid[i]
      xtitle = data.yvar
      ij = i
    endelse

; Put up a snapshot in the new window

    wset, swin

    if ((count gt 0) and valid) then begin
      if (not dorange) then range = minmax(z[indx])
      dz = (range[1] - range[0])/float(nbins)
      h = histogram(z[indx], binsize=dz, loc=hz, min=range[0], max=range[1])
      htop = sigfig(1.2*max(h),2)

      plot,hz,h,psym=10,charsize=1.8,xtitle=xtitle,ytitle='Sample Number', $
           yrange=[0,htop], /ysty, _extra=extra
      hz = [hz[0] - dz, hz, max(hz) + dz]
      h = [0., h, 0.]
      result = {x:hz, y:h, dx:dz, npts:data.npts[ij], mean:data.avg[ij], $
                median:data.med[ij], skew:data.skew[ij], kurt:data.kurt[ij]}
    
      oplot,hz,h,psym=10

      for k=0,maxcst do begin
        x = [constant[k], constant[k]]
        y = [0., htop]
        oplot, x, y, linestyle=2
        xyouts, constant[k], htop*1.02, clabel[k], align=0.5, charsize=1.4
      endfor

      mx = lpos[0]
      my = lpos[1]
      mdy = 0.05

      if (pmode) then msg = string(xi,yj,format='("[X,Y] = [",f5.2,", ",f5.2,"]")') $
                 else msg = string(xi,format='("X = ",f5.2)')
      xyouts, mx, my, /norm, msg, charsize=1.5
      my -= mdy

      if (dostat) then begin
        if (doline) then begin
          oplot,[data.avg[ij],data.avg[ij]],[0,10*max(h)],color=6,linestyle=2
          oplot,[data.med[ij],data.med[ij]],[0,10*max(h)],color=2,linestyle=2
        endif

        msg = strcompress(string(data.npts[ij],format='("Samples = ",i8)'))
        xyouts, mx, my, /norm, msg, charsize=1.5
        my -= mdy
        msg = strcompress(string(data.med[ij],format='("Median = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5, color=2
        my -= mdy
        msg = strcompress(string(data.avg[ij],format='("Mean = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5, color=6
        my -= mdy
        msg = strcompress(string(data.sdev[ij],format='("Std Dev = ",g8.3)'))
        xyouts, mx, my, /norm, msg, charsize=1.5
        my -= mdy      
        if keyword_set(allstat) then begin
          msg = strcompress(string(data.skew[ij],format='("Skewness = ",g8.3)'))
          xyouts, mx, my, /norm, msg, charsize=1.5
          my -= mdy
          msg = strcompress(string(data.kurt[ij],format='("Kurtosis = ",g8.3)'))
          xyouts, mx, my, /norm, msg, charsize=1.5
          my -= mdy
        endif
      endif
    endif else begin
      erase
      xyouts, 0.5, 0.5, /norm, "No Data", charsize=3.0, align=0.5, charthick=2
    endelse

; Restore the original graphics settings and get the next point

    wset, pwin
    !x = xsys
    !y = ysys
    !z = zsys
    !p = psys

    crosshairs, cx, cy, /nolegend, /silent, /oneclick, lastbutton=button, /lastpoint
    if (button eq 4) then ok = 0

  endwhile

  if ~keyword_set(keep) then wdelete, swin

; Reassert original graphics settings

  wset, pwin
  !x = xsys
  !y = ysys
  !z = zsys
  !p = psys

  return

end

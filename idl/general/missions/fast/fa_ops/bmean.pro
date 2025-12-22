;	@(#)bmean.pro	1.4	04/17/03
;+
; BMEAN - plots the mean of y in a set of x bins.
;
;    I believe all the keywords that can be passed to HISTOGRAM can
;  also be passed to BMEAN. By default, BMEAN makes a plot with an
;  error bar, you can use NO_PLOT and/or NO_ERROR to avoid this. 
; 
; OTHER KEYWORDS: 
;
;   MEDIAN - comupute binned median instead of mean
;
;   TOTAL - don't divide by number of points per bin!
;
;   XRANGE - the [min, max] xvalues to consider in the binning. 
;
;   M**_YVALUE - The min and max y values to consider in the mean,
;                median or total. 
;
;   YRANGE - the range of y to *plot*. Y's outside this range will
;            still be used in the calculation. 
;
;   BMEAN, SIGMA, NPTS - named variables for returning "the answer",
;                        the error bar, and the number of points per
;                        bin, respectively.
;
;   
; 
;-

pro bmean, x, y, BINSIZE =  binsize, XRANGE = xrange, YRANGE = yrange, $
           NAN = nan, OMAX = omax, OMIN = omin, $
           REVERSE_INDICES = rev, XBINS = bins, $
           _EXTRA = extra, NO_PLOT = no_plot, $
           SIGMA = sigma, NO_ERROR = no_error, NPTS = npts,  $
           MEDIAN = median, BMEAN = ym, SHOW_NUMBERS = show_numbers, $
           MAX_YVALUE = maxy, MIN_YVALUE = miny, MINPTS = minpts, $
           SCATTER = scatter, TOTAL = total, MAX_IN_BIN = max_in_bin, $
           MAXDEX = maxdex


if not defined(xrange) then xrange = var_range(x) 
if not defined(miny) then miny = min(y, /nan)
if not defined(maxy) then maxy = max(y, /nan)

fin = where(finite(x) and finite(y) and (y ge miny) and (y le maxy), nfin)
if nfin eq 0 then begin
    message, 'No finite data in range....',/continue
    return
endif

hist, x[fin], BINSIZE =  binsize, INPUT = input,  MAX = xrange[1], $
  MIN = xrange[0], /NAN, OMAX = omax, OMIN = omin, $
  REVERSE_INDICES = rev, XBINS = bins, $
  HISTOGRAM = npts, /no_plot, $
  SIGMA = sigma

nbins = n_elements(bins)
ym = make_array(type = data_type(y), nbins, value=!values.f_nan)
sigma = ym 
if keyword_set(max_in_bin) then maxdex = lonarr(nbins)

if not defined(minpts) then minpts = 3
for i=0,nbins-1l do begin
    if npts[i] gt minpts then begin
        pick = fin[rev[rev[i]:rev[i+1L]-1L]]
        yp = y[pick]
        if not keyword_set(median) then begin
            if keyword_set(max_in_bin) then begin
                ym[i] = max(yp, /nan, mxi)
                maxdex[i] = pick[mxi]
            endif else begin
                ym[i] = total(yp)/float(npts[i])
            endelse
            sigma[i] = sqrt(total((yp - ym[i])^2)/float(npts[i]))
        endif else begin
            ym[i] = median(yp)
            sigma[i] = median(abs(yp - ym[i]))/2.
        endelse
    endif
endfor

if keyword_set(total) then begin
    if keyword_set(median) then begin
        message,'Which do you want, the median or the ' + $
          'total?',/continue
        return
    endif
    ym = ym * npts
    sigma = sigma * sqrt(npts)
endif

if not defined(yrange) then yrange = var_range([ym+sigma*2.,ym-sigma*2.])
if not keyword_set(no_plot) then begin
    plot, bins, ym, psym=10, _EXTRA = extra, xrange = xrange, yrange = $
      yrange
    oplot,bins[0]+[-binsize/2.,0],[ym[0],ym[0]]
    oplot,bins[nbins-1l]+[binsize/2.,0],[ym[nbins-1l],ym[nbins-1l]]
    
    if not keyword_set(no_error) then begin
        oploterr, bins, ym, sigma
    endif
    
    if keyword_set(show_numbers) then begin
        offset = max(ym,/nan)/50.
        if not keyword_set(no_error) then offset = offset + sigma
        xyouts,bins,ym+offset,str(npts),align=0.5,_extra=extra
    endif
    
    if keyword_set(scatter) then oplot, x[fin], y[fin], psym=3

endif


return
end

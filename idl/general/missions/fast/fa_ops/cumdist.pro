;	@(#)cumdist.pro	1.2	04/29/99
;+
; plots a cumulative distribution of DATA. Many keywords in common
; with other HISTOGRAM functions.
;-

pro cumdist, data, BINSIZE = binsize, $
             MAX = max, MIN = min, NAN = nan, $
             REVERSE_INDICES = reverse_indices, $
             SIGMA = cdsig, NO_ERROR = no_error, _extra = e , $
             XBINS = xbins, CUMDIST = cd, NO_PLOT = no_plot
             
hist, data, xbins = xbins, hist = hist, /no_plot, BINSIZE = binsize, $
  MAX = max, MIN = min, NAN = nan, REVERSE_INDICES = reverse_indices, $
  SIGMA = sigma, NO_ERROR = no_error 

cd = int_up_to(xbins, hist)
norm = float(cd(n_elements(xbins)-1l))
cd = cd / norm

cdsig = sqrt(int_up_to(xbins, sigma^2)+ 1./norm) / norm

if not keyword_set(no_plot) then begin
    plot, xbins, cd, _extra = e
    if not keyword_set(no_error) then oploterr, xbins, cd, cdsig
endif
return
end


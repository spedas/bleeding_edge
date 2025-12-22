;	@(#)finish_hist.pro	1.2	02/17/99
pro finish_hist, bins, hist, _extra = extra

binsize = bins[1] - bins[0]
nbins = n_elements(bins)

first = min(where(finite(bins) and finite(hist)),/nan,max=last)
b0 = bins[first]
b1 = bins[last]
h0 = hist[first]
h1 = bins[last]

oplot, bins[0] - [0., 0.5]*binsize, [1,1]*hist[0], _extra = extra
oplot, bins[nbins-1l] + [0.,0.5]*binsize, [1,1]*hist[nbins-1l], $
  _extra = extra
oplot, bins[0] - [0.5, 0.5]*binsize, [0,1]*hist[0], _extra = extra
oplot, bins[nbins-1l] + [0.5,0.5]*binsize, [0.,1.]*hist[nbins-1l], $
  _extra = extra
return
end


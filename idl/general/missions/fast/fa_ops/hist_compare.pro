;	@(#)hist_compare.pro	1.9	03/17/99
;+
;  Compares the histograms of X1 and X2. Accepts all HISTOGRAM and
;  PLOT keywords, and some others. 
;
pro hist_compare, x1, x2, _extra = e, xlegend=xlegend,  $
                  ylegend=ylegend, no_error = no_error,  $
                  sigma1 = sig1, sigma2 = sig2, hist1 = hist1, $
                  hist2 = hist2, xbins = bins1, label1 = label1, $
                  label2 = label2, label3 = label3,  $
                  xlabel3 =xlabel3, ylabel3 = ylabel3,  $
                  no_legend = no_legend, binsize = binsize, $
                  no_plot = no_plot

;
; BINSIZE comes in explicitly from outside HIST_COMPARE, or if not,
; it's defined in first call to HIST. Since second call to HIST uses
; first call's OMIN and OMAX as it's MIN and MAX, the bins from the
; two histograms will be identical.
;

hist, x1, /no_plot, _extra = e, hist = hist1, xbin = bins1,  $
  binsize=binsize, omin = min, omax = max, nan = nan
hist, x2, /no_plot, _extra = e, hist = hist2, xbin = bins2, $
  binsize=binsize, min = min, max = max, nan = nan

d1 = float(hist1)/total(hist1)
d2 = float(hist2)/total(hist2)

if defined(e) then begin
    eplot = e
    trim_structure, eplot, ['min','max'], /hack
endif

sig1 = d1 * sqrt(1./hist1 + 1./total(hist1))
sig2 = d2 * sqrt(1./hist2 + 1./total(hist2))

if keyword_set(no_plot) then begin
    message,'Not plotting...',/continue
    return
endif


plot,bins1,d1, xrange = var_range([bins1, bins2]), $
  yrange = var_range([d1+sig1, d2+sig2]), psym=10, _extra = eplot
finish_hist, bins1,d1

oplot,bins2,d2,psym=10, linestyle = 2, thick = 2
finish_hist,bins2,d2, linestyle = 2, thick = 2

if not keyword_set(no_error) then begin
    oploterr,bins1+(bins1[1]-bins1[0])/6.,d1, sig1
    oploterr,bins2-(bins1[1]-bins1[0])/6.,d2, sig2
endif

delta_x = !x.crange[1] - !x.crange[0]
delta_y = !y.crange[1] - !y.crange[0]

if not defined(xlegend) then xlegend = 0.8 * delta_x + !x.crange[0]
if not defined(ylegend) then ylegend = 0.8 * delta_y + !y.crange[0]

if not defined(label1) then label1 = str(long(total(hist1)))+' points'
if not defined(label2) then label2 = str(long(total(hist2)))+' points'

if not keyword_set(no_legend) then begin
    xyouts, xlegend, ylegend+0.05*delta_y, '__ '+ $
      label1,/data
    xyouts, xlegend, ylegend-0.05*delta_y,  '... ' + $
      label2,/data
endif

if not defined(xlabel3) then xlabel3 = 0.2 * delta_x + !x.crange[0]
if not defined(ylabel3) then ylabel3 = 0.8 * delta_y + !y.crange[0]

if defined(label3) then xyouts, xlabel3, ylabel3, label3

return
end

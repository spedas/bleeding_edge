;+
; compare cumulative distributions of X1 and X2. 
;-
pro cumdist_compare, x1, x2, _extra = e, xlegend=xlegend,  $
                  ylegend=ylegend, no_error = no_error,  $
                  sigma1 = sig1, sigma2 = sig2, cumdist1 = cumdist1, $
                  cumdist2 = cumdist2, xbins = bins1, label1 = label1, $
                  label2 = label2, label3 = label3,  $
                  xlabel3 =xlabel3, ylabel3 = ylabel3,  $
                  no_legend = no_legend, binsize = binsize

cumdist, x1, /no_plot, _extra = e, cumdist = cumdist1, xbin = bins1,  $
  binsize=binsize, omin = min, omax = max, nan = nan, sigma = sig1
cumdist, x2, /no_plot, _extra = e, cumdist = cumdist2, xbin = bins2, $
  binsize=binsize, min = min, max = max, nan = nan, sigma = sig2

if defined(e) then begin
    eplot = e
    trim_structure, eplot, ['min','max'], /hack
endif

plot,bins1,cumdist1, xrange = var_range([bins1, bins2]), $
  yrange = var_range([cumdist1+sig1, cumdist2+sig2]), psym=10, _extra = eplot

oplot,bins2,cumdist2,psym=10, linestyle = 2, thick = 2
if not keyword_set(no_error) then begin
    oploterr,bins1+(bins1[1]-bins1[0])/6.,cumdist1, sig1
    oploterr,bins2-(bins1[1]-bins1[0])/6.,cumdist2, sig2
endif

delta_x = !x.crange[1] - !x.crange[0]
delta_y = !y.crange[1] - !y.crange[0]

if not defined(xlegend) then xlegend = 0.8 * delta_x + !x.crange[0]
if not defined(ylegend) then ylegend = 0.8 * delta_y + !y.crange[0]

if not defined(label1) then label1 = str(n_elements(x1))+' points'
if not defined(label2) then label2 = str(n_elements(x2))+' points'

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

;+
; NAME: HIST_NORM
;
; PURPOSE: To compute and plot a normalized histogram. By default, a
;          plot with error bars is made. 
;
; INPUTS: DATA - the stuff you want to histogram
;       
; KEYWORD PARAMETERS: HIST_NORM takes all the keywords of IDL
;                     HISTOGRAM. Keywords accepted by PLOT, such as
;                     titles and the like, may also be
;                     passed. HIST_NORM also has these keywords:
;
;         CONDITION - A byte array, of the same size as DATA, which is
;                     either 1 (true) or 0 (false). The histogram of
;                     those elements of DATA where CONDITION is 1 is
;                     divided by the histogram of all elements of
;                     DATA, to form a normalized histogram. CONDITION
;                     must be defined, otherwise calling HIST_NORM
;                     makes no sense.
;
;         COMPLEMENT - if set, causes the histogram where CONDITION is
;                      true to be normalized by the histogtram where
;                      CONDITION is false. 
;
;         XBINS - named variable in which the bin centers can be
;                 returned. 
;
;         NO_PLOT - if set, inhibits display of the normalized
;                   histogram
;
;         NPOINTS - The minimum number of points per bin for which the
;                   normalized histogram is considered computed. The
;                   default is 0.
;
;         SHOW_NUMBERS - if set, causes the number of points per bin
;                        to be displayed on the histogram plot. 
;
;         NO_ERROR - if set, inhibits the display of error bars. 
;
;         SIGMA - a named variable in which the bin standard
;                 deviations can be returned.
;
; EXAMPLE: hist_norm, density, condition = (wavepower gt .001), $
;             title='Density dependence of wave power'
;
;    This will show the likelihood of wave power greater than .001, as
; a function of density. 
;
; MODIFICATION HISTORY: Written in early 1999, by Bill Peria
;
;-
;       @(#)hist_norm.pro       1.9     04/12/99
pro hist_norm, data, BINSIZE =  binsize,  MAX = max, $
               MIN = min, NAN = nan, OMAX = omax, OMIN = omin, $
               REVERSE_INDICES = reverse_indices, XBINS = bins, $
               _EXTRA = extra, HISTOGRAM = dist, NO_PLOT = no_plot, $
               CONDITION = condition, NPOINTS = npoints, $
               SHOW_NUMBERS = show_numbers, NO_ERROR = no_error, $
               SIGMA = sigma, COMPLEMENT = complement

if n_elements(condition) ne n_elements(data) then begin
    message,'condition array and data are not the same ' + $
      'size...',/continue
    help,data,condition
    return
endif

if not defined(npoints) then npoints = 0

pick = where(condition, npick)
if npick eq 0 then begin
    message,'Condition is never met...',/continue
    return
endif

legal_oplot_tags = ['clip','color','linestyle','noclip','psym', $
                    'subtitle','symsize','t3d','zvalue', $
                    'max_value','min_value','nsum','polar','thick']

if not keyword_set(complement) then begin
    nnpick = n_elements(data)
    non_pick = lindgen(nnpick)
endif else begin
    non_pick = where(condition eq 0, nnpick)
    if nnpick eq 0 then begin
        message,'Condition is always met...no complement!',/continue
        return
    endif
endelse

hist, data[pick], BINSIZE =  binsize,  MAX = max, $
  MIN = min, NAN = nan, OMAX = omax, OMIN = omin, $
  REVERSE_INDICES = reverse_indices, XBINS = bins, $
  HISTOGRAM = hist, /no_plot

hist, data[non_pick], BINSIZE =  binsize,  MAX = omax, $
  MIN = omin, NAN = nan, $
  HISTOGRAM = norm, /no_plot

ok = where((norm ne 0) and (hist gt npoints), nok)
if nok eq 0 then begin
    message,'Not enough points per bin, ever!',/continue
    return
endif

dist = float(hist - hist)
sigma = float(hist - hist)
dist[ok] = float(hist[ok])/float(norm[ok])
sigma[ok] = dist[ok] *sqrt(1./hist[ok] + $
                           1./norm[ok])

empty = where(norm le npoints, nempty)
if nempty gt 0 then dist[empty] = !values.f_nan

if not keyword_set(no_plot) then begin
    if not defined(yrange) then yrange = [0,max(dist+sigma, /nan)*1.1]
    plot, bins, dist, _extra = extra, psym=10, yrange=yrange
    if defined(extra) then begin
        o_extra = extra
        trim_structure, o_extra, legal_oplot_tags, /keep, /quiet
    endif
    finish_hist, bins, dist, _extra = o_extra
    
    if not keyword_set(no_error) then begin
        oploterr,bins,dist,sigma
    endif
    
    if keyword_set(show_numbers) then begin
        offset = max(dist,/nan)/50.
        if not keyword_set(no_error) then offset = offset + sigma
        xyouts,bins,dist+offset,str(norm),align=0.5,_extra=extra
    endif
endif



return
end

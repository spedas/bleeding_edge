;	@(#)hist.pro	1.7	04/22/03
;+
; NAME: HIST
;
; PURPOSE: To actually produce a histogram plot. This is a radical
;          departure from the IDL HISTOGRAM function, which is for
;          something else, as far as anyone can tell. The default
;          binsize is set such that the middle two quartiles of the
;          data land in five bins.
;
; CALLING SEQUENCE: hist, my_data
;
; INPUTS: MY_DATA - an array of numerical values. Can be multi-D, but
;         can't be complex. 
;       
; KEYWORD PARAMETERS: Everything you can pass to IDL's HISTOGRAM
;                     function can be passed to HIST. Also, any
;                     keyword accepted by the PLOT procedure will be
;                     passed thru as well. In addition to that, HIST
;                     has these keywords:
;
;                     XBINS - a named variable in which the centers of
;                             the histogram bins can be returned to
;                             the caller.
;
;                     HIST - a named variable in which the histogram
;                            itself can be returned. 
;
;                     SIGMA - Error bar for the bins...sqrt(hist)
;
;                     NO_PLOT - if set, the histogram is not
;                               plotted. By default, a plot is made. 
;
;                     NO_ERROR - if set, prevents error bars from
;                                being drawn on the plot.
;
;                     QUIET - suppresses some warnings
; 
;                    
; SIDE EFFECTS: The amount of redundant coding when looking at
;               histograms is drastically reduced. 
;
; EXAMPLE: To see how SOME_DATA are distributed, using a text-only
;          terminal at 300 Baud, do this: 
;
;           hist, some_data, /no_plot, xbins = bins, hist = hist 
;           for i=0,n_elements(bins)-1 do print,bins[i],hist[i]
;
; MODIFICATION HISTORY: written about 10 years late, by Bill Peria. 
;
;-


pro hist, data, BINSIZE =  binsize, INPUT = input,  MAX = max, $
          MIN = min, NAN = nan, OMAX = omax, OMIN = omin, $
          REVERSE_INDICES = reverse_indices, XBINS = bins, $
          _EXTRA = extra, HISTOGRAM = dist, NO_PLOT = no_plot, $
          SIGMA = sigma, NO_ERROR = no_error, FORCE_BINSIZE = force, $
          NORMALIZE = normalize, QUIET = quiet

legal_oplot_tags = ['clip','color','linestyle','noclip','psym', $
                    'subtitle','symsize','t3d','zvalue', $
                    'max_value','min_value','nsum','polar','thick']

quiet = keyword_set(quiet)

if not defined(data) then begin
    if not quiet then message,'Input data are not defined!',/continue
    return
endif

force = defined(binsize) or keyword_set(force_binsize)

sd = size(data)
type = (sd)[sd[0]+1]

if not defined(min) then min = min(data, /nan) 
if not defined(max) then max = max(data, /nan)

ok = where(finite(data) and (data ge min) and (data lt max), nok)
if nok eq 0 then begin
    message,' No finite data...',/continue
    return
endif

if not defined(binsize) then begin
    binsize = (make_array(type=type,1,value=1))
    ord = sort(data[ok])
    binsize[*] = (data[ok[ord[nok*0.75]]]-data[ok[ord[nok*.25]]])/5.
    binsize = binsize[0]
    if binsize eq 0 then begin
        five = (make_array(type=type,1,value=5))
        binsize = (total([min(data,/nan),max(data,/nan)])/five)[0]
    endif
endif else begin
    binsize = (make_array(type=type,1,value=binsize))[0]
endelse



nbins_guess = (max-min)/binsize
if not force then begin
    repeat begin
        nbins_guess = (max-min)/binsize
        if nbins_guess gt nok then binsize = binsize *2. 
    endrep until nbins_guess lt nok
endif else begin
    if nbins_guess gt nok then begin
        if not quiet then message,'Roughly '+ $
          str(nbins_guess,form="(I)")+' bins, for ' + $
          ''+str(nok)+' points...', /continue
    endif
endelse

si = size(input)
if  si[si[0]+1] eq 1 then begin
    dist = histogram(data[ok], INPUT = input, BINSIZE =  binsize,  $
                     MAX = max, MIN = min, NAN = nan, OMAX = omax, $
                     OMIN = omin, REVERSE_INDICES = reverse_indices)
endif else begin
    dist = histogram(data[ok], BINSIZE =  binsize,  MAX = max, $
                     MIN = min, NAN = nan, OMAX = omax, OMIN = omin, $
                     REVERSE_INDICES = reverse_indices)
endelse
sigma = sqrt(dist)

;
; since not all data are passed thru to HISTOGRAM, I must now fix the
; reverse index list so that it corresponds to input data. (HISTOGRAM
; should be able to do this, but it stuffs up when there are NaN's in
; the input. This is a bug and a half, if you ask me. 
;
nh = n_elements(dist)
i_ind = reverse_indices[0L:nh]   ; this is the "range" part of the
                                ; reverse index list. It has one more
                                ; element than the histogram has
                                ; bins. 
o_ind = reverse_indices[nh+1L:*] ; there are the indices of the
                                ; elements from the OK array, referred
                                ; to by each bin's range indices
                                ; (I_IND). 
o_ind = ok[o_ind]               ; now o_ind refers properly to the input data. 
reverse_indices = [i_ind, o_ind]
undefine, i_ind, o_ind          ; clean up!


if keyword_set(normalize) then begin
    denom = total(dist)
    sigma = dist/denom * sqrt(1./denom + 1./dist)
    dist = dist / denom
endif


nbins = long((omax - omin)/binsize) + 1L
if type eq 1 then itype = 3 else itype = type ; prevent byte
                                              ; rollover in bins 

indices = make_array(nbins, type = itype,/index)

one = (make_array(1, type = type, value=1))[0]
two = one + one

bin_lower_bounds = indices*binsize + omin
bin_upper_bounds = (indices + one)*binsize + omin

bins = (bin_upper_bounds + bin_lower_bounds)/two
;
; why is the following necessary? Why does IDL stick on an empty bin?
; ARGH! 
;
if max(bins, /nan) gt omax then begin
    not_too_big = where(bins le omax, nntb)
    if nntb eq 0 then begin
        message,'Unable to define bins properly by default...you will ' + $
          'need to set them correctly yourself.',/continue
        return
    endif
    dist = dist[not_too_big]
    bins = bins[not_too_big]
endif    


if not keyword_set(no_plot) then begin
    plot, bins, dist, _extra = extra, psym=10
    if defined(extra) then begin
        o_extra = extra
        trim_structure, o_extra, legal_oplot_tags, /keep, /quiet
    endif
    finish_hist, bins, dist, _extra = o_extra
    if not keyword_set(no_error) then begin
        oploterr,bins, dist, sigma
    endif
endif


return
end



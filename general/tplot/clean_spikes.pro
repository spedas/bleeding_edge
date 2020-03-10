
;+
; PROCEDURE:   CLEAN_SPIKES, 'name'
; 
; PURPOSE: Simple routine to remove spikes from tplot data. 
; Clean_spikes smooths the data, then compares each data point
; with its smoothed value. Given a threshold value of FT (default of
; 10) and a number of smoothing points (default of 3) if the data
; value at any point is greater than FT*nsmooth/(nsmooth-1+FT) times
; the smoothed data point, then the data is reset to NaN. Note that
; the coefficient FT*nsmooth/(nsmooth-1+FT) is between a value of 1.0
; (for FT = 1) and nsmooth (ft -> INF). For the default input the
; coefficient is 2.5.
; 
; AUTHOR: unknown, Probably Frank Marcoline
; 
; KEYWORDS:
;  display_object = Object reference to be passed to dprint for output.
;  new_name = a new name for the despiked variable, the default is to
;  append '_cln' to the input variable name
;  nsmooth = the number of data points for smoothing. The default is
;  3, will be reset to an odd number prior to smoothing if an even
;  number is passed in.
;  thresh = a threshold value, the default is 10.0
;  use_nn_median = if set, then do not compare the value of the data
;  point to a smoothed version of itself, instead compare the value
;  data[i] with the median value of the data[i-ns:i+ns], not including the
;  value at data[i]
;  subtract_average = if set, subtract the average value of the data
;  prior to checking for spikes. **This is not recommended for data that
;  is defined to be greater than zero, such as a density or particle
;  count rate.
;  mdeian = passed into the average subtraction. if set, use the
;  median for the subtract_average option.
; jmm, 4-jul-2007, made to work for negative data, by adding absolute values
; jmm, 30-jul-2007, Added more error checking
; jmm, 15-sep-2009, documentation test
; jmm, 9-mar-2020, Added documentation, fixed absolute value
; calculation so that mixed positive-negative values are handled
; correctly. Also added use_nn_median, subtract_average keywords.
;$LastChangedBy: $
;$LastChangedDate: $
;$LastChangedRevision: $
;$URL: $
;-
pro clean_spikes, name, new_name=new_name, nsmooth=ns, thresh=ft, $
                  display_object=display_object, use_nn_median=use_nn_median, $
                  subtract_average=subtract_average, median=median

  get_data, name, data = d, dlim = dlim, lim = lim

  If(size(d, /type) Ne 8) Then Begin
     msg = name+': No data'
     dprint, msg , display_object=display_object
     Return
  Endif

  if not keyword_set(ns) then  ns = 3
  ns = (fix(ns)/2)*2 + 1 ;insure that ns is odd, for smoothing
  if not keyword_set(ft) then  ft = 10.
  ft = float(ft)
  xx = ft*ns/(ns-1+ft)
  If(xx Le 1.0) Then Begin ;Only happens for ft Lt 1
     msg = name+': Low threshold, returning undespiked data'
     dprint, msg , display_object=display_object
     if not keyword_set(new_name) then new_name = name+'_cln'
     store_data, new_name, data = d, dlim = dlim, lim = lim
     Return
  Endif
  nd1 = dimen1(d.y)
  If(nd1 Le 2*ns+1) Then Begin
     msg = name+': Not enough data for smoothing to despike, returning undespiked data'
     dprint, msg , display_object=display_object
     if not keyword_set(new_name) then new_name = name+'_cln'
     store_data, new_name, data = d, dlim = dlim, lim = lim
     Return
  Endif
  nd2 = dimen2(d.y)
  If(keyword_set(subtract_average)) Then Begin
; Before smoothing, subtract average, but save the original data
     d_original = d
     temp_name = new_name + '_tmp_'
     tsub_average, name, nn1, new_name = temp_name, median = median, $
                   display_object=display_object
     get_data, temp_name, data = d
  Endif
  ds = d ;ds is the smoothed version of the data
  If(keyword_set(use_nn_median)) Then Begin 
;compare d.y with points to either side
     For j = 0L, nd1-1 Do Begin
        x1 = (j-ns) > 0
        x2 = (j+ns) < (nd1-1)
        If(j eq 0) Then Begin
           For i = 0, nd2-1 Do ds.y[j, i] = median(d.y[1:x2, i])
        Endif Else If(j Eq nd1-1) Then Begin
           For i = 0, nd2-1 Do ds.y[j, i] = median(d.y[x1:j-1, i])
        Endif Else Begin
           For i = 0, nd2-1 Do ds.y[j, i] = median([d.y[x1:j-1, i], d.y[j+1:x2, i]])
        Endelse
     Endfor
  Endif Else Begin
;compare d.y with smoothed version of d.y
     If(!version.release Ge '8.1.0') Then Begin ;mirror edges if possible
        for i = 0, nd2-1 do ds.y[*, i] = smooth(d.y[*, i], ns, /nan, /edge_mirror)
     Endif Else for i = 0, nd2-1 do ds.y[*, i] = smooth(d.y[*, i], ns, /nan)
  Endelse
;Original spike test
;    bad = d.y gt (ft*ns*ds.y/(ns-1+ft) )
;2007 version
;    bad = abs(d.y) gt (ft*ns*abs(ds.y)/(ns-1+ft) )
;positive
;    xx = ft*ns/(ns-1+ft)
;    bad = d.y Gt xx*ds.y
;    bad = (d.y-ds.y) Gt (xx-1)*ds.y
;positive or negative
  bad = abs(d.y-ds.y) Gt abs((xx-1)*ds.y)
  if nd2 gt 1 then bad = total(bad, 2)
  wbad = where(bad gt .5)
;If average has been subtracted, restore original
  If(keyword_set(subtract_average)) Then d = temporary(d_original)
  If(wbad[0] Ne -1) Then d.y[wbad, *] = !values.f_nan
  if not keyword_set(new_name) then new_name = name+'_cln'
  store_data, new_name, data = d, dlim = dlim, lim = lim

End

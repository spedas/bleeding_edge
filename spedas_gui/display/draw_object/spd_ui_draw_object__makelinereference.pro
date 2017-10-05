;+
;spd_ui_draw_object method: makeLineReference
;
;
;this routine constructs a reference for legend lookup that has
;no more than the number of points on the screen times some number
;to account for pixel-level aliasing.  Operation vectorized with
;value-locate  
;x = clipped abcissa values, normalized to fractions of the total
;y = clipped data values, with the same number of elements as x
;n = the number of points requested in the output
;ref = data returned in named variable
;tolerance = the distance that a cursor can be from a real data point, before NaNs
;              get filled in.  This is a number proportional to the x range.(ex: .01 = 1% tolerance)
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__makelinereference.pro $
;-
pro spd_ui_draw_object::makeLineReference,x,y,n,ref=ref,tolerance=tolerance

  compile_opt idl2,hidden

  ;m = n_elements(x)
  
  ;set to 100% tolerance.  Meaning NANs will never be filled in unless they are in the data.
  if ~keyword_set(tolerance) then begin
    tolerance = 1.
  endif 
  
  minx = min(x,/nan)
  maxx = max(x,/nan)
  
  ref = dblarr(n)
  ref[*] = !VALUES.D_NAN
  
  ;These are fractional positions of points
  ;at which data values will be requested
  vals = (dindgen(n)/(n-1) > 0) < 1
  
  ;This pads the abcissas to deal with some
  ;of the weirdness in value_locate's output indexes
  datx = [minx-.001,x,maxx+.001]
  
;**********Save this code***********
;This code resamples the data rather than interpolates, it is being commented 
;because it can leave large NaN sized gaps in the results. 
;  
  ;value_locate requires sorted data, but
  ;the abcissa values may not be.
  ;So we sort, then later we unsort
  sort_idx = bsort(datx) ;sort transform
  isort_idx = bsort(sort_idx) ;inverse sort transform
  
  datx = datx[sort_idx]
  
  ;Locate the values
  close_idx = value_locate(datx,vals)
  
  ;The list of abcissa values one higher than the requested locations
  lows = abs((datx)[close_idx]-vals) 
  ;The list of abcissa values one lower than the requested locations
  highs = abs((datx)[close_idx+1]-vals)
  
  ;The list of lows that are closer to the values than highs and within
  ;the tolerance
  idx_lows = where(lows lt highs and lows lt tolerance,count_lows)
  
  ;Store these values.  To get to the final results, we need to use the inverse sort
  ;on the locations
  if count_lows gt 0 then begin
    ref[idx_lows] = ([!VALUES.D_NAN,y,!VALUES.D_NAN])[isort_idx[close_idx[idx_lows]]]
  endif
  
  ;The list of highs that are closer to the values than lows and within
  ;the tolerance
  idx_highs = where(highs lt lows and highs lt tolerance,count_highs)
  
  ;Store these values.  To get to the final results, we need to use the inverse sort
  ;on the locations
  if count_highs gt 0 then begin
    ref[idx_highs] = ([!VALUES.D_NAN,y,!VALUES.D_NAN])[isort_idx[close_idx[idx_highs]+1]]
  endif
  
end

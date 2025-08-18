;+
; NAME:
;      ssl_correlation_shift
;
; PURPOSE:
;      Calculates the shift required to correlate two tme series of
;      data.  Does this by binning the timeseries data, then
;      calculating the time shift required to maximally correlate each
;      bin.  When too few points overlap bins are rejected.
;
;
; CATEGORY:
;       THEMIS-SOC
;
; CALLING SEQUENCE:
;       lag_time_series = thm_correlation_shift(var1_time_series,var2_time_series)
;
; INPUTS:
;     
;       var1_time_series: a 2xn matrix(column major) of n time/value pairs for var1
;
;       var2_time_series: a 2xn matrix(column major) of n time/value pairs for var2
;
;       n_pts: optional, the minimum number of points of overlap necessary to
;       try correlating a bin
;
;       lag_steps: optional, checks plus or minus lag_steps * time steps
;       to correlate the vectors 
;
;       time_step: optional, the size of the time step to use when
;       interpolating and correlating the vectors
;
;       bin_size: optional, the size of each bin in seconds
;       
;
; OUTPUTS:
;       
;       an 3xn matrix(column major) of time/shift/correlation triplets  
;       or -1L on failure,
;       the output n is the number of bins constructed
;
; KEYWORDS:
;
; COMMENTS: This function will probably die horribly if time
;  values are not monotonic.
;
;
; PROCEDURE:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;       Written by:       Jim Lewis
;       2007-04-19        Initial version
;       Updated by: Patrick Cruce(pcruce@gmail.com)
;       2007-05-22        V2.0 
;
;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-25 15:20:30 -0700 (Mon, 25 Jun 2012) $
;$LastChangedRevision: 10638 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/ssl_correlation_shift.pro $
;
;-

;;tests if argument is array, 1L on success 0L on failure
;function tcs_is_array, a
;
;  if 0 eq (size(a))(0) then return, 0L
;
;  return, 1L
;  
;end

;calculates the intersection of two intervals
;t_start ge t_end then there is no intersection
function tcs_interval_intersect,i1, i2

t_start = (i1[0] GT i2[0]) ? i1[0] : i2[0]
t_end = (i1[1] GT i2[1]) ? i2[1] : i1[1]

return, [t_start, t_end]

end

;just returns time interval of some time series data
function tcs_get_time_interval, interval

  ;this is for monotonicity testing, but probably isn't necessary
  ;return, [min(interval[0, *]),max(interval[0, *])] 
  
  ;the efficient implementation
  return, [interval[0, 0], interval[0, n_elements(interval[0, *])-1]]

end

;I performs a row-wise permutation on a 2xn matrix(column_major)
function tcs_permute_time_series, time_series, permutation

  a = (time_series[0, *])(permutation)
  b = (time_series[1, *])(permutation)

  return, transpose([[a], [b]])

end

;this function looks tricky but its pretty simple
;it just clips a time_series to a specified interval
function tcs_clip, time_series, interval

  ;get the index matrix for all values within the interval
  ind =  where(time_series[0, *] ge interval[0] and time_series[0, *] lt interval[1])

  ;if some values are in range,ie if ind is an array not -1L
  if 0 ne size(ind, /DIMENSIONS)  then begin

    return, tcs_permute_time_series(time_series, ind)   

  endif

  ;else return -1L
  return, -1L

end

;get the ith bin from a 2xn time series(column major)
function tcs_get_bin, i, time_series, interval, bin_size

  low = i*bin_size + interval[0]
  high = (i+1)*bin_size + interval[0]

  ind =  where(time_series[0, *] ge low and time_series[0, *] lt high)

  if not tcs_is_array(ind) then return, -1L

  return, tcs_permute_time_series(time_series, ind)
  
end

;calculate the number of bins given an interval and a bin_size
function tcs_get_n_bins, interval, bin_size

  return, ceil((interval[1]-interval[0])/bin_size)

end

;just a bunch of calculation that dirties up my top level code
;returns a triplet with [time,shift,correlation] this corresponds to
;offset that maximizes correlation
function tcs_get_triplet, correlation_vector, bin_interval, lag_vector, time_step

  time = (bin_interval[0]+bin_interval[1])/2.0

  correlation = max(correlation_vector, index)

  shift = lag_vector[index]*time_step

  return, [time, shift, correlation]

end

;construct a lag offset vector for correlation function
function tcs_get_lag_vector, num_steps

  a = indgen(num_steps)
  
  return, [reverse(-1*a[1:*]),a]

end

;constructs an interpolation vector with a specified step size over a
;given interval
function tcs_get_time_vector, interval, step_size

  ;calculate number of steps and snap it to an integer
  step_num =  fix((interval[1]-interval[0])/step_size)

  ;generate array and offset(y=Mx+b)
  return, dindgen(step_num) * step_size + interval[0]
  
end

function ssl_correlation_shift, var1_time_series, var2_time_series, n_pts = n_pts, $
                                lag_steps = lag_steps, time_step = time_step, bin_size = bin_size

;optional variable setting
if not keyword_set(n_pts) then n_pts = 200

if not keyword_set(lag_steps) then lag_steps = 128

if not keyword_set(time_step) then time_step = 1.0D/128.0D

if not keyword_set(bin_size) then bin_size = 60.0

;get the interval where they overlap
overlap_interval = tcs_interval_intersect(tcs_get_time_interval(var1_time_series), $
                                          tcs_get_time_interval(var2_time_series))

;clip the intervals
var1_ts_clip =  tcs_clip(var1_time_series, overlap_interval)
var2_ts_clip =  tcs_clip(var2_time_series, overlap_interval)

;if there isn't an overlap then fail
if overlap_interval[0] ge overlap_interval[1] then return, -1L

;tried doing calculations using histogram function, but it didn't bin
;both vectors the same way

;calculate number of bins
n_bins = tcs_get_n_bins(overlap_interval, bin_size)

;3xn_bins, time/shift/correlation vector for returning
;tsc_vector = dblarr(3, n_elements(hist1))
tcs_vector = dblarr(3,n_bins)
tcs_vector(*) = !VALUES.F_NAN

;iterate over bins
for i = 0, n_bins-1 do begin

  ;get the bins
  bin1 = tcs_get_bin(i, var1_ts_clip, overlap_interval, bin_size)

  bin2 = tcs_get_bin(i, var2_ts_clip, overlap_interval, bin_size)
  
  ;makes sure bin has values
  if (tcs_is_array(bin1) and tcs_is_array(bin2)) then begin


    ;calculate the interval of overlap
    bin_overlap_interval = tcs_interval_intersect(tcs_get_time_interval(bin1), $
                                              tcs_get_time_interval(bin2))

    ;get the overlap bins
    bin1_overlap = tcs_clip(bin1, bin_overlap_interval)
    bin2_overlap = tcs_clip(bin2, bin_overlap_interval)

    ;check that the overlap bin isn't -1L and check
    ;that it has an acceptable number of elements
    if(tcs_is_array(bin1_overlap) and n_elements(bin1_overlap[0:*]) gt n_pts and $
       tcs_is_array(bin2_overlap) and n_elements(bin2_overlap[0:*]) gt n_pts) then begin
    
      ;calculate time grid(vector) for interpolation
      t_vector = tcs_get_time_vector(bin_overlap_interval, time_step)

      ;interpolate bins onto same step space
      bin1_interp =  interpol(bin1_overlap[1, *], bin1_overlap[0, *], t_vector)
      bin2_interp =  interpol(bin2_overlap[1, *], bin2_overlap[0, *], t_vector)
      
      ;calculate lag (vector)
      l_vector = tcs_get_lag_vector(lag_steps)

      ;correlate vectors
      correlation_vector = c_correlate(bin1_interp, bin2_interp, l_vector, /DOUBLE)
      ;store time/shift/correlation
      tcs_triplet = tcs_get_triplet(correlation_vector, bin_overlap_interval, l_vector, time_step)
      
      tcs_vector(*, i) = tcs_triplet
      
    endif
       
    ;handle fail case, leaving as NaN
    ;actually handles without any effort
    ;on my part

  endif

  ;handle fail case, ditto above

endfor

return, tcs_vector


end


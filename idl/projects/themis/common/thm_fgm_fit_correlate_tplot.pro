;+
; NAME:
;       thm_fgm_fit_correlate_tplot.pro
;
; Purpose:
;       Uses ssl_correlation_shift.pro to do a correlation shift
;       analysis on the vector lengths(math not cs vectors) of a
;       selected fgm mnemonic and fit data
;
;
; CATEGORY:
;       THEMIS-SOC
; CALLING SEQUENCE:
;      pro thm_fgm_fit_correlate_tplot,fit_name, fgm_name, store_name, correlation_floor = correlation_floor, point_number =  point_number, lag_step_number = lag_step_number, time_step_size = time_step_size, bin_size = bin_size
;
; INPUTS:
; 
;       fit_name: the tplot name of the fit data to be compared. RAW
;       LEVEL 1 FIT DATA IS REQUIRED, E.G., 'tha_fit'
;      
;       fgm_name: the tplot name of the fgm_data to be
;       compared
;
;       store_name: the name of a tplot variable in which to store the result
;     
;       correlation_floor: optional, if set filters all results where
;       the correlation between functions is too poor(default:0.0)
;
;       point_number: optional, the minimum number of points of
;       overlap necessary to try correlating a bin(default:10)
;
;       lag_step_number: optional, checks plus or minus lag_steps * time steps
;       to correlate the vectors (default:5)
;
;       time_step_size: optional, the size of the time step to use when
;       interpolating and correlating the vectors, in
;       seconds(default:1/8 seconds)
;
;       bin_size: optional, the size of each bin in seconds
;       (default:60 seconds)
;       
;
; OUTPUTS:
;       
;       stores the time and the shift values in the selected tplot_var
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
;       Written by: Patrick Cruce(pcruce@gmail.com)
;       2007-06-06        V1.0
;
; KNOWN BUGS: tcs_vector_length doesn't filter NANs so it may output 
; arithmetic warnings
;-


;tests if argument is array, 1L on success 0L on failure
;function tcs_is_array, a
;
;  if 0 eq (size(a))(0) then return, 0L
;
;  return, 1L
;  
;end

;array based vector length of time series data
;works for any number of physical dimensions
;ie 3-d input = 3xn array
;       output= 1xn array of vector lengths at each n
;
;has bug, doesn't filter nan's so it will output arithmetic warnings
function tcs_vector_length, x

  return,sqrt(total(x*x, 1))

end

pro thm_fgm_fit_correlate_tplot, fit_mnem, fgm_mnem, store_name,  correlation_floor = correlation_floor, point_number =  point_number, lag_step_number = lag_step_number, time_step_size = time_step_size, bin_size = bin_size


if(not keyword_set(lag_step_number)) then lag_step_number = 5

if(not keyword_set(time_step_size)) then time_step_size = 1.0/8.0

if(not keyword_set(point_number)) then point_number = 10

if(not keyword_set(correlation_floor)) then correlation_floor = 0.0

get_data, fit_mnem, data = d

times = d.X

;get the proper 3 dimensions out of the fit mnem
values = transpose([[d.Y[*, 1, 1]], [d.Y[*, 2, 1]], [d.Y[*, 4, 1]]])

;calculate length and concatenate into time series (2xn array)
ts1 = transpose([[times], [tcs_vector_length(values)]])

;ts1 = transpose([[times], [d.Y[*, 4, 1]]])

get_data, fgm_mnem, data = d

times = d.X

values = transpose(d.Y)

ts2 = transpose([[times], [tcs_vector_length(values)]])

;ts2 = transpose([[times], [d.Y[*, 0]]])

 x_cor = ssl_correlation_shift(ts1, ts2, n_pts = point_number, lag_steps = lag_step_number, time_step = time_step_size, bin_size = bin_size)


 if not tcs_is_array(x_cor) then begin
   print, 'error calculating correlation shift, probable 0 overlap between variables'
   return
 endif

; print, x_cor

;filter all values that do not correlate better than correlation_floor

;this line prevent arithmetic error messages
index = where(finite(x_cor[2, *]))

;tcs_is array is a utility function that just makes sure the indices
;returned aren't -1L

;find the values that have acceptable correlation
if(tcs_is_array(index)) then index = where(x_cor[2, index] ge correlation_floor)

;make proper assignments
if(tcs_is_array(index)) then x_cor[2, index] = !VALUES.F_NAN $
else x_cor[*] = !VALUES.F_NAN

;store the data
store_data, store_name, DATA = {X:transpose(x_cor[0, *]), Y:transpose(x_cor[1, *])}

end

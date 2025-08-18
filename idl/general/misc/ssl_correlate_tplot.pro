;+
; NAME:
;      ssl_correlate_tplot
;
; PURPOSE:
;        Identified the amount of shift required to correlate two
;        time series tplot variables and stores the result in a tplot
;        variable. Only compares 1-d to 1-d data at a time So for example you
;        can, compare the fge x and the fgl_x but can't do all three
;        at a time. 
;
;
;      Works by binning the timeseries data, then calculating the
;      time shift required to maximally correlate each bin.  
;      When too few points overlap bins are rejected.
;
; CATEGORY:
;       THEMIS-SOC
;
; CALLING SEQUENCE:
;      pro thm_correlate_tplot,var1_name, var1_y_dim, var2_name, var2_y_dim, store_name, correlation_floor = correlation_floor, point_number =  point_number, lag_step_number = lag_step_number, time_step_size = time_step_size, bin_size = bin_size
;
; INPUTS:
; 
;       var1_name: the tplot name of the first variable to be compared
;       
;       var1_y_dim: the numerical dimension of the first tplot y_var to look 
;       at(from 0 to n-1)
;
;       var2_name: the tplot name of the second variable to be
;       compared
;
;       var2_y_dim: the numerical dimension of the second tplot y_var
;       to look at(from 0 to n-1)
;
;       store_name: the name of a tplot variable in which to store the result
;     
;       correlation_floor: optional, if set filters all results where
;       the correlation between functions is too poor(default:.9)
;
;       point_number: optional, the minimum number of points of
;       overlap necessary to try correlating a bin(default:200)
;
;       lag_step_number: optional, checks plus or minus lag_steps * time steps
;       to correlate the vectors (default:64)
;
;       time_step_size: optional, the size of the time step to use when
;       interpolating and correlating the vectors, in
;       seconds(default:1/128 seconds)
;
;       bin_size: optional, the size of each bin in seconds
;       (default:60 seconds)
;       
;
; OUTPUTS:
;       
;       stores the time and the shift values in the select tplot_var
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
;       2007-05-24        V1.0
;
;;$LastChangedBy: lphilpott $
;$LastChangedDate: 2012-06-25 15:20:30 -0700 (Mon, 25 Jun 2012) $
;$LastChangedRevision: 10638 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/ssl_correlate_tplot.pro $
;
; KNOWN BUGS:
;-


;tests if argument is array, 1L on success 0L on failure
;function tcs_is_array, a
;
;  if 0 eq (size(a))(0) then return, 0L
;
;  return, 1L
;  
;end

;the main function
pro ssl_correlate_tplot,var1_name, var1_y_dim, var2_name, var2_y_dim, store_name, correlation_floor = correlation_floor, point_number =  point_number, lag_step_number = lag_step_number, time_step_size = time_step_size, bin_size = bin_size

if not keyword_set(correlation_floor) then correlation_floor = 0.9D

if not keyword_set(point_number) then point_number = 200

if not keyword_set(lag_step_number) then lag_step_number = 64

if not keyword_set(time_step_size) then time_step_size = 1.0D/128.0D

if not keyword_set(bin_size) then bin_size = 60

get_data, var1_name, data = d

times1 = d.X
values1 = transpose(d.Y[*, var1_y_dim])

get_data, var2_name, data = d

times2 = d.X
values2 = transpose(d.Y[*, var2_y_dim])

;below is a little idl magic to concatenate for input into thm_correlation_shift
 ts1 = transpose([[times1], [reform(values1)]])
 ts2 = transpose([[times2], [reform(values2)]]) 

;x_ts1 is a 2xn matrix(column major) of x-value/timestamp pairs from
;tha_fgl
;x_ts2 is a 2xn matrix(column major) of x-value/timestamp pairs from
;tha_fge
;x_cor is a 3xn matrix(column major of timestamp/shift/correlation
;triplets between tha_fgl and tha_fge
 x_cor = ssl_correlation_shift(ts1, ts2, n_pts = point_number, lag_steps = lag_step_number, time_step = time_step_size, bin_size = bin_size)

 if not tcs_is_array(x_cor) then begin
   dprint,  'error calculating correlation shift, probable 0 overlap between variables'
   return
 endif

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

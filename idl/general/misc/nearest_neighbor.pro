;+
;Name: 
;   nearest_neighbor
;   
;Purpose:
;   Finding the nearest neighbors by interpolating the indices for two arrays. 
;   NANs can be returned when gap/no_extrapolate are used.
;   
;Input:
;   time_series: monotonically increasing time series array 
;   target_time: monotonically increasing time to search for in the time series
;   
;Keywords:   
;   gap: return NANs if time gap > gap (in seconds), see keyword 'interp_threshold' in "interp"
;   no_extrapolate: Set this keyword to prevent extrapolation. See keyword 'no_extrapolate' in "interp"
;   silent: No printing
; $LastChangedBy: xussui $
; $LastChangedDate: 2018-12-05 17:23:32 -0800 (Wed, 05 Dec 2018) $
; $LastChangedRevision: 26256 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/nearest_neighbor.pro $
; 
;CREATED BY:    Shaosui Xu  2018-08-15
;FILE: nearest_neighbor.pro
;-
function nearest_neighbor, time_series, target_time, gap=gap, no_extrapolate=no_extrap, silent=silent

    if ~keyword_set(silent) then print,'Warning: Both "time_series" and "target_time" are assumed to be monotonic!!'
    inx = lindgen(n_elements(time_series))
    
    tt = target_time

    inxp = interp(inx,time_series,tt,interp_threshold=gap,no_extrap=no_extrap)
    innan = where(inxp ne inxp,c1,com=inn,ncom=ninn) 
    if (ninn gt 0L) then inxp[inn]=round(inxp[inn])
    if (c1 gt 0L) then inxp[innan]=!values.f_nan
    
    return,inxp 
end

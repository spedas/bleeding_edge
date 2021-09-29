;+ 
; Name:
;     find_nearest_neighbor2
;     
; Purpose:
;     Faster versin of find_nearest_neighbor. Use minimum to search in a time series to find the array element closest to the target time.
;     nn function uses similar algorithm providing nearest index in time.
;     
; Input:
;     time_series: monotonically increasing time series array (stored as doubles)
;     target_time: time to search for in the time series (double)
;     
; Keywords:
;     quiet: suppress output of errors
;     sort: sort the input array prior to searching
;     allow_outside: if target_time is outside of target_series, this keyword 
;         causes this routine to return the last/first element in the array
;         (whichever is closer)
;     
; Output:
;     Returns the value in time_series nearest to the target_time (as a double) 
;     Returns -1 if there's an error
; 
; Examples:
;     >> print, find_nearest_neighbor2([1,2,3,4,5,6,7,8,9], 4.6)
;           5
;           
;     >> print, find_nearest_neighbor2([5,4,3,7,8,2,4,6,7], 7.6, /sort)
;           8
; See also:
;   find_nearest_neighbor, nn
;
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2018-01-10 17:03:26 -0800 (Wed, 10 Jan 2018) $
; $LastChangedRevision: 24506 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/find_nearest_neighbor2.pro $
;-
function find_nearest_neighbor2, time_series, target_time, quiet = quiet, sort = sort, allow_outside = allow_outside
    if keyword_set(sort) then time_series = time_series[bsort(time_series)]

    ; check the first and last elements to make sure we're inside the range
    ; using the fact that the times are monotonic 
    if (target_time lt time_series[0] || target_time gt time_series[n_elements(time_series)-1]) then begin
        if keyword_set(allow_outside) then return, target_time lt time_series[0] ? time_series[0] : time_series[n_elements(time_series)-1]
        if undefined(quiet) then dprint, dlevel=1, 'The element we''re searching for is outside the array'
        return, -1
    end
    
    tmp = min(time_series - target_time, idx, /ABSOLUTE)
    fnn = time_series[idx]
    
    return, fnn

end
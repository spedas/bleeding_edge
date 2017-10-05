;+
; FUNCTION:	get_wind_times
;
; PURPOSE: 	To get an array of all the times loaded in memory for a
;		given data type.
; 
; INPUTS:	STRING data type.
;
; OUTPUTS:	array of time tags if successful, else 0D
;
; MODIFICATION HISTORY: Written 1995/09/22 By J. M. Loran
;-

FUNCTION get_wind_times, data_sel, silent=silent
@wind_com.pro

; check that data_sel is a string

IF data_type(data_sel) NE 7 THEN BEGIN
	PRINT, 'data type must be a string'
	return, 0
ENDIF

; allocate a large double array for the data

n_points = 200000L
time_points= DBLARR(n_points)

; and get the times

n_points = CALL_EXTERNAL(wind_lib,'get_time_array', data_sel, n_points, time_points)

if n_points GT 0 THEN BEGIN
	time_points = time_points(0:n_points)
;	time_points = time_points(uniq(time_points, sort(time_points)))
	IF NOT keyword_set(silent) THEN $
          print, N_ELEMENTS(time_points), ' time tags retrieved'
	RETURN, time_points
ENDIF

RETURN, 0D

end


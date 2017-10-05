;+
;	Procedure: FIND_CONST_INTERVALS
;
;	Purpose:  Find intervals within the input array where the data are constant to some tolerance,
;		and return the begin and end indices into the original array for those intervals.
;
;	Calling Sequence:
;		x = [ 1, 1, 3, 3, 4, 1, 1, 1, 1]
;		ctol = 0.01
;		find_const_intervals, x, nint=nint, ibeg=ibeg, iend=iend, ctol=ctol
;
;	Arguements:
;		X, ARRAY or any type; will be cast to FLOAT for comparison.
;		NINT, LONG, number of intervals of constantcy found in X.
;		IBEG, IEND, LONG[ nint], arrays of array indices to the begin and end of each constant interval.
;		CTOL, FLOAT, tollerance for constancy of data; ABS(dX) lt CTOL for data to be "constant".
;
;	Notes:
;		None.
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-11-14 13:46:58 -0800 (Mon, 14 Nov 2016) $
; $LastChangedRevision: 22356 $
; $URL $
;-

pro find_const_intervals, x, nint=nint, ibeg=ibeg, iend=iend, ctol=ctol

	if not keyword_set( ctol) then $
		ctol = 0.01

	y = [ -!values.f_infinity, float(x), !values.f_infinity ]
	dy = y[ 1:*] - y[ 0:*]
	idx = where( abs( dy) gt ctol, icnt)
	if icnt gt 0 then begin
		ibeg = idx[ 0:(icnt-2L)]
		iend = idx[ 1:(icnt-1L)] - 1L
		nint = icnt - 1L
	endif else begin
		ibeg = -1L
		iend = -1L
		nint = 0L
	endelse

return
end

;+
;	Procedure:
;		thm_comp_scm_response
;
;	Purpose:
;		Compute the voltage gain (magnitude only) as a function of frequency
;	for a given THEMIS SCM sensor.
;
;	Calling Sequence:
;	thm_comp_scm_response, sensor, ff, resp

;	Arguements:
;		sensor	STRING, ignored.
;		ff	FLOAT[ N], array of frequencies at which to compute the sensor response.
;		resp	float[ N], array of |voltage gain| vs. frequency.
;
;	Notes:
;	-- none.
;
; $LastChangedBy: jbonnell $
; $LastChangedDate: 2007-06-28 18:00:35 -0700 (Thu, 28 Jun 2007) $
; $LastChangedRevision: 939 $
; $URL $
;-
pro thm_comp_scm_response, sensor, ff, resp

; model THM SCM sensor response.
; based on FM1, X-Sensor.
	f1 = 40.	; single-pole high-pass corner frequency, Hz.
	f2 = 1650.	; single-pole, low-pass corner frequency, Hz.

	ff1 = ff/f1
	ff2 = ff/f2

	resp = sqrt( ff1*ff1/((1.+ff1*ff1)*(1. + ff2*ff2)))

return
end

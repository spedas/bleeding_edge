;+
;	Procedure:
;		thm_comp_eac_response
;
;	Purpose:
;		Compute the voltage gain (magnitude only) as a function of frequency
;	for the DFB EAC channels.
;
;	Calling Sequence:
;	thm_comp_eac_response, sensor, ff, resp

;	Arguements:
;		sensor	STRING, ignored.
;		ff	FLOAT[ N], array of frequencies at which to compute the channel response.
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
pro thm_comp_eac_response, sensor, ff, resp

; model THM DFB EAC channel response.
; based on FM002, EAC12 channel.

	f1 = 6.	; single-pole high-pass corner frequency, Hz.

	ff1 = ff/f1

	resp = sqrt( ff1*ff1/(1.+ff1*ff1))

return
end

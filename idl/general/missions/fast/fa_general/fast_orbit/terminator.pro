;+
;PROCEDURE:	terminator
;
;PURPOSE:	Generates lattitude and longitude arrays for the
;		night/day terminator given an input time.
;		Values returned are in Geographic coordinates.
;
;KEYWORDS:
;
;	TIME	The input time in seconds since 1970.
;
;POSITIONAL 
;PARAMETERS:
;
;	TLAT	The name of the array in which to return the
;		lattitude values of the terminator.
;	TLNG	The name of the array in which to return the
;		longitude values of the terminator
;
;Created by:	J.Rauchleiba	97-25
;-
pro terminator, TIME=time, tlat, tlng

; Create arrays for plotting terminator.

tlat=(findgen(61)*6. - 89)/!RADEG	; lattitudes (radians)
tlng=fltarr(61)				; longitudes (radians)

; Calc angle between axis and terminator

t0=time_double('96-12-21/0:00')
ang=(time - t0)*2*!PI/(365.25*24.*3600.)
tilt = 23.5/!RADEG	; Angle, axis and normal to ecliptic plane
alpha = tilt * cos(ang)	; Angle, axis and terminator

; Tilt terminator 

sohem=where((tlat LE 0) OR (tlat GE !pi))	; indices of pts in S.hem.
tlng = atan( 1. / (tan(tlat)*sin(abs(alpha))) )	; Tform longitudes, note abs()
tlng(sohem) = tlng(sohem) - !pi			; rotate pts in S.hem.
if alpha LT 0 then tlng = tlng + !pi		; rotate 180 if alpha (-)
;Tform lattitudes, cos(alpha)=cos(-alpha)
tlat = atan( sin(tlat)*cos(alpha) / sqrt( 1. - (sin(tlat)*cos(alpha))^2 ) )

; Rotate terminator according to time of day

if (!VERSION.RELEASE LE '5.4') then begin
    date_time = str_sep(time_string(time), '/')	; split the time string
    t_hms=str_sep(date_time(1),':')	; time array [hh,mm,ss]
endif else begin
    date_time = strsplit(time_string(time), '/', /EXTRACT)	; split the time string
    t_hms=strsplit(date_time(1),':', /EXTRACT)	; time array [hh,mm,ss]
endelse
;noon is degrees that 12pm is offset from Greenwich
noon = -(t_hms(0)*3600.+t_hms(1)*60.+t_hms(2))/(24.*3600.)*(2.*!PI) - !PI
tlng = tlng + noon
rerange, tlng, tlat, /deg

return
end

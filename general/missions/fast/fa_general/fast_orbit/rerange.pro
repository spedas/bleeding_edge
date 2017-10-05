;+
;PROCEDURE:	rerange
;
;PURPOSE:	Reformats arrays so they may be plotted as
;		lattitude and longitude.  Changes arrays so
;		that they are in the intervals [-pi/2, +pi/2]
;		and [-pi, +pi]. Can change both lattitude and 
;		longitude or just longitude.
;
;ARGUMENTS:	lng	The longitude array in radians.
;		lat	The corresponding lattitude array in
;			radians. (Optional)
;KEYWORDS:	degrees	Set this to return the arrays in degrees.
;
;Created by:	J.Rauchleiba	12/20/96
;-
pro rerange, lng, lat, degrees=deg

if keyword_set(lat) then begin
	if n_elements(lng) NE n_elements(lat) then $
		message, 'LNG and LAT arrays must be equal length.'

	lat = lat MOD (2*!pi)
	under = where(lat LT -!pi/2, count)
	if count GT 0 then begin
		lat(under) = -lat(under) - !pi
		lng(under) = lng(under) - !pi
	endif

	over = where(lat GT !pi/2, count)
	if count GT 0 then begin
		lat(over) = -lat(over) + !pi
		lng(over) = lng(over) - !pi
	endif
endif

lng = lng MOD (2*!pi)
under = where(lng LT -!pi, count)
if count GT 0 then lng(under) = lng(under) + 2*!pi

over = where(lng GT !pi, count)
if count GT 0 then lng(over) = lng(over) - 2*!pi

if keyword_set(deg) then begin
	if keyword_set(lat) then lat = lat*!radeg
	lng = lng*!radeg
endif

return
end

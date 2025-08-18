;+
;PROCEDURE:	mag_to_geo
;
;PURPOSE:	Converts lattitude and longitude between MAG 
;		and GEO coordinates.
;		Uses a simple transformation matrix from Kivelson
;		and Russell, "Intro to Space Physics" which is not
;		very accurate in the polar regions.
;
;PARAMETERS:	lat	The array of lattitudes.(In radians unless
;			degrees keyword set.)
;		lon	The array of longitudes.(in radians unless
;			degrees keyword set.)
;
;KEYWORDS:	degrees	Set this if both input and output are to be
;			in degrees.
;		mag	Set this to do the inverse transformation,
;			GEO to MAG coordinates.
;Created by:	J.Rauchleiba	1/7/97
;-
pro mag_to_geo, lat, lon, degrees=deg, mag=mag

; Convert to radians if necessary

if keyword_set(deg) then begin
	lat = lat*!dtor
	lon = lon*!dtor
endif

; The transformation matrix

maggeo = [ 	[ .32110, .94498,  .06252], $
		[-.92756, .32713, -.18060], $
		[-.19112,      0,  .98157]	]

if keyword_set(mag) then maggeo = transpose(maggeo)

lat = !pi/2. - lat	; theta is measured from pole in spherics.

; Create array of column vectors (lats and lons in cartesian coords.)

Vmag = [	[sin(lat)*cos(lon)], $
		[sin(lat)*sin(lon)], $
		[cos(lat)	  ]	]

; Transform each column vector

Vgeo = maggeo ## Vmag	; array of 3-element column vectors

lat = acos( Vgeo(*,2) )
lon = atan( Vgeo(*,1)/Vgeo(*,0) )

flip = where(Vgeo(*,0) LT 0)	; 0 < lon < pi,	Vmag(1) > 0
if flip(0) NE -1 then $
	lon(flip) = lon(flip) + !pi	; pi < lon < 2pi, Vmag(1) < 0

lat = !pi/2. - lat	; theta is measured from equator in GEO.

if keyword_set(deg) then begin
	lat = lat*!radeg
	lon = lon*!radeg
endif

return
end

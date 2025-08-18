;+
; PROCEDURE:	transform_mag_geo
;
; PURPOSE:	Convert lattitudes and longitudes between MAG and GEO 
;		coordinate systems using the eccentric dipole model.
;		Transformation is from MAG to GEO unless INVERSE is set.
;		Transformation is performed at <Re> + 100km = 6472.1 km
;
; INPUTS:
;
;   LAT		The input lattitude array. (Not altered)
;   LNG		The input longitude array. (Not altered)
;   TLAT	Named variable to accept transformed lattitudes.
;   TLNG	Named variable to accept transformed longitudes.
;
; KEYWORDS:
;
;   YEAR	The 4-digit year.
;   DEGREES	If nonzero, input and ouput in degrees.
;   INVERSE	If nonzero, tranformation is from GEO to MAG.
;
; NOTES:
;
;   MAG --> GEO:
;   When transforming from MAG to GEO, LAT and LNG are assumed to
;   refer to points Re=6372.1 km from the earth's dipole center.
;   (This does not necessarily place them on the surface of the earth.)
;   The points are propagated to <Re> + 100km and then their
;   coordinates are converted to the GEO system through a rotation
;   followed by a translation.
;
;   This procedure is inaccurate for points where field lines are nearly
;   orthogonal to lines through the dipole center, i.e. near the equator.
;
;   GEO --> MAG:
;   When transforming from GEO to MAG, LAT and LNG are assumed to
;   refer to points Re + 100km from the center of the earth.
;   Since this one is simply the inverse of the above transformation, we
;   do the inverse translation followed by the inverse rotation.
;   Right now, the GEO to MAG transformation is less accurate than its
;   inverse; it does not propagate along field lines during the
;   translation to the dipole center.
; 
; 
; WRITTEN BY:	J. Rauchleiba	4/14/97
; ALGORITHM BY: M. Temerin, G. Kaplan, J. Rauchleiba
;
;-
pro transform_mag_geo, lat, lng, tlat, tlng, $
	YEAR=year, $
	DEGREES=deg, $
	INVERSE=inv

earth_rad = 6372.1
mean_rad = 6472.1 ;km  ( = <Re> + 100 km)

; Get location of dipole

dpo = dipole_offset(year)	; 3-element vector in km

; Make the rotation matrices (for transformation either way).

yyvar = year - 1995		; IGRF 1995 revision
g10 = -29682.0 + 17.6*yyvar
g11 = -1789.0 + 13.0*yyvar
h11 = 5318.0 - 18.3*yyvar
h2 = g10*g10 + g11*g11 + h11*h11
alpha = acos( -g10 / sqrt(h2) )
beta = atan(h11/g11)
ca = cos(alpha)
sa = sin(alpha)
cb = cos(beta)
sb = sin(beta)

geo2mag = [	[ca*cb, ca*sb, -sa], $
		[-sb  , cb   , 0  ], $
		[sa*cb, sa*sb, ca ]	]

if NOT keyword_set(inv) then mag2geo = transpose(geo2mag)

if keyword_set(deg) then begin	; I/O in degrees, must convert to radians
	tlat = lat*!dtor	; The transformed array
	tlng = lng*!dtor
endif else begin
	tlat = lat		; Copy input to output arrays
	tlng = lng
endelse

tlat = !pi/2. - tlat		; colattitude in rads for spherical coords

; Create array of column vectors (lats and lons -> cartesian coords.)

pos = [ [sin(tlat)*cos(tlng)], $
	[sin(tlat)*sin(tlng)], $
        [cos(tlat)          ]	] ; unit vectors

; Scale the position vectors to touch 100km alt if doing GEO->MAG (inv)
; or Re if doing MAG->GEO.

if keyword_set(inv) then pos=temporary(pos)*mean_rad $
  else pos=temporary(pos)*earth_rad
	
; PERFORM THE TRANSFORMATION

if NOT keyword_set(inv) then begin ;mag -> geo
        
        tpos = mag2geo ## pos       ; Lengths unchanged, axes now || to GEO

        ;; Now scale the vectors to 100 km alt
        ;; This does not entail constraint to field lines

	square = tpos(*,0)^2 + tpos(*,1)^2 + tpos(*,2)^2
	cross = 2*dpo(0)*tpos(*,0) + 2*dpo(1)*tpos(*,1) + 2*dpo(2)*tpos(*,2)
	const = dpo(0)^2 + dpo(1)^2 + dpo(2)^2 - mean_rad^2
	scale = ( -cross + sqrt(cross^2 - 4*square*const)) / (2*square)
        ;; if where(scale LT 0) NE -1 then message, 'Scaling error in T-form.'
	for i=0,2 do tpos(*,i) = tpos(*,i)*scale
        
        ; Find the difference between original vectors and scaled ones

        new_len = sqrt(tpos(*,0)^2 + tpos(*,1)^2 + tpos(*,2)^2)
        diff = new_len - mean_rad

        ; Find the fix in lattitude necessary to constrain scaled
        ; vectors to field lines.  Then fix and recalculate vectors.

        latfix = atan(diff*tan(tlat)/new_len/2)
        tlat = tlat + latfix
        pos = [ [sin(tlat)*cos(tlng)], $
                [sin(tlat)*sin(tlng)], $
                [cos(tlat)          ]	] ; reset pos to MAG unit vectors
        for i=0,2 do pos(*,i) = pos(*,i)*new_len ; scale to 100km individually
        tpos = mag2geo ## pos
        
        ; Translate the coordinate system to earth center

	for i=0,2 do tpos(*,i) = tpos(*,i) + dpo(i)

endif else begin ;do geo -> mag
        tpos = pos ; Set up the target array
	for i=0,2 do tpos(*,i) = pos(*,i) - dpo(i)
	tpos = geo2mag ## tpos
endelse

; Convert back into lattitude and longitude, degrees if necessary

tlat = atan(tpos(*,2)/sqrt(tpos(*,0)^2 + tpos(*,1)^2))	; assume < pi/2
tlng = atan(tpos(*,1)/tpos(*,0))			; can't assume
flip = where(tpos(*,0) LT 0)
if flip(0) NE -1 then tlng(flip) = tlng(flip) + !pi

if keyword_set(deg) then begin
	rerange, /deg, tlng, tlat
endif else begin
	tlat = tlat MOD (2*!pi)
	tlng = tlng MOD (2*!pi)
endelse

return
end

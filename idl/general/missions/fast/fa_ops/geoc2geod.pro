pro geoc2geod, lat_in, alt_in, lat_out, alt_out, INVERSE = inverse, $
               RADIANS = radians, IAU67 = iau67, GC_RADIUS = gc_rad
;+
;
; pro geoc2geod, lat_in, alt_in, lat_out, alt_out, INVERSE = inverse
;
; converts geocentric latitude and altitude and to geodetic. Latitude must
; be in degrees, altitude in kilometers. The INVERSE keyword goes from
; geodetic to geocentric. 
;
; You can also specify the GC_RADIUS keyword, which will have the
; geocentric radial distances in km. This method is actually
; preferable , since it avoids assigning a radius for the spherical
; Earth.
;
; With double precision, roundoff error is less than 1.d-06 km, which
; is more than adequate.  
;
; Uses geodetic parameters from WGS '84, semi-major axis and inverse of
; flattening :  6378.137 km and 298.257223563, unless one of the other
; ellipsoids is specified through a keyword.
;
;-
case 1 of 
    keyword_set(IAU67):begin
        biga = 6378.16
        finverse = 298.25
    end
    else: begin                 ; WGS '84
        biga = 6378.137d
        finverse = 298.257223563d
    end
endcase

one = 1.0d
radeg = 180.d/!dpi
ecc = sqrt((one+one)/finverse - one/finverse^2)
bigb = biga*(one - one/finverse)


mean_re = 6378.1400             ; this is the current difference
                                ; between GEI radial distance and ALT
                                ; returned by GET_FA_ORBIT. 23-Mar-97

;
; convert to radians
;
if not keyword_set(radians) then begin
    latrad = double(lat_in)/radeg
endif else begin
    latrad = double(lat_in)
endelse

if not defined(alt_in) then alt_in = make_array(size=size(lat_in))
if not defined(gc_rad) then gc_rad = alt_in + mean_re

if not keyword_set(inverse) then begin
    bigz = gc_rad * sin(latrad)
    bigp = gc_rad * cos(latrad)
    ep2 = (biga^2-bigb^2)/bigb^2

    t2 = atan(bigz*biga,bigp*bigb)
    lat_out = atan(bigz + $
                   ep2*bigb*sin(t2)^3,bigp-ecc^2*biga*cos(t2)^3)*radeg
    phi = lat_out/radeg
    
    bign = biga/sqrt(one-(ecc*sin(phi))^2)
    
    alt_out = bigp/cos(phi) - bign
    
    too_close = where(abs(abs(lat_in)-90.d) lt .01d,ntc)
    if ntc gt 0 then begin
        alt_out[too_close] = gc_rad[too_close] - bigb
    endif
endif else begin
    bign = biga/sqrt(one-ecc^2*sin(latrad)^2)
    bigp = (bign + alt_in)*cos(latrad)
    
    bigz = (bign*(one-ecc^2) + alt_in)*sin(latrad)

    alt_out = sqrt(bigp^2+bigz^2)-mean_re
    gc_rad = sqrt(bigp^2+bigz^2)
    lat_out = atan(bigz,bigp)*radeg
    too_close = where(abs(abs(lat_in)-90.d) lt .01d,ntc)
    if ntc gt 0 then begin
        alt_out[too_close] = alt_in[too_close] + bigb - mean_re
    endif
endelse

if keyword_set(radians) then begin
    lat_out = lat_out/radeg
endif

return

end



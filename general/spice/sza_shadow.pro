; this function returns the solar zenith angle at which the  planet's shadow
; occurs at various altitudes

function sza_shadow,  altitude,  latitude =  latitude,  radius =  radius, $
                      Areoid = areoid, offset = offset
  if not keyword_set (offset) then offset = 125.0
  if not keyword_set (radius) then radius = 3390.0 + offset; EUV shadow
  if not keyword_set (areoid) and keyword_set (latitude) then begin
    restore, '/home/rlillis/work/mgs/mola/r_areoid_fn_latitude.idl'
    radius =  interpol (r_mars,  lat,  latitude)
  endif
  return, 90.0+ acos (radius/(radius + altitude-offset))/!dtor
end

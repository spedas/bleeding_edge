;20171117 Ali
;crustal field at location x, given B
;
function mvn_sep_elec_peri_bcrust,x,b,lowres=lowres,mhd=mhd,t=time

  rmars=3390. ;km
  sizeb=size(b,/dim) ;[3,rad,lat,lon] or [3,r,t,p]
  tbin=0
  if keyword_set(mhd) then begin
    if mhd eq 3 then tbin=floor((time-time_double('2017-9-13/3:00'))/60./5.)
    if mhd eq 4 then tbin=3+floor((time-time_double('2017-9-12/22:00'))/60./5.)
    if tbin lt 0 or tbin gt sizeb[4]-1 then return,!values.f_nan
  endif

  ;x1=quaternion_rotation(x,qrot,/last_ind) ;position in IAU_MARS (km)
  sp=cv_coord(from_rect=x,/to_sphere,/degrees) ;[longitude:-180 to 180,latitude: -90 to 90,radius] or [p,t,r]
  reslat=180./sizeb[2]
  reslon=360./sizeb[3] ;angular resolution (degrees)
  if keyword_set(lowres) then begin
    resrad=10. ;radial resolution (km) Morschhauser_spc_dlat0.5_delon0.5_dalt10.sav
    alt0=120. ;altitude of first bin (km)
    if keyword_set(mhd) then alt0=100.
  endif else begin
    resrad=5. ;radial resolution (km) Morschhauser_spc_dlat0.25_delon0.25_dalt5.sav
    alt0=40. ;altitude of first bin (km)
  endelse
  lon=floor(sp[0]/reslon) ;longitude bin
  lat=floor((90.+sp[1])/reslat) ;latitdue bin
  alt=floor((sp[2]-rmars-alt0)/resrad)
  altscale=1.
  if lon eq 360/reslon then lon-=1
  if lat eq 180/reslat then lat-=1
  if alt lt 0 then alt=0
  if alt gt sizeb[1]-1 then begin
    altscale=float((sizeb[1]-1))/float(alt)
    alt=sizeb[1]-1
  endif
  
  bout=b[*,alt,lat,lon,tbin]*altscale ;(r,t,p)
  
  return,bout

end
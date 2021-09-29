;+
; PROCEDURE:
;         elf_make_geo_grid
;
; PURPOSE:
;         Create a geographic grid for orbit plots
;
; KEYWORDS:
;         None
;-
function elf_make_geo_grid

  ;MLAT contours
  latstep=10   ; 5. 
  ;latstart=0; 40.
  ;latend=90
  ;-------------------------
  ;JWu edit start
  latstart=-90; 40.
  latend=90
  ;JWu edit end
  ;------------------------


  ;mlon contours
  ;get magnetic lat/lons
  lonstep=30
  lonstart=0
  lonend=360
  nmlats=round((latend-latstart)/float(latstep)+1)
  mlats=latstart+findgen(nmlats)*latstep
  n2=150
  v_lat=fltarr(nmlats,n2)
  v_lon=fltarr(nmlats,n2)
  height=100.
  ; Calculate latitude circile; each latitude circle has 150 points
  ;the call of cnv_aacgm here converts from geomagnetic to geographic
  for i=0,nmlats-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r1,error,/geo
      v_lat[i,j]=u
      v_lon[i,j]=v
    endfor
  endfor

  nmlons=12 ;mlons shown at intervals of 15 degrees or one hour of MLT
  mlon_step=round(360/float(nmlons))
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  cnv_aacgm, 86.39, 175.35, height, outlat,outlon,r1,error   ;JWu ???
  mlats=latstart+findgen(n2)/float(n2-1)*(latend-latstart)
  ;  Calculate longitude values
  for i=0,nmlons-1 do begin
    for j=0,n2-1 do begin
      cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error,/geo
      u_lat[i,j]=u
      u_lon[i,j]=v
    endfor
  endfor

  ; v_lat, v_lon geo graphic latitude circles
  ; u_lat, u_lon geo graphic longitude lines
  geo_grid = {v_lat:v_lat, v_lon:v_lon, u_lat:u_lat, u_lon:u_lon, $
              nmlats:nmlats, nmlons:nmlons}
  
  return, geo_grid

end
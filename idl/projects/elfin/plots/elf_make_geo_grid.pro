;+
; PROCEDURE:
;         elf_make_geo_grid
;         
; INPUTS: 
;         mlat: magnetic latitude
;         mlon: magnetic longitude
;         height: elevation in km
;         glat: geographic latitude
;         glon: geographic longitude
;         
; OUTPUTS:
;         geo_grid: returns a structure with geographic grid
;
; PURPOSE:
;         Create a geographic grid for orbit plots
;
; KEYWORDS:
;         None
;-

;;;; Jiang Liu edit:
pro cotrans_magccord2geoccord, mlat, mlon, height, glat, glon
;;;; Inputs:
;;;;	height, mlat, mlon
;;;; Outputs:
;;;;	glat, glon
sphere_to_cart, height, mlat, mlon, vec = xyz_mlat
del_data, 'mlatcircle_???'
store_data, 'mlatcircle_mag', data = {x:replicate(time_double('2022 1 1'), n_elements(mlon)), y:xyz_mlat} 
cotrans, 'mlatcircle_mag', 'mlatcircle_geo', /mag2geo
get_data, 'mlatcircle_geo', nouse, xyz_mlat_geo
cart_to_sphere, xyz_mlat_geo[*,0], xyz_mlat_geo[*,1], xyz_mlat_geo[*,2], rp, glat, glon
end
;;;; end of Jiang Liu edit


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
	;;; Orignial
    ;for j=0,n2-1 do begin
    ;  cnv_aacgm,mlats[i],j/float(n2-1)*360,height,u,v,r1,error,/geo
    ;  v_lat[i,j]=u
    ;  v_lon[i,j]=v
    ;endfor

	;;; Jiang Liu edit:
	mlons_latcircle = indgen(n2)/float(n2-1)*360
  	cotrans_magccord2geoccord, replicate(mlats[i], n_elements(mlons_latcircle)), mlons_latcircle, replicate(height, n_elements(mlons_latcircle)), u_all, v_all
	v_lat[i,*] = u_all
	v_lon[i,*] = v_all
  	;;;;;;; end of Jiang Liu edit
  endfor

  nmlons=12 ;mlons shown at intervals of 15 degrees or one hour of MLT
  mlon_step=round(360/float(nmlons))
  n2=20
  u_lat=fltarr(nmlons,n2)
  u_lon=fltarr(nmlons,n2)
  ;cnv_aacgm, 86.39, 175.35, height, outlat,outlon,r1,error   ;JWu ???
  ;;; Jiang Liu edit:
  cotrans_magccord2geoccord, 86.39, 175.35, height, outlat, outlon
  ;;; end of Jiang Liu edit

  mlats=latstart+findgen(n2)/float(n2-1)*(latend-latstart)
  ;  Calculate longitude values
  for i=0,nmlons-1 do begin
	;;;; Original:
    ;for j=0,n2-1 do begin
    ;  cnv_aacgm,mlats[j],((outlon+mlon_step*i) mod 360),height,u,v,r1,error,/geo
    ;  u_lat[i,j]=u
    ;  u_lon[i,j]=v
    ;endfor

	;;; Jiang Liu edit:
  	cotrans_magccord2geoccord, mlats, replicate((outlon+mlon_step*i) mod 360, n_elements(mlats)), replicate(height, n_elements(mlats)), u_all, v_all
	u_lat[i,*] = u_all
	u_lon[i,*] = v_all
	;;;;;;; end of Jiang Liu edit
  endfor

  ; v_lat, v_lon geo graphic latitude circles
  ; u_lat, u_lon geo graphic longitude lines
  geo_grid = {v_lat:v_lat, v_lon:v_lon, u_lat:u_lat, u_lon:u_lon, $
              nmlats:nmlats, nmlons:nmlons}
  
  return, geo_grid

end

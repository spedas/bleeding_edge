;+
; PROCEDURE:
;         elf_make_sm_grid
;
; PURPOSE:
;         Create SM latitude rings and longitude spokes, expresented in GEO.
;         (for use with ELFIN orbit plots)
;
; KEYWORDS:
;         tdate: time to be used for calculation
;                (format can be time string '2020-03-20'
;                or time double)
;         south: use this flag for grids in southern hemisphere
;
; OUTPUT:
;         sm_grids: structure with lat rings, lon spokes, and poles
;
; EXAMPLE:
;         sm_grid = elf_make_sm_grid('2020-03-20')
;         sm_grid = elf_make_sm_grid('2020-03-20', /south)
;
;-
function elf_make_sm_grid, tdate=tdate,south=south

  ;------------------------
  ; Create Latitude rings
  ;------------------------
  ; create geographic rings (from 0 to 90 deg every 10 deg)
  thisllon=findgen(360)
  for i=0,8 do begin
    if keyword_set(south) then thisllat=make_array(360,/float)-i*10. else thisllat=make_array(360,/float)+i*10.
    append_array, ulats, thisllat
    append_array, ulons, thisllon 
  endfor

  ; convert lat rings from geo to sm
  r=make_array(360*9,/float)+0.1
  sphere_to_cart, r,ulats,ulons,x,y,z
  times=make_array(n_elements(ulons),/double)+tdate
  store_data, 'cart_latlons_sm', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_sm', 'cart_latlons_gsm', /sm2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_gse', /gsm2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gei', /gse2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_geo', /gei2geo
  get_data, 'cart_latlons_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, usmlats, usmlons

  ;-------------------------
  ; Create Longitude Spokes
  ;-------------------------
  ; geographic spokes go from 0 to 360 deg every 30 deg
  thislat=findgen(90)
  if keyword_set(south) then thislat = -thislat
  for i=0,11 do begin
    thislon=make_array(90,/float)+i*30.
    append_array, vlons, thislon
    append_array, vlats, thislat
  endfor
  
  ; convert longitude spokes to sm coordinates
  r=make_array(360*9,/float)+0.1
  sphere_to_cart, r,vlats,vlons,x,y,z
  times=make_array(n_elements(vlats),/double)+tdate
  store_data, 'cart_latlons_sm', data={x:times, y:[[x],[y],[z]]}
  cotrans, 'cart_latlons_sm', 'cart_latlons_gsm', /sm2gsm
  cotrans, 'cart_latlons_gsm', 'cart_latlons_gse', /gsm2gse
  cotrans, 'cart_latlons_gse', 'cart_latlons_gei', /gse2gei
  cotrans, 'cart_latlons_gei', 'cart_latlons_geo', /gei2geo
  get_data, 'cart_latlons_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, vsmlats, vsmlons

  ;--------------------------
  ; Calculate magnetic pole
  ;--------------------------
  if ~keyword_set(south) then lat_sm_pole=90. else lat_sm_pole=-90.
  sphere_to_cart, 1.,lat_sm_pole,0.1,x,y,z
  store_data, 'cart_pole_sm', data={x:tdate, y:[[x],[y],[z]]}
  cotrans, 'cart_pole_sm', 'cart_pole_gsm', /sm2gsm
  cotrans, 'cart_pole_gsm', 'cart_pole_gse', /gsm2gse
  cotrans, 'cart_pole_gse', 'cart_pole_gei', /gse2gei
  cotrans, 'cart_pole_gei', 'cart_pole_geo', /gei2geo
  get_data, 'cart_pole_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, psmlats, psmlons

  ;--------------------------
  ; Calculate SM noon
  ;--------------------------
  sphere_to_cart, 1.,0,0,x,y,z
  store_data, 'cart_noon_sm', data={x:tdate, y:[[x],[y],[z]]}
  cotrans, 'cart_noon_sm', 'cart_noon_gsm', /sm2gsm
  cotrans, 'cart_noon_gsm', 'cart_noon_gse', /gsm2gse
  cotrans, 'cart_noon_gse', 'cart_noon_gei', /gse2gei
  cotrans, 'cart_noon_gei', 'cart_noon_geo', /gei2geo
  get_data, 'cart_noon_geo', data=d
  cart_to_sphere, d.y[*,0], d.y[*,1], d.y[*,2], r, nsmlats, nsmlons

  
  sm_grid={lat_circles:[[usmlons], [usmlats]], $
           lon_lines:[[vsmlons], [vsmlats]], $
           pole: [psmlats, psmlons], noon: [nsmlats, nsmlons]}

  return, sm_grid

end


;+
;procedure: hdz2geo
;
;Purpose: Coordinate transformation between HDZ coordinates & GEO coordinates
;
;     HDZ is defined as:

;       H = horizontal field strength, in the plane formed by Z and GEO graphic north
;       D = field strength in the Z x X direction in nT
;       Z = downward field strength  
;       
;     H should be a projection onto a basis vector pointing north from station in nT
;     D should be a projection onto a basis vector perpendicular to H in the horizontal plane.
;         
;     Total field strength should be sqrt(H^2+D^2+Z^2) not sqrt(H^2+Z^2)
;     D must be in nT not degrees
;    
;     GEO is defined as:
;         X = Vector parallel to vector pointing outward at the intersection of the equatorial plane and the 0 degree longitudinal meridean(Greenwich Meridean)
;         Y = Z x X
;         Z = Vector parallel to orbital Axis of Earth Pointing northward.
;
;inputs:
;
;  data_in: 
;    Name of input tplot variable to be transformed, or Nx3 array of data for transformation. If no tplot variable is specific latitude and longitude must be set.
;  data_out:
;    Name of tplot variable in which to store output.  If this is a named variable and not a string, output data will instead be returned in variable.
;  latitude: latitude of the HDZ station, must be set if data_in is not tplot variable, or latitude and longitude not stored in dlimit.data_att or dlimit.cdf.vatt 
;  longitude: longitude of the HDZ station, must be set if data_in is not tplot variable, or latitude and longitude not stored in dlimit.data_att or dlimit.cdf.vatt
;  geo2hdz: If set, performs inverse transformation from GEO to HDZ
;  error: Set to named variable that will return 1 if an error occurs and 0 otherwise
;  rotation_matrix:  Returns the rotation matrix that will be used to transform
;  
;keywords:
;
;   /SSE2GSE inverse transformation
;
;   /IGNORE_DLIMITS: Dlimits normally used to determine if coordinate
;   system is correct, to decide if position needs offset, or to 
;   stop incorrect transforms.  This option will stop this behavior. 
;
;Examples:
;  hdz2geo,hdz_arr_in,geo_arr_out,latitude=60.4,longitude=173.6
;  hdz2geo,'in_tvar_name_hdz','out_tvar_name_geo'
;  hdz2geo,'in_tvar_name_geo','out_tvar_name_hdz',/geo2hdz  ;inverse transformation
;
;Notes:
;   #1 HDZ coordinates only make sense relative to a location, assumedly a ground station(gmag)
;   
;   #2 Specific latitude and longitude keywords must be set if: 
;    (1) data_in is not a tplot variable name 
;    -OR-
;    (2) tplot variable named by data_in does not specific site_latitude & site_longitude in dlimits 
;   
;   #3 If latitude or longitude keywords are set, these values will be used, not dlimit values. 
;   
;   #4 This transformation is a first order approximation.  It treats the earth as if it is a true sphere, ignoring
;   distortions due to the fact that the earth is actually an oblate spheroid.  
;  
;   
;   Written by Patrick Cruce(pcruce@igpp.ucla.edu)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2010-03-29 15:27:35 -0700 (Mon, 29 Mar 2010) $
; $LastChangedRevision: 7445 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/hdz2geo.pro $
;-



;helper function searches various metadata locations for latitude and longitude of station
pro hdz2geo_get_latlong,dl,latitude=latitude,longitude=longitude

  ;latitude
  str_element,dl,'data_att.site_latitude',success=s1
  str_element,dl,'cdf.vatt.station_latitude',success=s2
  if s1 then begin
    latitude = dl.data_att.site_latitude
  endif else if s2 then begin
    latitude = dl.data_att.station_latitude
  endif
  
  ;longitude
  str_element,dl,'data_att.site_longitude',success=s1
  str_element,dl,'cdf.vatt.station_longitude',success=s2
  if s1 then begin
    longitude = dl.data_att.site_longitude
  endif else if s2 then begin
    longitude = dl.data_att.station_longitude
  endif

end

pro hdz2geo,data_in,data_out,latitude=lat,longitude=lon,geo2hdz=geo2hdz,error=e,rotation_matrix=rotation_matrix

  compile_opt idl2,hidden

  e=1 

  if n_params() lt 2 then begin
    dprint,'ERROR: Incorrect number of parameters passed to hdz2geo'
    return
  endif
  
  if n_elements(data_in) eq 0 then begin
    dprint,'data_in is not set"
    return
  endif
  
  if is_string(data_in) then begin
    if n_elements(tnames(data_in)) gt 1 then begin
      dprint,"ERROR: hdz2geo only supports one input at a time"
      return
    endif
    
    if ~keyword_set(tnames(data_in)) then begin
      dprint,"ERROR: string input is not valid tplot variable name" 
      return 
    endif
      
    get_data,data_in,data=d,limits=l,dlimits=dl
    
    hdz2geo_get_latlong,dl,latitude=data_lat,longitude=data_lon
    
    if n_elements(lat) eq 0 && n_elements(data_lat) ne 0 then begin
      lat = data_lat
    endif
    
    if n_elements(lon) eq 0 && n_elements(data_lon) ne 0 then begin
      lon = data_lon
    endif
    
    dat = d.y
  endif else begin
    dat = data_in
  endelse
  
  if n_elements(lat) eq 0 then begin
    dprint,"ERROR: Required site latitude cannot be found"
    return
  endif 
   
  if n_elements(lon) eq 0 then begin
    dprint,"ERROR: Required site longitude cannot be found"
    return
  endif
  
  dim = dimen(dat)
  
  if n_elements(dim) ne 2 then begin
    dprint,"Input data does not 2-dimensions"
    return
  endif 
  
  if dim[1] ne 3 then begin
    dprint,"Input data is not Mx3"
    return
  endif
  
  z_basis_vector = [cos(!DTOR*lat),0,-sin(!DTOR*lat)]
  x_basis_vector = [-cos(!DTOR*lon)*sin(!DTOR*lat),-sin(!DTOR*lon),-cos(!DTOR*lon)*cos(!DTOR*lat)]
  y_basis_vector = crossp(z_basis_vector,x_basis_vector)

  if ~keyword_set(geo2hdz) then begin
  
    str_element,dl,'data_att.coord_sys',coord_sys,success=s
    if s && strlowcase(coord_sys) ne 'hdz' then begin
      dprint,'Warning: Coordinate system of data is labeled as something other than hdz in variable dlimits'
    end
     
    str_element,dl,'data_att.coord_sys','hdz',/add
    rotation_matrix = [[x_basis_vector],[y_basis_vector],[z_basis_vector]]
    
  endif else begin
  
    str_element,dl,'data_att.coord_sys',coord_sys,success=s
    if s && strlowcase(coord_sys) ne 'geo' then begin
      dprint,'Warning: Coordinate system of data is labeled as something other than hdz in variable dlimits'
    end 
  
    str_element,dl,'data_att.coord_sys','geo',/add
    rotation_matrix = transpose([[x_basis_vector],[y_basis_vector],[z_basis_vector]])
    
  endelse
  
  str_element,dl,'data_att.site_latitude',lat,/add
  str_element,dl,'data_att.site_longitude',lon,/add
  
  result = make_array(dim,type=size(dat,/type))
  
  for i = 0,2 do begin
    result[*,i] = rotation_matrix[i,0]*dat[*,0]+rotation_matrix[i,1]*dat[*,1]+rotation_matrix[i,2]*dat[*,2]
  endfor
  
  if is_struct(d) && is_string(data_out) then begin
    
    str_element,d,'v',success=s
    if ~s then begin
      store_data,data_out,data={x:d.x,y:result},dlimit=dl,limit=l
    endif else begin
      store_data,data_out,data={x:d.x,y:result,v:d.v},dlimit=dl,limit=l
    endelse
    
  endif else begin
    data_out=result
  endelse
  
  e = 0
  
end
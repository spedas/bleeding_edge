;+
;
;NAME:
; tmake_map_table
;
;PURPOSE:
; Create the mapping table in geographic coordinates, and store tplot variable:
;
;SYNTAX:
; tmake_map_table, vname, mapping_alt = mapping_alt, grid = grid, mapsize = mapsize, in_km = in_km
;
;PARAMETER:
;  vname = tplot variable of airgrow data.
;
;KEYWOARDS:
;  mapping_alt = Mapping altitude.
;           The default is 110 km.
;  grid = grid size.
;         The default is 0.01.
;  mapsize = map size.
;            The default is an original image size. 
;  in_km = If in_km is set, unit is km.        
;
;CODE:
;  A. Shinbori, 15/07/2022.
;
;MODIFICATIONS:
;
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:
; $LastChangedDate:
; $LastChangedRevision:
; $URL $
;-
pro tmake_map_table, vname, mapping_alt = mapping_alt, grid = grid, mapsize = mapsize, in_km = in_km

  ;=====================================
  ;---Get data from tplot variable:
  ;=====================================
   if strlen(tnames(vname)) eq 0 then begin
      print, 'Cannot find the tplot vars in argument!'
      return
   endif
  
   get_data, vname, data = ag_data, alimits = alim ;---for airglow image

  ;---Get the information of site, date, and wavelength from tplot name:
   strtnames = strsplit(vname,'_',/extract)
  ;---Time in UT 
   date = ag_data.x[0]
  ;---Observation site (ABB code): 
   site = strtnames[2]
  ;---wavelength: 
   wavelength = strtnames[3]
 
  ;---Get the information of imgsize and mapsize from ag_data:
   imgsize = n_elements(reform(ag_data.y[0,*,0]))
   if ~keyword_set(mapsize) then  mapsize = imgsize

  ;---Set the map grid in a case of degree unit:
   if ~keyword_set(in_km) then begin
      if ~keyword_set(grid) then begin
        ;---longitudinal grid of map [deg]:
         grid_lon = 0.01d  
        ;---latitudinal grid of map [deg]:
         grid_lat = 0.01d  
      endif else begin
        ;---longitudinal grid of map [deg]:
         grid_lon = grid
        ;---latitudinal grid of map [deg]:
         grid_lat = grid
      endelse
   endif
  ;---Set the map grid in a case of km unit: 
   if keyword_set(in_km) then begin
      if ~keyword_set(grid) then begin
        ;---longitudinal grid of map [km]:
         grid_lon = 1.0d
        ;---latitudinal grid of map [km]:
         grid_lat = 1.0d
      endif else begin
        ;---longitudinal grid of map [deg]:
         grid_lon = grid
        ;---latitudinal grid of map [deg]:
         grid_lat = grid
      endelse
   endif
   
  ;---Set the mapping altitude:
  ;---The default is 110 km:
   if ~keyword_set(mapping_alt) then mapping_alt = 110.0d 
   mapping_alt = double(mapping_alt)

  ;---Width of the latitude and longitude that depend on both map and grid sizes:
   width_lon = mapsize * grid_lon  ;lonitude [deg]:
   width_lat = mapsize * grid_lat  ;latitude [deg]:

  ;----Get the OMTI Imager Attitude Parameters for Coordinate Transformation:
   result = omti_attitude_params(date = date, site = site)
   lon_obs = result[0]  ;longitude of observation site [deg]:
   lat_obs = result[1]  ;latitude of observation site [deg]:
   alt_obs = result[2]  ;altitude of observation site [km]:
   xcent = result[3]    ;x-location of the maximum elevation in an image map:
   ycent = result[4]    ;y-location of the maximum elevation in an image map:
   a_val = result[5]    ;A value = image diameter(pixel)/3.14159
   rot_d = result[6]    ;rotation angle [deg]:
  
  ;---If in_km is set, unit is km.
  ;---Set the map grid in a case of degree unit.
   if ~keyword_set(in_km) then begin
     map_unit = 'deg'
   endif else begin
     map_unit = 'km'
   endelse

  ;---Convertion of rotation angle from degree to radian:
   rot_d = !PI/180.0d * rot_d

  ;================Calculation of radius on Earth ellipsoid as a function of latitude===================
   a = 6378.140d   ;---Earth radius (Equator) [km]:  
   b = 6356.755d   ;---Earth radius (Pole) [km] 
  
  ;---The Earth radius at a latitude of a site location:
  ;---r=ab/sqrt(a^2sin^2+b^2cos^2):
   r = a * b / sqrt((a * sin(!PI/180.0d * lat_obs))^(2.0d) + (b * cos(!PI/180.0d * lat_obs))^(2.0d))
  ;=====================================================================================================
   
  ;---Definition of map and position array
   img_map = intarr(2, mapsize, mapsize)  ;for map data:
   img_pos = fltarr(2, mapsize)   ;for position data:
   
  ;====Identification of array number of image data corresponding to latitude (meridional)====
  ;====and longitude (zonal) values, and put the position data into the position array========
  ;---for loop of y direction:
   for j = 0, mapsize - 1 do begin  
     ;---Calculate the latitude of j location of image:
      if keyword_set(in_km) then begin
        ;---Distance from the map center
         y_img = (double(j) - double(mapsize)/(2.0d)) * double(grid)
        ;---Conversion from a distance to a degree: 
         lat_img = lat_obs + 180.0d /!PI * (y_img/(r + mapping_alt)) 
        ;---Input the position data (meridional direction):
         img_pos[1,j] = y_img
      endif else begin
        ;---Latitude from the map center:
         lat_img = lat_obs - width_lat/(2.0d) + double(j) * grid_lat
        ;---Input the position data (latitude):
         img_pos[1,j] = lat_img
      endelse
     ;---for loop of y direction:
      for i = 0, mapsize - 1 do begin  ;--for loop of x direction:
        ;---Calculate the longitude of i location of image:
         if keyword_set(in_km) then begin
           ;---Distance from the map center
            x_img = (double(i) - double(mapsize)/(2.0d)) * double(grid)
           ;---Conversion from a distance to a degree: 
            lon_img = lon_obs + 180.0d /!PI * (x_img/((r + mapping_alt) * cos(!PI/180.0d * lat_img)))
           ;---Input the position data (zonal direction):
            img_pos[0,i] = x_img
         endif else begin
           ;---Longitude from the map center: 
            lon_img = lon_obs -width_lon/(2.0d) + double(i) * grid_lon
           ;---Input the position data (longitude): 
            img_pos[0,i] = lon_img
         endelse
        ;---Radian value of the longitudinal difference from the j point to the image center: 
         aa_rad = !PI/180.0d * (lon_img - lon_obs) 
         
        ;---Radian value of the latitudinal difference from the pole to the i point:
         b_rad = !PI/180.0d * (90.0d - lat_img)    
         
        ;---Radian value of the latitudinal difference from the pole to the image center:
         c_rad = !PI/180.0d * (90.0d - lat_obs) 
         
         cosa = cos(b_rad) * cos(c_rad) + sin(b_rad) * sin(c_rad) * cos(aa_rad)
         sina = sqrt(1.0d - cosa^2.0d)

         if sina ne 0.0 then begin
            sinbb = sin(b_rad) * sin(aa_rad)/sina
            cosbb = (cos(b_rad) * sin(c_rad) - sin(b_rad) * cos(c_rad) * cos(aa_rad))/sina
            th_rad = atan((r + mapping_alt) * sina, (r + mapping_alt) * cosa - (r + alt_obs * 1.0d))

           ;---Correction for fish eye lens distortion ** OMTI version
            th = 180.0d /!PI * th_rad
            fc = (-2.3483712d * 10.^(-5.0d)) * th^(3.0d) + (0.0016958048d) * th^(2.0d) + (2.6996802d) * th^(1.0d) + (0.26921133d)
            r_fc = fc * a_val/(156.26124)
            x_fc = xcent + r_fc * sinbb
            y_fc = ycent + r_fc * cosbb
         endif else begin
            x_fc = xcent
            y_fc = ycent
         endelse

        ;---Correction for Rotation:
         x_zo = (2.0d) * xcent - x_fc
         x = (x_zo - xcent) * cos(rot_d) + (y_fc - ycent) * sin(rot_d) + xcent
         y = (y_fc - ycent) * cos(rot_d) - (x_zo - xcent) * sin(rot_d) + ycent
         if x ge 0 and y ge 0 and x lt imgsize and y lt imgsize then begin
            img_map[0,i,j] = round(x)
            img_map[1,i,j] = round(y)            
         endif
      endfor
   endfor
  ;=====================================================================================================
  
  ;========================
  ;---Store tplot variable:
  ;========================
   store_data, 'omti_asi_' + site + '_' + wavelength + '_gmap_table_' + strtrim(fix(mapping_alt), 2), data = {x:ag_data.x, map:img_map, pos:img_pos}
   options, 'omti_asi_' + site + '_' + wavelength + '_gmap_table_' + strtrim(fix(mapping_alt), 2), ztitle = map_unit

end

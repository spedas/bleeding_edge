pro draw_crustal_fields_on_map,contours = contours, thick = thick, $
                               color_negative = color_negative, $
                               color_positive = color_positive, $
                               color_table = color_table,$
                               br = br, bp = bp, bt = bt, bmag = bmag,$
                               elev = elev, charsize = charsize, $
                               no_labels = no_labels, altitude = altitude, $
                               Morschhauser = Morschhauser


  if not keyword_set (thick) then thick = 1
  if not keyword_set (color_table) then color_table = 0
  if not keyword_set (color_positive) then color_positive = 12
  if not keyword_set (color_negative) then color_negative =  134
  if not keyword_set (altitude) then altitude = 400.0


  longitude_array = 0.5+findgen (360)
  latitude_array = -89.5+ findgen (180)
  longitude_2d = longitude_array# replicate (1.0, 180)
  latitude_2d = latitude_array## replicate (1.0, 360)
  alt_map = 400.0

  nelon = 360L
  nlat = 180L

  latlong2cart, latitude_2d, longitude_2d,3390.0+ alt_map , x, y, z
  ntot = nelon*nlat
  x1d = reform (x,ntot)
  y1d = reform (y,ntot)
  z1d = reform (z,ntot)

; Crustal field map is kept in the same location as the ideal routines
  path = FILE_DIRNAME(ROUTINE_FILEPATH(), /mark)
  modelfile = path + 'Morschhauser_spc_dlat1.0_delon1.0_400km.sav'

; you can make this code run much faster by preloading the
; Morschhauser structure
  if not keyword_set (Morschhauser) then begin
     print, 'Restoring Morschhauser Structure. Use Morschhauser keyword for faster execution'
     restore,modelfile
  endif
  altitude_index = value_locate (Morschhauser.altitude, altitude)
; if the altitude requested is below the lowest level of the file,
; just take the lowest level
  If altitude_index eq -1 then altitude_index = 0
  bradius = reform (Morschhauser.b[0, altitude_index,*,*])
  btheta = reform (Morschhauser.b[1, altitude_index,*,*])
  bphi = reform (Morschhauser.b[2, altitude_index,*,*])
    
; now do one in geographic coverage
  loadct2,color_table
  !p.thick=2
  b_contours =[-200.0, -100.0, -50.0, -20.0, -10.0, $
               10.0,20.0, 50.0, 100.0, 200.0]
  elev_contours = [-75, -50, -25, 25, 50, 75]
  if keyword_set (bp) then z = bphi 
  if keyword_set (br) then z = bradius
  if keyword_set (bt) then z = btheta
  if keyword_set (bmag) then z = sqrt(bradius^2 +bphi^2 + btheta^2)
  if not keyword_set (contours) then begin
  if keyword_set (elev) then begin
     if not keyword_set (contours) then contours = elev_contours
     elev = asin(bradius/sqrt(bradius^2+bphi^2 + btheta^2))/!dtor
     z = elev 
  endif else contours = b_contours
  endif

  nc = n_elements (contours)
  
  
  if keyword_set (no_labels) then begin
     contour,reform (z, nelon, nlat),longitude_array, latitude_array,/over, levels = $
             contours [0:nc/2-1],c_color = color_negative, c_thick = thick
     contour,reform (z, nelon, nlat),longitude_array, latitude_array,/over, levels = $
             contours [nc/2:nc-1],c_color = color_positive, c_thick = thick
  endif else begin
     if not keyword_set (charsize) then charsize = 0.7
     contour,reform (z, nelon, nlat),longitude_array, latitude_array,/over, levels = $
             contours [0:nc/2-1],c_color = color_negative, c_thick = thick , $
             c_labels = replicate (1.0,nc), c_charsize = charsize
     contour,reform (z, nelon, nlat),longitude_array, latitude_array,/over, levels = $
             contours [nc/2:nc-1],c_color = color_positive, c_thick = thick , $
             c_labels = replicate (1.0,nc), c_charsize = charsize
  endelse
       
end

;+
;
;NAME:
; plot_omti_gmap
;
;PURPOSE:
; Create the two-dimensional map of image data in geographic coordinates.
;
;SYNTAX:
; plot_omti_gmap, vname, time = time, min_value = min_value, max_value = max_value
;
;PARAMETERS:
;  vname = tplot variable of image data.
;  
;  Example:
;   plot_omti_gmap, vname, time = time, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, z_min = z_min, z_max = z_max
;
;KEYWOARDS:
;  time = plot time. The default is start time of tplot variable.
;  min_value = minimum value of plot range. The default is the minimum value of image data.
;  max_value = maximum value of plot range. The default is the maximum value of image data.
;
;CODE:
;  A. Shinbori, 22/07/2022.
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
pro plot_omti_gmap, vname, time = time, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, z_min = z_min, z_max = z_max

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================
   if strlen(tnames(vname)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif
   
   get_data, vname, data = ag_data, alimits = alim1

  ;---Get the ABB code and mapping altitude from tplot name:
   strtnames = strsplit(tnames(vname),'_',/extract)
   if n_elements(strtnames) lt 8 then begin
     print, 'Wrong tplot variable.'
     return
   endif
  ;---Observation site (ABB code): 
   site = strtnames[2]
  ;---Wavelength: 
   wavelength = strtnames[3]
   wavelength = strtrim(string(float(wavelength)/10.0, F = '(f5.1)'), 2)
  ;---Data level (raw or abs) 
   level = strtnames[5]
  ;---Mapping altitude [km]: 
   altitude = strtnames[n_elements(strtnames)-1]
      
  ;--------------- Preparation for Plotting ----------------
  ;---Find the array number of image data corresponding to the input time:
   if ~keyword_set(time) then time = time_string(ag_data.x[0])
   idx = where(abs(ag_data.x - time_double(time)) eq min(abs(ag_data.x - time_double(time))), cnt)
   if cnt eq 0 then begin
     print, 'Out of time range'
     return
   endif

  ;---Set the plot range of x, y, and z axes:
   if ~keyword_set(x_min) then x_min = min(reform(ag_data.pos[0, *]))
   if ~keyword_set(x_max) then x_max = max(reform(ag_data.pos[0, *]))
   if ~keyword_set(y_min) then y_min = min(reform(ag_data.pos[1, *]))
   if ~keyword_set(y_max) then y_max = max(reform(ag_data.pos[1, *]))
   if ~keyword_set(z_min)  then begin
      z_min = min(reform(ag_data.y[idx[0], *, *]))
   endif
   if ~keyword_set(z_max) then z_max = max(reform(ag_data.y[idx[0], *, *]))
   
  ;---Set each axis title: 
   if alim1.ztitle eq 'deg' then begin
     xtitle = 'GLON [deg]'
     ytitle = 'GLAT [deg]'
   endif
   if alim1.ztitle eq 'km' then begin
     xtitle = 'Zonal [km]'
     ytitle = 'Meridional [km]'
   endif
   if level eq 'raw' then ztitle = 'Count'
   if level eq 'abs' then ztitle = 'Intensity [R]'
   idx_str = where(strtnames eq 'dev', cnt)
   if cnt ne 0 then ztitle = 'Normalized deviation'

  ;---Plot the image data in geographic coordinates:
   plotxyz, reform(ag_data.pos[0, *]), reform(ag_data.pos[1, *]), reform(ag_data.y[idx[0], *, *]), $
             xrange = [x_min,  x_max], yrange = [y_min,  y_max], zrange = [z_min,  z_max], $
             xtitle = xtitle, ytitle = ytitle, ztitle = ztitle, xmargin=[0.2,0.2]
  
  ;---Add the plot legends:           
   xyouts, 0.5, 0.86, time_string(ag_data.x[idx[0]]), alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
   xyouts, 0.5, 0.895, 'Mapping altitude: ' + altitude + ' [km]', alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
   xyouts, 0.5, 0.93, 'Wavelength: ' + wavelength + ' [nm]', alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
   xyouts, 0.5, 0.965, 'Station: '+strupcase(site), alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL  

end
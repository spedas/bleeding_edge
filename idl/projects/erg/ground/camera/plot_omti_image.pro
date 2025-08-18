;+
;
;NAME:
; plot_omti_gmap
;
;PURPOSE:
; Create the two-dimensional map of image data.
;
;SYNTAX:
; plot_omti_image, vname, time = time, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, z_min = z_min, z_max = z_max
;
;PARAMETERS:
;  vname = tplot variable of image data.
;
;KEYWOARDS:
;  time = plot time. The default is start time of tplot variable.
;  x_min = minimum value of x range. The default is the minimum value of image size.
;  x_max = maximum value of x range. The default is the maximum value of image size.
;  y_min = minimum value of y range. The default is the minimum value of image size.
;  y_max = maximum value of y range. The default is the maximum value of image size.
;  z_min = minimum value of z range. The default is the minimum value of image data.
;  z_max = maximum value of z range. The default is the maximum value of image data.
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
pro plot_omti_image, vname, time = time, x_min = x_min, x_max = x_max, y_min = y_min, y_max = y_max, z_min = z_min, z_max = z_max

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================
   if strlen(tnames(vname)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif
   get_data, vname, data = ag_data, ALIMITS = alim1

  ;---Get the ABB code and mapping altitude from tplot name:
   strtnames = strsplit(tnames(vname),'_',/extract)
   if n_elements(strtnames) lt 6 then begin
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
   
  ;--------------- Preparation for Plotting ----------------
  ;---Find the array number of image data corresponding to the input time:
   if ~keyword_set(time) then time = time_string(ag_data.x[0])
   idx = where(abs(ag_data.x - time_double(time)) eq min(abs(ag_data.x - time_double(time))), cnt)
   if cnt eq 0 then begin
     print, 'Out of time range'
     return
   endif
  ;---Set the image size from the image data array: 
   image_size = n_elements(reform(ag_data.y[0,*,0]))

  ;---Set the plot range of x, y, and z axes:
   if ~keyword_set(x_min) then x_min = 0
   if ~keyword_set(x_max) then x_max = image_size
   if ~keyword_set(y_min) then y_min = 0
   if ~keyword_set(y_max) then y_max = image_size
   if ~keyword_set(z_min)  then begin
      z_min = min(reform(ag_data.y[idx[0], *, *]))
   endif 
   if ~keyword_set(z_max) then z_max = max(reform(ag_data.y[idx[0],* , *]))

  ;---Set each axis and plot titles: 
   if level eq 'raw' then begin
      title = 'Raw image' 
      ztitle = 'Count'
   endif
   if level eq 'abs' then begin
     title = 'Absolute image'
     ztitle = 'Intensity [R]'
   endif
   idx_str = where(strtnames eq 'dev', cnt)
   if cnt ne 0 then ztitle = 'Normalized deviation'
   xtitle = 'Pixel'
   ytitle = 'Pixel'

  ;---Plot the image:
   plotxyz, indgen(image_size), indgen(image_size), reform(ag_data.y[idx[0],*,*]), $
             xrange = [x_min,  x_max], yrange = [y_min,  y_max], zrange = [z_min,  z_max], $
             xtitle = xtitle, ytitle = ytitle, ztitle = ztitle, xmargin=[0.2,0.2]

  ;---Add the plot legends:  
   xyouts, 0.5, 0.86, time_string(ag_data.x[idx[0]]), alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
   xyouts, 0.5, 0.895, title, alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL            
   xyouts, 0.5, 0.93, 'Wavelength: ' + wavelength + ' [nm]', alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
   xyouts, 0.5, 0.965, 'Station: '+strupcase(site), alignment = 0.5, orientation = 0., charsize = 1.2, color = 0, /NORMAL
  
end
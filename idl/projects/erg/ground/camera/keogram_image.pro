;+
;
;NAME:
; keogram_image
;
;PURPOSE:
; Create the keogram of image data at a spesific location.
;
;SYNTAX:
; keogram_image, vname, lat = lat, lon = lon 
;
;PARAMETERS:
;  vname = tplot variable of image data.
;
;  Example:
;   plot_omti_gmap, vname, lat = lat, lon = lon
;
;KEYWOARDS:
;  lat = latitude to creat a longitude-time plot of image data.
;  lon = longitude to creat a latitude-time plot of image data.
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
pro keogram_image, vname, lat = lat, lon = lon

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================
   if strlen(tnames(vname)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif

  ;---Get the ABB code and mapping altitude from tplot name:
   strtnames = strsplit(tnames(vname),'_',/extract)
   if n_elements(strtnames) lt 8 then begin
     print, 'Wrong tplot variable.'
     return
   endif
   
   get_data, vname, data = ag_data, alimits = alim1
   
   site = strtnames[2]
   wavelength = strtnames[3]
   wavelength = strtrim(string(float(wavelength)/10.0, F = '(f5.1)'), 2)
   level = strtnames[5]
   altitude = strtnames[n_elements(strtnames)-1]

   if ~keyword_set(lat) then lat = 60.0
   if ~keyword_set(lon) then lon = 240.0 
   
   sglat = strtrim(string(float(lat), F = '(f5.1)'), 2)
   sglon = strtrim(string(float(lon), F = '(f5.1)'), 2)
   
   idx_lon = where(abs(reform(ag_data.pos[0,*]) - lon) eq min(abs(reform(ag_data.pos[0,*])- lon)), cnt)
   idx_lat = where(abs(reform(ag_data.pos[1,*]) - lat) eq min(abs(reform(ag_data.pos[1,*]) - lat)), cnt)
   
   keogram_lon_time = reform(ag_data.y[*,*, idx_lat[0]])
   keogram_lat_time = reform(ag_data.y[*,idx_lon[0], *])

  ;--------------- Preparation for setting tplot variables ----------------
   if alim1.ztitle eq 'deg' then begin
      ytitle_lat = 'Station: ' + strupcase(site) + '!CWavelength: ' + wavelength + '!CSlice GLON: ' + sglon + ' [deg]!CGLAT [deg]'
      ytitle_lon = 'Station: ' + strupcase(site) + '!CWavelength: ' + wavelength + '!CSlice GLAT: ' + sglat + ' [deg]!CGLON [deg]'
   endif
   if alim1.ztitle eq 'km' then begin
     ytitle_lat = 'Station: ' + strupcase(site) + '!CWavelength: ' + wavelength + '!CZonal [km]'
     ytitle_lon = 'Station: ' + strupcase(site) + '!CWavelength: ' + wavelength + '!CMeridional [km]'
   endif
   if level eq 'raw' then ztitle = 'Count'
   if level eq 'abs' then ztitle = 'Intensity [R]'
   idx_str = where(strtnames eq 'dev', cnt)
   if cnt ne 0 then ztitle = 'Normalized deviation'
      
  ;========================
  ;---Store tplot variable:
  ;========================
   store_data, vname + '_keogram_lon_' + strtrim(fix(lon), 2), data = {x:ag_data.x, y:keogram_lat_time, v:reform(ag_data.pos[1,*])}
   options, vname + '_keogram_lon_' + strtrim(fix(lon), 2), ytitle = ytitle_lat, ztitle = ztitle, spec = 1
   store_data, vname + '_keogram_lat_' + strtrim(fix(lat), 2), data = {x:ag_data.x, y:keogram_lon_time, v:reform(ag_data.pos[0,*])}
   options, vname + '_keogram_lat_' + strtrim(fix(lat), 2), ytitle = ytitle_lon, ztitle = ztitle, spec = 1

end
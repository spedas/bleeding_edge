;+
;
;NAME:
; tasi2gmap
;
;PURPOSE:
; Create the image data in geographic coordinates, and store tplot variable:
;
;SYNTAX:
; tasi2ggg, vname1, vname2
;
;PARAMETER:
;  vname1 = tplot variable of airgrow data.
;  vname2 = tplot variable of map table data.
;
;KEYWOARDS:
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
pro tasi2gmap, vname1, vname2

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================
   if strlen(tnames(vname1)) * strlen(tnames(vname2)) eq 0 then begin
      print, 'Cannot find the tplot vars in argument!'
      return
   endif

   get_data, vname1, data = ag_data, alimits = alim1 ;---for airglow image data:
   get_data, vname2, data = map_table_data, alimits = alim2 ;---for map table data:

  ;---Get the information of tplot name:
   strtnames = strsplit(tnames(vname1),'_',/extract)
  ;---Time in UT: 
   date = ag_data.x[0]
  ;---Observation site (ABB code): 
   site = strtnames[2]
  ;---Wavelength:  
   wavelength = strtnames[3]
  ;---Data level (raw or abs):
   level = strtnames[5]
  ;---Get the information of tplot name: 
   strtnames = strsplit(tnames(vname2),'_',/extract)
  ;---Mapping altitude [km]:  
   altitude = strtnames[6]  

  ;---Definition of parameters for convert loop:
  ;---Map saize from pos array size:
   mapsize = n_elements(reform(map_table_data.pos[0,*]))
  ;---Array of image data in geographic coordinates: 
   image_gmap = fltarr(n_elements(ag_data.x), mapsize, mapsize)

  ;---Convert loop in geographic coordinates:
   for i = 0, n_elements(ag_data.x) - 1 do begin
      img_t = reform(ag_data.y[i,*,*])
      image_gmap[i,*,*] = img_t[map_table_data.map[0, indgen(mapsize), indgen(mapsize)], map_table_data.map[1, indgen(mapsize), indgen(mapsize)]]
      nowi = string(i + 1, format = '(I3.3)')
      print, 'now converting... : ', time_string(ag_data.x[i])
   endfor

  ;========================
  ;---Store tplot variable:
  ;========================
   store_data, vname1 + '_gmap_' + strtrim(fix(altitude), 2), data = {x:ag_data.x, y:image_gmap, pos:map_table_data.pos}
   options, vname1 + '_gmap_' + strtrim(fix(altitude), 2), ztitle = alim2.ztitle 

end
;+
;
;NAME:
; tmake_image_dev
;
;PURPOSE:
; Calculates the deviation of image data from 1-hour verage data and store tplot variable:
;
;SYNTAX:
; tmake_image_dev, vname, width = width
;
;PARAMETERS:
;  vname = tplot variable of image data.
;
;  Example
;   tmake_image_dev, 'omti_asi_sgk_5577_image_raw'
;
;KEYWOARDS:
;  width = Period of data window to calculate the average value.
;         The default is 3600 sec.
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

pro tmake_image_dev, vname, width = width

  ;=====================================
  ;---Get data from two tplot variables:
  ;=====================================
   if strlen(tnames(vname)) eq 0 then begin
      print, 'Cannot find the tplot var in argument!'
      return
   endif
   
   get_data, vname, data = ag_data, ALIMITS = alim1
  
  ;---Definition of arrays for deviation and average data: 
  ;---Map size:
   mapsize = n_elements(reform(ag_data.y[0,*,0]))
  ;---Deviation from 1-hr average image data:
   dev = fltarr(n_elements(ag_data.x), mapsize, mapsize)+0.0

  ;---Keyword check (width):
   if ~keyword_set(width) then begin
      h = 3600.0d   ; 1-h
   endif else begin
      h = width
   endelse
   
   for i = 0, n_elements(ag_data.x) - 1 do begin
     ;---Definition of array used in average calculation and initializing it 
      avg = fltarr(mapsize, mapsize)+0.0
     ;---Search the data number within a time rage from t-width/2 to t+width/2 [sec]: 
      res = where(ag_data.x ge ag_data.x[i] - h/2.0d and ag_data.x le ag_data.x[i] + h/2.0d, nres)
      if nres ne 0 then begin
        ;---Calculation of total value of image data within a time rage from t-width/2 to t+width/2 [sec]: 
         for j = 0, nres - 1 do begin
            avg[*,*] = avg[*,*] + reform(ag_data.y[res[j],*,*]) * 1.0
         endfor
        ;---Average data:  
         avg = avg/nres
        ;---Replace zero value of average data into 1 to use normalization:
         den_avg = avg
         idx_avg = where(avg eq 0)
         den_avg[idx_avg] = 1.0
        ;---Normalized deviation of image data:
         dev[i,*,*] = (float(reform(ag_data.y[i,*,*])) - avg)/den_avg
         dev[i,*,*] = dev[i,*,*] - mean(dev[i,*,*],/NAN)
      endif
   endfor

  ;========================
  ;---Store tplot variable:
  ;========================
   store_data, vname +'_dev', data = {x:ag_data.x, y:dev}

end
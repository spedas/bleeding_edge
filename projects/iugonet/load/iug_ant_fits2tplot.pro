;-----------------------------------------------
; Load IPRT/AMATERAS high resolution data
; 
; Ver 1.0   2019-06-21  F. Tsuchiya
;-----------------------------------------------
;
pro iug_ant_fits2tplot, file_in, subtract_bg=subtract_bg

;  if not keyword_set(dir)     then dir     = 'C:\Data\AMT\Lv1\'
  if not keyword_set(file_in) then file_in = 'iprt_amt_high_8bit_20140212-0026.fits'

  ;------------------------------
  ; Read data from the fits file
  ;------------------------------
  fits_read,file_in,data,hd
    
  ;------------------------------
  ; Read fits header (Time info)
  ;------------------------------
  DATE_OBS = sxpar(hd,'DATE-OBS')  ; / START time of EUV data acquisition
  DATE_END = sxpar(hd,'DATE-END')  ; / END   time of EUV data acquisition
  TIME_OBS = sxpar(hd,'TIME-OBS')  ; / START time of EUV data acquisition
  TIME_END = sxpar(hd,'TIME-END')  ; / END   time of EUV data acquisition
  ds = long(strsplit(DATE_OBS,'-T:',/extract))
  de = long(strsplit(DATE_END,'-T:',/extract))
  ts = long(strsplit(TIME_OBS,'-T:',/extract))
  te = long(strsplit(TIME_END,'-T:',/extract))
  jd_s = julday(ds[1],ds[2],ds[0],ts[0],ts[1],ts[2])
  jd_e = julday(de[1],de[2],de[0],te[0],te[1],te[2])
  jd0 = (jd_s+jd_e)*0.5d
  
  ;------------------------------
  ; Read fits header (Axes info)
  ;------------------------------
  BZERO  = sxpar(hd,'BZERO')   ; / 
  BSCALE = sxpar(hd,'BSCALE')  ; / 
  CRPIX1 = sxpar(hd,'CRPIX1')  ; /
  CRVAL1 = sxpar(hd,'CRVAL1')  ; /
  CDELT1 = sxpar(hd,'CDELT1')  ; /
  CRPIX2 = sxpar(hd,'CRPIX2')  ; /
  CRVAL2 = sxpar(hd,'CRVAL2')  ; /
  CDELT2 = sxpar(hd,'CDELT2')  ; /

  m = sxpar(hd,'NAXIS1')
  n = sxpar(hd,'NAXIS2')
  x = CRVAL1 + (findgen(m)+CRPIX1) * CDELT1  ; [sec]
  y = CRVAL2 + (findgen(n)+CRPIX2) * CDELT2  ; [MHz]

  ;------------------------------
  ; Convert data unit to dB 
  ;------------------------------
  data_r = BZERO + float(data[*,*,0]) * BSCALE   ; [dB]
  data_l = BZERO + float(data[*,*,1]) * BSCALE   ; [dB]

  ;------------------------------
  ; Subtract background spectrum
  ;------------------------------
  if keyword_set(subtract_bg) then begin
    min_r = fltarr(n)
    min_l = fltarr(n)
    for i=0,n-1 do begin
      min_r[i] = min(data_r[*,i])
      min_l[i] = min(data_l[*,i])
    endfor
    for i=0,m-1 do begin
      data_r[i,*] -= min_r
      data_l[i,*] -= min_l
    endfor
  endif

  ;------------------------------
  ; Store data to TPLOT variable
  ;------------------------------
  caldat, jd_s, mm0,dd1,yy1,hh1,mn1,ss1
  caldat, jd_e, mm1,dd1,yy1,hh1,mn1,ss1
  jd = [jd_s,jd_e]
  td = (jd - julday(1,1,1970,0,0,0))*24.0*60.0*60.0   ; unix time
  delta_t = (td[1]-td[0])/double(m)
  td_data = td[0] + dindgen(m)*delta_t
  
  store_data, 'iprt_r', data={x:td_data,y:data_r,v:y}, dlim={spec:1}
  store_data, 'iprt_l', data={x:td_data,y:data_l,v:y}, dlim={spec:1}
    
  tvar = ['iprt_r','iprt_l']
  options, tvar, 'charsize', 1.2
  options, tvar, 'ysubtitle', 'Frequency [MHz]'
  if not keyword_set(subtract_bg) then begin
    options, tvar, 'ztitle', '[dB] from quiet Sun level'
    options, 'iprt_r', 'ytitle', 'IPRT RH'
    options, 'iprt_l', 'ytitle', 'IPRT LH'
    zlim, tvar, 0, 25.0, 0
  endif else begin
    options, tvar, 'ztitle', '[dB] from background'
    options, 'iprt_r', 'ytitle', 'IPRT LH (subtract bg)'
    options, 'iprt_l', 'ytitle', 'IPRT LH (subtract bg)'
    zlim, tvar, 0, 10.0, 0
  endelse
  
;  timespan, [td_data[0],td_data[m-1]]
 
end

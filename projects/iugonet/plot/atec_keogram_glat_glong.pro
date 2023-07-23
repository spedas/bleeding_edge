;+
;
;NAME:
; atec_keogram_glat_glong
;
;PURPOSE:
;  Create a keogram of the subtracted TEC (Total Electron Content) data
;  provided by the DRAWING/PWING projects and and loads data into tplot format.
;
;SYNTAX:
; atec_keogram_glat_glong,  glong = glong
;
;KEYWOARDS:
;  glong = specify the geographic longitude of a TEC keogram.
;              The default is 0.
;
;CODE:
; A. Shinbori, 06/10/2021.
;
;MODIFICATIONS:
;
;
;ACKNOWLEDGEMENT:
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision:  $
; $URL $
;-

pro atec_keogram_glat_glong, glong = glong

  ;**********************
  ;***Chek keyword***
  ;**********************
  ;--- all glong values (default)
   glong_all = strsplit('0.0 30.0 60.0 90.0 120.0 150.0 180.0 210.0 240.0 270.0 300.0 330.0',' ', /extract)

   ;--- check parameters
   if(not keyword_set(glong)) then begin
      glong ='all'
      glongs = ssl_check_valid_name(glong, glong_all, /ignore_case, /include_all)
   endif else begin
    if glong[0] eq 'all' or glong[0] eq '*' then begin
      glongs = glong_all[1:n_elements(glong_all )-1]
    endif
     glongs = glong
   endelse
   
   
 ;  if glongs[0] eq '*' then glong = glongs[1:n_elements(glong)-1]

   print, glongs

   glong = float(glongs)

  ;---Get data from tplot variable 'nict_gps_atec_global' :
   get_data,  'iug_gps_atec', data = atec, dlimit=str
   tec = atec.y

  ;------------------------------------------------------------------------------------------------------------------------------
  ;==============================================================================================================================
  ;------------------------------------------------ Create the keogram data------------------------------------------------------
  ;---Convert the eastern longitude:
   idx = where(glong ge 180.0, cnt)
   if idx[0] ne -1 then glong[idx] = glong[idx] -360.0

   for i = 0, n_elements(glong)-1 do begin
    
     ;---Longitude array number corresponding to the specified longitude:
      index_glong = where(abs(atec.glon - glong[i]) eq  min(abs(atec.glon - glong[i])))

     ;---Select the TEC data to plot a keogram:
      atec_keogram = reform(atec.y[*, index_glong[0], *])
      idx2 = where(glong lt 0.0, cnt)
      if idx2[0] ne -1 then glong[idx2] = 360.0 + glong[idx2]

     ;----Store tplot variable of the specified geographic longitude:  
      store_data, 'atec_keogram_geocoord_' + strtrim(string(glong[i], format='(f5.1)'),2), data = {x:atec.x, y:atec_keogram,v:atec.glat, glon:atec.glon}, dlimit=str
      options, 'atec_keogram_geocoord_' + strtrim(string(glong[i], format='(f5.1)'),2), ytitle = 'GLAT [deg]', ztitle = 'TEC!C(GLONG:'+strtrim(string(glong[i], format='(f5.1)'),2)+' [deg])!C[10!U16!N/m!U2!N]', spec = 1
      zlim,'atec_keogram_geocoord_' + strtrim(string(glong[i], format='(f5.1)'),2),0, 40
   endfor
  ;--------------------------------------------Create the keogram data END-------------------------------------------------------
  ;==============================================================================================================================
  ;------------------------------------------------------------------------------------------------------------------------------
end
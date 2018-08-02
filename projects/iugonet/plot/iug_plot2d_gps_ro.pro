;+
;
;NAME:
;  iug_plot2d_gps_ro
;
;PURPOSE:
;  Generate several height-latitude profile from the GPS radio occultation data
;  taken by the CHAMP and COSMIC satellites.
;
;SYNTAX:
;  iug_plot2d_gps_ro, valuename1 = valuename1, valuename2 = valuename2
;
;KEYWOARDS:
;
;  SITE = LEO satellite name. CHAMP and COSMIC are available as an input satellite name.
;         The default is 'cosmic'.
;
;CODE:
;  A. Shinbori, 14/05/2016.
;
;MODIFICATIONS:
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro iug_plot2d_gps_ro, site = site

  ;*******************
  ;Site keyword check:
  ;*******************
  if not keyword_set(site) then site = 'cosmic'
  
  ;---Definition of tplot variable names
  valuename1 = 'gps_ro_'+site+'_fsi_tan_lat'
  valuename2 = 'gps_ro_'+site+'_fsi_temp'
  valuename3 = 'gps_ro_'+site+'_fsi_pres'
  valuename4 = 'gps_ro_'+site+'_fsi_ref'


  ;window,0,xs=512,ys=512
  ;loadct,39

  ;Get the GPS radio occultation data from tplot variable:
  if strlen(tnames(valuename1[0])) eq 0 and strlen(tnames(valuename2[0])) eq 0 $
     and strlen(tnames(valuename3[0])) eq 0 and strlen(tnames(valuename4[0])) eq 0 then begin
    print, 'Cannot find the tplot vars in argument!'
    return
  endif

  get_data, valuename1, data = gps_tan_lat  
  get_data, valuename2, data = gps_temp
  get_data, valuename3, data = gps_pres
  get_data, valuename4, data = gps_ref


  ;----Zonal-mean value:
  for i=0, 400-1 do begin
    for k=0, 180 do begin
      if i eq 0 then begin
        if k eq 0 then begin
          mean_temp = fltarr(181,n_elements(gps_temp.v))+!values.f_nan
          mean_ref = fltarr(181,n_elements(gps_ref.v))+!values.f_nan
          mean_pres = fltarr(181,n_elements(gps_pres.v))+!values.f_nan
        endif
        append_array, lat_app, -90.0 + 1.0*k
      endif
      idxz = where(gps_tan_lat.y[*,i] ge -90.0 + 1.0*(k-3.0) and gps_tan_lat.y[*,i] lt -90.0 + 1.0*(k+3.0))
      mean_temp[k,i] = mean(gps_temp.y[idxz,i],/NAN)
      mean_ref[k,i] = mean(gps_ref.y[idxz,i],/NAN)
      mean_pres[k,i] = mean(gps_pres.y[idxz,i],/NAN)
    endfor
  endfor
  
  ;----Plot the hight-latitude prfile of zonal-mean value:
  
  window,0,xs=1500,ys=500
  
  plotxyz,lat_app, gps_ref.v, smooth(mean_ref,2,/NAN), multi='3,1', xtitle = 'Latitude [deg]', ytitle = 'Height [km]', ztitle = 'Zonal-mean refractivity [N]',$
           xmargin= [0.10,0.20],ymargin= [0.11,0.05],xrange = [-90,90],yrange = [0,40],xticks=12,xminor=5,yticks=8,yminor=5,$
           /noisotropic,/interpolate,title = strupcase(site)+' ('+strmid(time_string(gps_ref.x[0]),0,10)+')'
  
  plotxyz,lat_app, gps_pres.v, smooth(mean_pres,2,/NAN),xtitle = 'Latitude [deg]', ytitle = 'Height [km]', ztitle = 'Zonal-mean pressure [hPa]',$
           xmargin= [0.10,0.20],ymargin= [0.11,0.05],xrange = [-90,90],yrange = [0,40],xticks=12,xminor=5,yticks=8,yminor=5,$
           /noisotropic,/interpolate,/add,title = strupcase(site)+' ('+strmid(time_string(gps_pres.x[0]),0.16)+')'
  
  plotxyz,lat_app, gps_temp.v, smooth(mean_temp,2,/NAN),xtitle = 'Latitude [deg]', ytitle = 'Height [km]', ztitle = 'Zonal-mean temperature [degree C]',$
           xmargin= [0.10,0.20],ymargin= [0.11,0.05],xrange = [-90,90],yrange = [0,40],zrange = [-100,20],xticks=12,xminor=5,yticks=8,yminor=5,$
           /noisotropic,/interpolate,/add,title = strupcase(site)+' ('+strmid(time_string(gps_temp.x[0]),0,10)+')'


end
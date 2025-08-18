;+
; NAME:
;     SOLARWIND_LOAD_WIND
;
; PURPOSE:
;	Plug-in subroutine for driver routine solarwind_load.pro provides 
;	solar wind (SW) data time-shifted to the bow-shock
;	nose. Time resolution of data is variable with 1 minute as finest.
;	SW data sources: WIND SWE and MFI. Time shifting of the WIND
;	data is based on the OMNI-2 metodology.
;	Important difference is that we first average and then propagate
;	averaged WIND quantities to the Earth. If there still is a strong
;	irregularity in the SW speed after averaging, the code warns user.
;	In all cases of insufficient data, the code produces nominal static
;	SW parameters, following SPDF standards. 
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	solarwind_load_wind,iswind,times,timee,swdata,resol
;
; INPUTS:
;	times : - start time (at the magnetopause) for SW data (double UNIX time or
;		any other TDAS time format)
;	timee : - end time, formatted as above
;	resol : desired time resolution of the output data in seconds
;		- if not set, SW data are provided in original time resolution
;
; KEYWORDS: None
;
; PARAMETERS: 3 parameters for outlier filtering are propagated through the 
;		common block from the main driver solarwind_load.
;
; OUTPUTS:
;	iswind - 1 if WIND data are found and 0 otherwise
;	swdata: | t | Dp | Bz | of IMF at the bow-shock nose
;		- 2D double array (ntpoints,3)
;
; DEPENDENCIES: convolve_gaussian_1d.pro, remove_outliers.pro, repair.pro,
;     wi_swe_load.pro, wi_mfi_load.pro, get_data.pro,
;		xclip.pro, xdegap.pro, xdeflag.pro, cotrans.pro. The code is a
;		lowest-level part of LMN transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;	Modified by Vladimir Kondratovich 2008/03/31.
;-
;
; THE CODE BEGINS:

pro solarwind_load_wind,iswind,times,timee,swdata,resol
;Get WIND data++++++++
common filtpar,d,tmax,nmax

isswe=0
ismfi=0
iswind=0
timss=times-7200.;sec - grab two extra hours in view of delay

;get data
wi_swe_load,trange=[timss,timee]
wi_mfi_load,trange=[timss,timee]
get_data,'wi_swe_V_GSE',timeswe,vswgse
get_data,'wi_swe_Np',timeswe,np
get_data,'wi_h0_mfi_B3GSE',timemfi,bswgse

;select data chunk to study
indswe=where(timeswe gt times and timeswe lt timee,nswe)
if nswe gt 1 then begin
   isswe=1
   vswgse=vswgse[indswe,*]
   np = np[indswe]
   tswe=timeswe[indswe]
endif else begin
   isswe=0
   print,'solarwind_load: No SWE data found.'
   print,'Static values Dp=2.088 nPa and Bz=0 are set.'
endelse

if isswe then begin
   iswind=1
   ;retain only good values:
   ;replace fill values with NaNs
   amm=0.999*max(abs(vswgse))
   xclip,-amm,amm,vswgse
   amm=0.999*max(abs(np))
   xclip,-amm,amm,np

   ;remove outliers
   remove_outliers,tswe,vswgse,d,tmax,nmax
   remove_outliers,tswe,np,d,tmax,nmax

   ;fill in the gaps
   delt=tswe-shift(tswe,1)
   delt=delt[1:*]
   dtswe=median(delt)
   margswe=0.3*dtswe
   xdegap,dtswe,margswe,tswe,vswgse,tgridv,vswgsenan;,/nowarning
   sss=size(vswgsenan)
   if sss[0] lt 1 then begin
      vswgsenan=vswgse
      tgridv=tswe
   endif
   xdegap,dtswe,margswe,tswe,np,tgridnp,npnan;,/nowarning
   sss=size(npnan)
   if sss[0] lt 1 then begin
      npnan=np
      tgridnp=tswe
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgridv,vswgsenan,flag=fl
   xdeflag,'linear',tgridnp,npnan,flag=fl

   ;convolve to req'd resolution
   if n_elements(resol) gt 0 then begin
      convolve_gaussian_1d,resol,tgridv,vswgsenan,vpgse
      convolve_gaussian_1d,resol,tgridnp,npnan,npgse
   endif else begin
      vpgse=vswgsenan
      npgse=npnan
   endelse

   ;adjust time
   dist=1500000.;km - average distance WIND - magnetopause
   tearthv=tgridv+abs(dist/reform(vpgse[*,0]))
   tearthnp=tgridnp+abs(dist/reform(vpgse[*,0]))

   ;check signs
   dtev=tearthv-shift(tearthv,1)
   dtev=dtev[1:*]
   indneg=where(dtev lt 0.,nneg)
   if nneg gt 1 then begin
      t1=tgridv[indneg[0]]
      t2=tgridv[indneg[nneg-1]]
      print,'Attention: strong irregularities in solar wind speed detected.'
      print,'Start time at WIND:',t1
      print,'End time at WIND:',t2
      print,'More sophisticated approach to propagation may be necessary.'
      print,'You also can try to decrease requested time resolution.'
   endif

   ;interpolate onto the output grid
   noutswe=long((timee-times)/dtswe + 1L)
   fgridswe=times+dtswe*lindgen(noutswe)
   vswgseout=fltarr(noutswe,3)
   for ii=0,2 do begin
      vpgsei=reform(vpgse[*,ii])
      vswgseouti=interpol(vpgsei,tearthv,fgridswe)
      vswgseout[*,ii]=vswgseouti
   endfor
   npswgseout=interpol(npgse,tearthnp,fgridswe)

   vpout=sqrt(vswgseout[*,0]^2+vswgseout[*,1]^2+vswgseout[*,2]^2)
   cotrans,vswgseout,vswgsmout,fgridswe,/gse2gsm

;   dp=1.67e-6*npswgseout*vpout^2
   dp=2.e-6*npswgseout*vpout^2
   dpout=dp
   tgrid=fgridswe


   indmfi=where(timemfi gt times and timemfi lt timee,nmfi)
   if nmfi gt 1 then begin
      ismfi=1
      bswgse = bswgse[indmfi,*]
      tmfi=timemfi[indmfi]
   endif else begin
      ismfi=0
      print,'solarwind_load: No MFI data found.'
      print,'Bz=0 nT instead of dynamic Bz is set.'
   endelse

   if ismfi then begin
      ;retain only good values:
      ;replace fill values with NaNs
      amm=0.999*max(abs(bswgse))
      xclip,-amm,amm,bswgse

      ;remove outliers
      remove_outliers,tmfi,bswgse,d,tmax,nmax

      ;fill in the gaps
      delt=tmfi-shift(tmfi,1)
      delt=delt[1:*]
      dtmfi=median(delt)
      margmfi=0.3*dtmfi
      xdegap,dtmfi,margmfi,tmfi,bswgse,tgridb,bswgsenan;,/nowarning
      sss=size(bswgsenan)
      if sss[0] lt 1 then begin
         bswgsenan=bswgse
         tgridb=tmfi
      endif

      ;interpolate onto the grid
      fl=!values.f_nan
      xdeflag,'linear',tgridb,bswgsenan,flag=fl

      ;convolve to req'd resolution
      if n_elements(resol) gt 0 then begin
         convolve_gaussian_1d,resol,tgridb,bswgsenan,bgse
      endif else begin
         bgse=bswgsenan
      endelse

      vrel=reform(vpgse[*,0])
      vrelm=abs(interpol(vrel,tgridv,tgridb))

      ;adjust time
      dist=1500000.;km - average distance WIND - magnetopause
      tearthb=tgridb+dist/vrelm

      ;interpolate onto the output grid
      noutmfi=long((timee-times)/dtmfi + 1L)
      fgridmfi=times+dtmfi*lindgen(noutmfi)
      bswgseout=fltarr(noutmfi,3)
      for ii=0,2 do begin
         bgsei=reform(bgse[*,ii])
         bswgseouti=interpol(bgsei,tearthb,fgridmfi)
         bswgseout[*,ii]=bswgseouti
      endfor

      cotrans,bswgseout,bswgsmout,fgridmfi,/gse2gsm

      bzout=reform(bswgsmout[*,2])
      dpout=interpol(dp,fgridswe,fgridmfi)
      tgrid=fgridmfi
      swdata=[[tgrid],[dpout],[bzout]]
   endif else begin; ismfi
      bzout=fltarr(noutswe)
      swdata=[[tgrid],[dpout],[bzout]]
   endelse
endif; isswe

return
end

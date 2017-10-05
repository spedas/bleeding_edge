;+
; NAME:
;     SOLARWIND_LOAD_HRO
;
; PURPOSE:
;	Plug-in subroutine for driver routine solarwind_load.pro provides 
;	solar wind (SW) data time-shifted to the bow-shock
;	nose. Time resolution of data is variable with 1 minute as finest.
;	SW data source: High Resolution OMNI. It is already time-shifted.
;	In all cases of insufficient data, the code produces nominal static
;	SW parameters, following SPDF standards. 
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	solarwind_load_hro,ishro,times,timee,swdata, resol=resol, min5=min5
;
; INPUTS:
;	times : - start time (at the magnetopause) for SW data (double UNIX time or
;		any other TDAS time format)
;	timee : - end time, formatted as above
; OPTIONAL INPUT:
;	resol  : desired time resolution of the output data in seconds (double)
;		- if not set, SW data are provided in original time resolution
;
; KEYWORDS:
;	min5 - use 5 min HRO merged database (default is to use 1 min HRO merged data)
;
; PARAMETERS: fill values taken from HRO web site
;
; OUTPUTS:
;	ishro - 1 if HRO data are found and 0 otherwise
;	swdata: | t | Dp | Bz | of IMF at the bow-shock nose
;		- 2D double array (ntpoints,3)
;
; DEPENDENCIES: convolve_gaussian_1d.pro, omni_hro_load.pro, get_data.pro,
;		xclip.pro, xdegap.pro, xdeflag.pro. The code is a
;		lowest-level part of LMN transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;	Modified by Vladimir Kondratovich 2008/03/31.
;-
;
; THE CODE BEGINS:

pro solarwind_load_hro,ishro,times,timee,swdata,resol,min5=min5
;Get HRO data+++++++

isdp=0
isbz=0
ishro=0

;get data
if keyword_set(min5) then begin
   omni_hro_load,trange=[times,timee],/res5min
   get_data,'OMNI_HRO_5min_BZ_GSM',timeomn,bzgsm
   get_data,'OMNI_HRO_5min_Pressure',timeomn,dp
endif else begin
   omni_hro_load,trange=[times,timee]
   get_data,'OMNI_HRO_1min_BZ_GSM',timeomn,bzgsm
   get_data,'OMNI_HRO_1min_Pressure',timeomn,dp
endelse
indhro=where(timeomn ge times and timeomn le timee,nhro)
if nhro gt 1 then begin
   ishro=1
   timeomni=timeomn[indhro]
   bzgsm=bzgsm[indhro]
   dp=dp[indhro]
   maxbz=max(bzgsm)
   indbz=where(bzgsm lt maxbz,nbz)
   if nbz gt 1 then isbz=1
   maxdp=max(dp)
   inddp=where(dp lt maxdp,ndp)
   if ndp gt 1 then isdp=1
   nomni=n_elements(timeomni)
   tgrid=timeomni
endif else begin
   print,'solarwind_load_hro: no HRO data found for requested interval. Exiting.'
   return
endelse

if isdp then begin
   ;retain only good values:
   ;replace fill values with NaNs
   amm=99.;0.999*max(dp)
   xclip,-amm,amm,dp

   ;fill in the gaps
   tgrid=timeomni
   if keyword_set(min5) then dtomni=300. else dtomni=60.;sec
   margomni=0.3*dtomni
   xdegap,dtomni,margomni,timeomni,dp,tgrid,dpnan;,/nowarning
   sss=size(dpnan)
   if sss[0] lt 1 then begin
      dpnan=dp
      tgrid=timeomni
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgrid,dpnan,flag=fl

   ;convolve to req'd resolution
   if n_elements(resol) gt 0 then begin
      convolve_gaussian_1d,resol,tgrid,dpnan,dp
   endif else dp=dpnan
   dpout=dp
endif else begin; isdp
   dpout=fltarr(nomni)+2.088; nPa
   print,'solarwind_load: No HRO Dp data found.'
   print,'I set static values Dp=2.088 nPa.'
endelse

if isbz then begin
   ;retain only good values:
   ;replace fill values with NaNs
   amm=9999.;0.999*max(bzgsm)
   xclip,-amm,amm,bzgsm

   ;fill in the gaps
   tgrid=timeomni
   if keyword_set(min5) then tomni=300. else dtomni=60.;sec
   margomni=0.3*dtomni
   xdegap,dtomni,margomni,timeomni,bzgsm,tgrid,bzgsmnan;,/nowarning
   sss=size(bzgsmnan)
   if sss[0] lt 1 then begin
      bzgsmnan=bzgsm
      tgrid=timeomni
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgrid,bzgsmnan,flag=fl

   ;convolve to req'd resolution
   if n_elements(resol) gt 0 then begin
      convolve_gaussian_1d,resol,tgrid,bzgsmnan,bz
   endif else bz=bzgsmnan
   bzout=bz
endif else begin; isbz
   bzout=fltarr(nomni)+0.
   print,'solarwind_load: No HRO Bz data found.'
   print,'I set static values Bz=0. nT.'
endelse
swdata=[[tgrid],[dpout],[bzout]]

return
end

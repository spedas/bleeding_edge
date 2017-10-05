;+
; NAME:
;     SOLARWIND_LOAD_OMNI1H
;
; PURPOSE:
;	Plug-in subroutine for driver routine solarwind_load.pro provides 
;	solar wind (SW) data time-shifted to the bow-shock
;	nose. Time resolution of data is fixed: 1 hour. SW data source: 
;	OMNI-2. Data is already time-shifted.
;	In all cases of insufficient data, the code produces nominal static
;	SW parameters, following SPDF standards. 
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	solarwind_load_omni1h,isomni1h,times,timee,swdata,dstout
;
; INPUTS:
;	times : - start time (at the magnetopause) for SW data (double UNIX time or
;		any other TDAS time format)
;	timee : - end time, formatted as above
;
; KEYWORDS: None
;
; PARAMETERS: fill values taken from OMNI-2 web site
;
; OUTPUTS:
;	isomni1h - 1 if OMNI-2 data are found and 0 otherwise
;	swdata: | t | Dp | Bz | of IMF at the bow-shock nose
;		- 2D double array (ntpoints,3)
;	dst_out: | Dst | - Dst index on the 1-hour OMNI-2 time grid
;		- double array (ntpoints)
;
; DEPENDENCIES: omni2_load.pro, get_data.pro,
;		xclip.pro, xdegap.pro, xdeflag.pro, cotrans.pro. The code is a
;		lowest-level part of LMN transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;	Modified by Vladimir Kondratovich 2008/03/31.
;-
;
; THE CODE BEGINS:

pro solarwind_load_omni1h,isomni1h,times,timee,swdata,dstout

;Get 1 Hour data and/or Dst if requested++++++++++++
isdp=0
isbz=0
isdst=0
isomni1h=0

;get data
omni2_load,trange=[times,timee]

get_data,'OMNI2_mrg1hr_BZ_GSM',timeomni2,bzgsm
get_data,'OMNI2_mrg1hr_Pressure',timeomni2,dp
get_data,'OMNI2_mrg1hr_DST',timeomni2,dstt

;select data chunk to study
ind2=where(timeomni2 ge times and timeomni2 le timee,n2)
if n2 gt 0 then begin
   isomni1h=1
   bzgsm=bzgsm[ind2]
   dp = dp[ind2]
   dstt=dstt[ind2]
   timeomni2=timeomni2[ind2]
endif else begin
   isswe=0
   print,'get_omni1h: No OMNI-2 one-hour data found.'
   print,'I set static values Dp=2.088 nPa, Bz=0 and Dst=-16.4.'
   return
endelse

maxbz=max(bzgsm)
indbz=where(bzgsm lt maxbz,nbz)
if nbz gt 0 then isbz=1
maxdp=max(dp)
inddp=where(dp lt maxdp,ndp)
if ndp gt 0 then isdp=1
maxdstt=max(dstt)
inddstt=where(dstt lt maxdstt,ndstt)
if ndstt gt 0 then isdst=1
nomni=n_elements(timeomni2)

if isdp then begin
   ;retain only good values:
   ;replace fill values with NaNs
   amm=99.;0.999*max(dp)
   xclip,-amm,amm,dp

   ;fill in the gaps
   tgrd=timeomni2
   dtomni=3600.;sec
   margomni=0.2*dtomni
   xdegap,dtomni,margomni,timeomni2,dp,tgrd,dpnan;,/nowarning
   sss=size(dpnan)
   if sss[0] lt 1 then begin
      dpnan=dp
      tgrd=timeomni2
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgrd,dpnan,flag=fl
   dpout=dpnan
endif else begin; isdp
   dpout=fltarr(nomni)+2.088; nPa
   print,'solarwind_load: No OMNI2 Dp data found.'
   print,'I set static values Dp=2.088 nPa.'
endelse

if isbz then begin
   ;retain only good values:
   ;replace fill values with NaNs
   amm=999.;0.999*max(bzgsm)
   xclip,-amm,amm,bzgsm

   ;fill in the gaps
   tgrd=timeomni2
   dtomni=3600.;sec
   margomni=0.2*dtomni
   xdegap,dtomni,margomni,timeomni2,bzgsm,tgrd,bzgsmnan;,/nowarning
   sss=size(bzgsmnan)
   if sss[0] lt 1 then begin
      bzgsmnan=bzgsm
      tgrd=timeomni2
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgrd,bzgsmnan,flag=fl
   bzout=bzgsmnan
endif else begin; isbz
   bzout=fltarr(nomni)+0.
   print,'solarwind_load: No OMNI Bz data found.'
   print,'I set static values Bz=0. nT.'
endelse
swdata=[[tgrd],[dpout],[bzout]]

if isdst then begin
   ;retain only good values:
   ;fill in the gaps
   tgrd=timeomni2
   dtomni=3600.;sec
   margomni=0.2*dtomni
   xdegap,dtomni,margomni,timeomni2,dstt,tgrd,dsttnan;,/nowarning
   sss=size(dsttnan)
   if sss[0] lt 1 then begin
      dsttnan=dstt
      tgrd=timeomni2
   endif

   ;interpolate onto the grid
   fl=!values.f_nan
   xdeflag,'linear',tgrd,dsttnan,flag=fl
   dstout=dsttnan
endif else begin; isdst
   dstout=fltarr(nomni)-16.4
   print,'solarwind_load: No OMNI2 Dst data found.'
   print,'I set average value Dst=-16.4.'
endelse

return
end

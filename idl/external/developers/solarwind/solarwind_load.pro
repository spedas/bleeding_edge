;+
; NAME:
;     SOLARWIND_LOAD
;
; PURPOSE:
;	Routine provides solar wind (SW) data time-shifted to the bow-shock
;	nose. Time resolution of data is variable with 1 minute as finest.
;	SW data sources: OMNI-2, HRO, and WIND. Time shifting of the WIND
;	data is based on the OMNI-2 metodology.
;	Important difference is that we first average and then propagate
;	averaged WIND quantities to the Earth. If there still is a strong
;	irregularity in the SW speed after averaging, the code warns user.
;	In all cases of insufficient data, the code produces nominal static
;	SW parameters, following SPDF standards. Static nominal SW data is
;	default output if no user preferences are specified in the
;	program call.
;
; CATEGORY:
;	Data Processing
;
; CALLING SEQUENCE:
;	solarwind_load,swdata,dstout,trange, resol=resol, wind=wind, hro=hro, min5=min5, h1=h1, dst=dst
;
; INPUTS:
;	trange : [tstart, tend] - time range (at the magnetopause) for SW data
;		Times tstart and tend need to be one of types supported by TDAS 
;		(specifically, by the time_double.pro routine), in part:
;		double seconds since 1970 (internal TDAS format)
;		string format: 'YYYY-MM-DD/hh:mm:ss'
; OPTIONAL INPUT:
;	resol  : desired time resolution of the output data in seconds
;		- if not set, SW data are provided in original time resolution
;
; KEYWORDS:
;	wind - WIND observations used (they are convolved to desired resolution and
;		then time-shifted to the bow-shock nose using OMNI-2 methodology. The
;		code checks if the SW speed irregularities are too large and warns
;		user when more sophisticated processing may be needed.
;	hro - HRO data are used (most consistent approach up-to-date). The data are
;		already propagated, so they are just convolved to desired resolution.
;	min5 - use 5 min HRO merged database (default is to use 1 min HRO merged data)
;	h1 - use OMNI-2 1 hour SW database. No convolution employed and parameter
;		resol is ignored
;	dst - get Dst index from the OMNI-2 database. This switch works independently
;		on the other data keywords (for example, it provides Dst output even
;		if HRO or WIND data are ordered). Dst is interpolated onto the time grid
;		od requested data, if any.
;
; PARAMETERS: 3 parameters for outlier filtering are described and set at the
;			beginning of the code.
;
; OUTPUTS:
;	swdata: | t | Dp | Bz | of IMF at the bow-shock nose
;		- 2D double array (ntpoints,3)
;	dstout: | Dst | - Dst index on the 1-hour OMNI-2 time grid
;		- double array (ntpoints)
;
; DEPENDENCIES: convolve_gaussian_1d.pro, remove_outliers.pro, repair.pro,
;     wi_swe_load.pro, wi_mfi_load.pro, omni_hro_load.pro, omni2_load.pro,
;     get_data.pro, xclip.pro, xdegap.pro, xdeflag.pro, cotrans.pro. The code
;     is a lowest-level part of LMN transform package.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2007/12/28.
;	Modified by Vladimir Kondratovich 2008/03/31. Mods do not change call syntax. The code 
;		is made modular with plug-in subroutines for each data source, so it became easy
;		to add a new one. Existing ingest modules provide a template.
;-
;
; THE CODE BEGINS:

pro solarwind_load,swdata,dstout,trange,resol=resol,  wind=wind, hro=hro, min5=min5, h1=h1, dst=dst

;Foolproving it:
if n_elements(swdata) gt 0 then print,'SOLARWIND_LOAD: Attention: SWDATA is output array. Its content will be overwritten!'
if n_elements(dstout) gt 0 then print,'SOLARWIND_LOAD: Attention: DSTOUT is output array. Its content will be overwritten!'
if (n_elements(trange) le 1) or (n_elements(trange) gt 2) then begin
   print,'SOLARWIND_LOAD: Input error: trange must be a 2-element array [Tstart, Tend]'
   print,'Times tstart and tend need to be one of types supported by TDAS'
   print,'(specifically, by the time_double.pro routine), namely:'
   print,'double seconds since 1970 (internal TDAS format)'
   print,'string format: "YYYY-MM-DD/hh:mm:ss"'
   return
endif
if (n_elements(resol) le 0) and (not keyword_set(h1)) then begin
   print,'SOLARWIND_LOAD: Resolution RESOL of the output data is not specified,'
   print,'therefore data will be output in its native resolution.'
endif
if keyword_set(h1) or keyword_set(dst) then print,'SOLARWIND_LOAD: OMNI-2 data and Dst index are output in one-hour resolution.'

;Parameters for outlier filtering:
common filtpar,d,tmax,nmax
;halfwidth of the hollow vicinity (in number of points)
d=3
;maximal comparison time
tmax=15 ;minutes
tmax=tmax*60 ;seconds
;tmax=double(tmax*1000.) ;milliseconds
;tmax=tmax/1440. ;MJD
;maximal deviation from the vicinity average deemed probable, in sdev
nmax=3

times=time_double(trange[0])
timee=time_double(trange[1])
timss=times-7200.;sec

;To get nominal magnetopause
nnom=1000
dt=(timee-times)/(nnom+0.)
tgrid=times+dt*indgen(nnom+1)
bzout=fltarr(nnom+1)+0.
dpout=fltarr(nnom+1)+2.088;nPa
swdata=[[tgrid],[dpout],[bzout]]
if not keyword_set(wind) and not keyword_set(hro) and not keyword_set(h1) then begin
   print,'You have not specified the source of solar wind data.'
   print,'To do so, set the keywords wind or hro or h1 in the call to solarwind_load.'
   print,'Otherwise, you get the nominal solar wind Bz=0 and Dp=2.088 nPa.'
endif


;Get 1 Hour data and/or Dst if requested++++++++++++
if keyword_set(h1) or keyword_set(dst) then begin
   solarwind_load_omni1h,isomni1h,times,timee,swdat,dstout1
   if isomni1h then swdata=swdat
endif; 1-hour OMNI-2 and Dst-----------------------


;Get WIND data++++++++
if keyword_set(wind) then begin
   solarwind_load_wind,iswind,times,timee,swdat,resol
   if iswind then swdata=swdat
endif; wind---------


;Get HRO data+++++++
if keyword_set(hro) then begin
   if keyword_set(min5) then solarwind_load_hro,ishro,times,timee,swdat,resol,/min5 $
   else solarwind_load_hro,ishro,times,timee,swdat,resol
   if ishro then swdata=swdat
endif; hro--------

if keyword_set(dst) or keyword_set(h1) then begin
   if isomni1h then begin
      dstout=dstout1
   endif else begin
      ng=n_elements(tgrid)
      dstout=fltarr(ng)-16.4
   endelse
endif

print,'solarwind_load finished.'
end

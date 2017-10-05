;+
; Procedure: RBSP_LOAD_SPICE_METAKERNEL
;
; Purpose:  Loads RBSP SPICE metakernels
;
; input:
; metakernel : full path to metakernel file for loading
; 
; keywords:
;	/UNLOAD : unloads all kernels loaded by the four RBSP metakernels
;   mkpath='/path/to/teams/spice/meta' : the full path to the teams/spice/meta
;		directory that contains the up-to-date metakernels from MOC
;	/ALL : load all available kernels
; Examples:
;   rbsp_load_spice_metakernel,/dev ; load development kernels
;	rbsp_load_spice_metakernel,/dev,/unload ; unload development kernels
;   rbsp_load_spice_kernels,/update ; update and load latest MOC kernels
;
; Notes:
;	Default is to load all available kernels if no timespan is set.
;-
;
; History:
;	10/2012, created - Peter Schroeder, peters@ssl.berkeley.edu
; 04/2014, added handling for monthly full attitude history files - kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-04-05 09:30:44 -0700 (Sat, 05 Apr 2014) $
;   $LastChangedRevision: 14759 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_spice_metakernel.pro $
;
;-


pro rbsp_load_spice_metakernel, metakernel, unload=unload,update=update,all=all


rbsp_spice_init

if(icy_test() eq 0) then return

; get the current time range for restricting attitude_history kernels
if keyword_set(all) then begin
	tr=[time_double('1000'),time_double('9000')]
endif else begin
	@tplot_com.pro
	str_element,tplot_vars,'options.trange_full',tr
	; see if we have a reasonable timerange.  if not, load all kernels
	if n_elements(tr) ne 2 then tr=[time_double('1000'),time_double('9000')]
	if tr[0] ge tr[1] then tr=[time_double('1000'),time_double('9000')]
endelse
; drop hh:mm:ss and expand timerange to -3 to +1 days
str=time_string(tr,tformat='YYYY-MM-DD')
tr[0]=time_double(str[0]) ; these have to be converted separately?  not sure why
tr[1]=time_double(str[1])
tr[0]-=3.*86400.
tr[1]+=86400.



file_open,'r',metakernel, unit=unit

line = ''
inblock = 0

while not eof(unit) do begin
  readf, unit, line
  if strmatch(line, '*KERNELS_TO_LOAD += (*') then inblock = 1 
  if inblock then begin
    paren1 = strpos(line, "'")
    kerneltoload = strmid(line,paren1+1)
    paren2 = strpos(kerneltoload,"'")
    kerneltoload = strmid(kerneltoload,0,paren2)
    str_replace,kerneltoload,'$ROOT/',''
    str_replace,kerneltoload,'$RBSPA','MOC_data_products/RBSPA'
    str_replace,kerneltoload,'$RBSPB','MOC_data_products/RBSPB'
    str_replace,kerneltoload,'$CKP','attitude_predict'
    str_replace,kerneltoload,'$CKFULL','attitude_history_full'
    str_replace,kerneltoload,'$CKQUICK','attitude_history'
    str_replace,kerneltoload,'$FKG','teams/spice/fk'
    str_replace,kerneltoload,'$FK','frame_kernel'
    str_replace,kerneltoload,'$IK','teams/spice/ik'
    str_replace,kerneltoload,'$LSK','leap_second_kernel'
    str_replace,kerneltoload,'$PCK','teams/spice/pck'
    str_replace,kerneltoload,'$SCLK','operations_sclk_kernel'
    str_replace,kerneltoload,'$SPKPE','planetary_ephemeris'
    str_replace,kerneltoload,'$SPKP','ephemeris_predict'
    str_replace,kerneltoload,'$SPKD','ephemerides'
    
    ; strip out extra attitude_history kernels
    if strpos(kerneltoload,'attitude_history/') ne -1 then begin
		
  		; kernels are suffixed with _YYYY_DOY_VV.ath.bc
  		kernelbits=strsplit(kerneltoload,'_',/extract)
  		nkernelbits=n_elements(kernelbits)
  		kyear=long(kernelbits[nkernelbits-3])
  		kdoy=long(kernelbits[nkernelbits-2])
  		doy_to_month_date,kyear,kdoy,kmonth,kday
  		sktime=string(kyear,kmonth,kday,format='(I04,"-",I02,"-",I02)')
  		ktime=time_double(sktime)
  		if (ktime lt tr[0]) or (ktime gt tr[1]) then kerneltoload=''
		
    endif

    ; strip out extra attitude history full monthly files
    if strpos(kerneltoload,'attitude_history_full/') ne -1 then begin

      ; kernels are suffixed with _YYYY_DOY_YYYY_DOY_VV.ath.bc
      kernelbits=strsplit(kerneltoload,'_',/extract)
      nkernelbits=n_elements(kernelbits)
      kstartyear=long(kernelbits[nkernelbits-5])
      kstartdoy=long(kernelbits[nkernelbits-4])
      kendyear=long(kernelbits[nkernelbits-3])
      kenddoy=long(kernelbits[nkernelbits-2])
      doy_to_month_date,kstartyear,kstartdoy,kstartmonth,kstartday
      doy_to_month_date,kendyear,kenddoy,kendmonth,kendday
      skstarttime=string(kstartyear,kstartmonth,kstartday,format='(I04,"-",I02,"-",I02)')
      kstarttime=time_double(skstarttime)
      skendtime=string(kendyear,kendmonth,kendday,format='(I04,"-",I02,"-",I02)')
      kendtime=time_double(skendtime)
      if (kendtime lt tr[0]) or (kstarttime gt tr[1]) then kerneltoload=''

    endif

    
    if kerneltoload ne '' then begin
      files = file_retrieve(kerneltoload, _extra=!rbsp_spice)
      print,'Processing '+files[0]
      if keyword_set(unload) then cspice_unload,files $
        else cspice_furnsh,files
    endif
    if strmatch(line, '*)*') then inblock = 0
  endif
endwhile

free_lun,unit

end
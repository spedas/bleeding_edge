;+
; NAME:
;    THM_LOAD_ASI_CAL
;
; SYNTAX:
;    thm_load_asi_cal,'fykn',fykn_cal
;
; PURPOSE:
;   load the ASI calibration parameters into tplot variables
;
; INPUTS:
;   SITE	names of GBO stations requested
;
; OUTPUTS:
;   CAL_STRUC   structure containing pointers to calibration parameters
;
; KEYWORDS:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;   /ALL	get data from all 20 THEMIS-GBO
;   /DOWNLOADONLY   
;   /VALID_NAMES
;   /CURSOR	get time range with cursor
;   REGO	read cal-file for REGO camera instead of THEMIS
;
; HISTORY:
;   adapted from thm_load_asi
;   2015-07-21, hfrey, included call to REGO cal-files
;   2020-06-09, jmm, checks for v02 files and corrects mlat and mlon
;   variables for ASK data.
;
; Notes:
;
; To get an array of valid names make the following call;
;   thm_load_asi_cal,valid_names=vn
; No further action will be taken.
;
;Written by: Harald Frey,   Jan 26 2007
;   $LastChangedBy: jwl $
;   $LastChangedDate: 2023-12-30 17:48:10 -0800 (Sat, 30 Dec 2023) $
;   $LastChangedRevision: 32328 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_load_asi_cal.pro $
;-
;
pro thm_load_asi_cal,site,cal_struc,trange=trange,verbose=verbose,all=all $
   ,downloadonly=downloadonly,valid_names = vstats, $
   cursor=cursor,rego=rego,file_version_in=file_version_in

thm_init

	; Valid station names   (see note above):
if keyword_set(rego) then vstats='atha fsim fsmi gill kakt luck rank resu talo' else $
vstats='atha chbg ekat fsmi fsim fykn gako gbay gill inuv kapu '+ $
   'kian kuuj mcgr pgeo pina rank snkq tpas whit yknf nrsq snap talo'
vstats=strsplit(vstats,' ',/extract)
if arg_present(vstats) then return

	; set begin and end of trange
if keyword_set(trange) then begin
   if (size(trange[0],/type) eq 7) then time=time_double(trange[0])
   if (size(trange[0],/type) eq 5) then time=trange[0] 
   endif else time=(timerange('2000-01-01/00:00:00'))[0]

	; get time with cursor
if keyword_set(cursor) then begin   ; Use the cursor to determine what asi's to load.
   ctime,t,vname=var
   trange = minmax(t)
   stations = strmid(var,3,4,/reverse)
   ;stop,time_string(trange),stations
endif

	; just get all stations
if keyword_set(all) then stations='*' else stations=site
stats = strfilter(vstats,stations,delimiter=' ',/string)  ; vstats is the subarray of valid stations

if not keyword_set(stats) then  begin
   dprint, 'Input must be one or more of the following strings:'
   dprint, vstats
   return
endif

if keyword_set(verbose) then printdat,stats,/value,'Stations'

	    ; loop over all stations
for i=0,n_elements(stats)-1 do begin
  station = stats[i]

  ; Although these file names appear platform dependent, it works well on MS windows! Please don't change

  if keyword_set(rego) then prefix = 'rego_l2_asc_' + station + '_' else $
       prefix = 'thg_l2_asc_' + station + '_'
  relpath = 'thg/l2/asi/cal/'
;allow old version in for testing v02 fix
  If(keyword_set(file_version_in)) Then Begin
     ending = '_v'+string(file_version_in[0], format='(i2.2)')+'.cdf'
  Endif Else ending = '_v0?.cdf'

  relpathnames = file_dailynames(relpath,prefix,ending,$
     trange=['1970-01-01/00:00:00','1970-01-01/00:00:00'])

  files = spd_download(remote_file=relpathnames, _extra = !themis, /last_version)

  if keyword_set(verbose) then  dprint, files

;  if  keyword_set(downloadonly) then continue

     ; load data into tplot variables  

	; read only one record out of CDF-file
  res=cdf_load_vars(files,varformat='*time', spdf_dependencies=0,/verbose)
  if (size(res,/type) ne 8) then continue
  ti = (where(strpos(res.vars.name,'time') ne -1))[0]
  timearr = *res.vars[ti].dataptr  

	; we check for which record is applicable
  if (size(time,/type) eq 5) then record=where(time-timearr ge 0.,count) else $  ; double
       record=where(abs(timearr-time_double(time)) le 1,count)	; string
  if (count gt 0) then $       		; Load data from file(s)
       cal = cdf_load_vars(files,varnames=varnames2,verbose=verbose,record=record[count-1],/all) $
       else cal=-1

;fix for mlat, mlon for version 02 files, jmm, 2020-06-08, fixed fix 2020-07-20
  tmp_file = strsplit(file_basename(files[0]), '_', /extract)
  If(is_struct(cal) && tmp_file[n_elements(tmp_file)-1] Eq 'v02.cdf') Then Begin
     a = where(cal.vars.name Eq 'thg_asf_'+station+'_mlat')
     b = where(cal.vars.name Eq 'thg_ask_'+station+'_mlat')
     f_mlat = *cal.vars[a].dataptr
     If(ptr_valid(cal.vars[b].dataptr)) Then ptr_free, cal.vars[b].dataptr
     cal.vars[b].dataptr = ptr_new(reform(f_mlat[127, 0:255]))
     a = where(cal.vars.name Eq 'thg_asf_'+station+'_mlon')
     b = where(cal.vars.name Eq 'thg_ask_'+station+'_mlon')
     f_mlon = *cal.vars[a].dataptr
     If(ptr_valid(cal.vars[b].dataptr)) Then ptr_free, cal.vars[b].dataptr
     cal.vars[b].dataptr = ptr_new(reform(f_mlon[127, 0:255]))
  Endif

  if (i gt 0) then cal_struc=[cal_struc,cal] else cal_struc=cal
  
endfor

end


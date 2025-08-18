;+
;PROCEDURE:	load_wi_h0_mfi
;PURPOSE:
;   loads WIND MAGNETOMETER high resolution data for "tplot".
;
;INPUTS:	none, but will call "timespan" if time
;		range is not already set.
;KEYWORDS:
;  TIME_RANGE:  2 element vector specifying the time range
;  POLAR:       Also computes the B field in polar coordinates.
;  DATA:        Data returned in this named variable.
;  HOUR:	Load hourly averages instead of 3 second data.
;  MINUTE:	Load 60 second averages instead of 3 second data.
;  NODATA:	Returns 0 if data exists for time range, otherwise returns 1.
;  GSM:		If set, GSM data is retrieved.
;  PREFIX:	(string) prefix for tplot variables.  Default is 'wi_'
;  NAME:	(string) name for tplot variables. Default is 'wi_Bh'
;  RESOLUTION:	Resolution to return in seconds.
;  MASTERFILE:	(string) full filename of master file.
;SEE ALSO:
;  "make_cdf_index","loadcdf","loadcdfstr","loadallcdf"
;
;CREATED BY:	Peter Schroeder
;LAST MODIFIED:	@(#)load_wi_h0_mfi.pro	1.10 02/11/01
;-


pro load_wi_h0_mfi,time_range=trange,polar=polar,data=d,  $
  nodata=nodat, $
  GSM = gsm, $
  source=source, $
  prefix = prefix, $
  resolution = res,  $
  name = bname, $
  no_download=no_download, no_update=no_update, $
  masterfile=masterfile, $
  hour = hour, minute=minute

if not keyword_set(masterfile) then masterfile = 'wi_h0_mfi_files'
cdfnames = ['B3GSE','B3RMSGSE']
ppx = 'B3'
if keyword_set(hour) then begin
	cdfnames = ['B1GSE','B1RMSGSE']
	ppx = 'B1'
endif
if keyword_set(minute) then begin
	cdfnames = ['BGSE','BRMSGSE']
	ppx = 'Bm'
endif
if keyword_set(gsm) then cdfnames =['B3GSM','B3RMSGSM']

if not keyword_set(source) then begin
   istp_init
   source = !istp
endif

if keyword_set(no_download) && no_download ne 0 then source.no_download = 1
if keyword_set(no_update) && no_update ne 0 then source.no_update = 1

file_format = 'wind/mfi/mfi_h0/YYYY/wi_h0_mfi_YYYYMMDD_v0?.cdf'
pathnames = file_dailynames(file_format=file_format,trange=trange)

;filenames = file_retrieve(pathnames,_extra=source,/last_version)
filenames = spd_download(remote_file = pathnames, $
                         remote_path = source.remote_data_dir, $
                         local_path = source.local_data_dir, $
                         no_download = source.no_download, $
                         no_update = source.no_update, /last_version, $
                         file_mode = '666'o, dir_mode = '777'o)
d=0
nodat = 0

loadallcdf,time_range=trange,masterfile=masterfile,filenames=filenames, $
    cdfnames=cdfnames,data=d,res =res

if keyword_set(d) eq 0 then begin
   message,'No H0 MFI data during this time.',/info
   nodat = 1
  return
endif


if data_type(prefix) eq 7 then px=prefix else px = 'wi_'
if data_type(bname) eq 7 then px = bname else px = px+ppx
if keyword_set(gsm) then px =px+'_GSM'

labs=['B!dx!n','B!dy!n','B!dz!n']


time  = reform(d.time)
str_element,d,cdfnames(0),bgse
bgse = transpose(bgse)
str_element,d,cdfnames(1),brmsgse
brmsgse = transpose(brmsgse)

bmag=sqrt(total(bgse*bgse,2))
w =where(bmag gt 1000.,c)
if c ne 0 then bgse[w,*] = !values.f_nan
if c ne 0 then brmsgse[w,*] = !values.f_nan

store_data,px,data={x:time,y:bgse},min= -1e30, dlim={labels:labs}
store_data,px+'_rms',data={x:time,y:brmsgse},min= -1e30

if keyword_set(polar) then begin
   xyz_to_polar,px,/ph_0_360

   options,px+'_mag','ytitle','|B|',/def
   options,px+'_th','ytitle','!19Q!X!DB!U',/def
   ylim,px+'_th',-90,90,0,/def
   options,px+'_phi','ytitle','!19F!X!DB!U',/def
   options,px+'_phi','psym',3,/def
   ylim,px+'_phi',0,360.,0,/def

endif


end


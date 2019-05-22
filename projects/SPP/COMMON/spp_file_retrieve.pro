;+
; Written by Davin Larson 
; 
; $LastChangedBy: pulupa $
; $LastChangedDate: 2019-05-21 15:55:18 -0700 (Tue, 21 May 2019) $
; $LastChangedRevision: 27271 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_file_retrieve.pro $
; 
; Function:  files = spp_file_retrieve(PATHNAME)
; Purpose:  Retrieve or Download Solar Probe data files (i.e. L0 files)  (Can be used to generate filenames too)
; INPUT:
; PATHNAME:  string specifying relative path to files.         Default might change-  Currently:  'psp/pfp/l0/YYYY/MM/mvn_pfp_all_l0_YYYYMMDD_v???.dat'
;         PATHNAME must be relative to the LOCAL_DATA_DIR and REMOTE_DATA_DIR fields of the source keyword.
;         "globbed" filenames (*,?) are accepted.
; typical usage:
;   files = spp_file_retrieve('psp/xxxxxx/YYYY/MM/mvn_pfp_all_l0_YYYYMMDD_v???.dat',/daily_names)   ; get L0 files for user defined time span
;   files = spp_file_retrieve(pathname,/daily_names,trange=trange)  ; set time range
;Keywords:  (All are optional - none are recommended)
; L0:   set to 1 to return PFP L0 files
; DAILY_NAMES : resolution (in days) for generating file names. 
;         YYYY, yy, MM, DD,  hh,  mm, ss, .f, DOY, DOW, TDIFF are special characters that will be substituted with the appropriate date/time field
;         Be especially careful of extensions that begin with '.f' since these will be translated into a fractional second. 
;         See "time_string"  TFORMAT keyword for more info.
; TRANGE : two element vector containing start and end times (UNIX_TIME or UT string).  if not present then timerange() is called to obtain the limits.
; SOURCE:  alternate file source.   Default is whatever is return by the function:  mvn_file_source()    (see "mvn_file_source" for more info)
; FILES:  if provided these will be passed through as output.
; VALID_ONLY:  Set to 1 to prevent non existent files from being returned.
; CREATE_DIR:  Generates a filename and creates the directories needed to create the file without errors.  Will not check for file on remote server.
;
; KEYWORDS Passed on to "FILE_RETRIEVE":
; LAST_VERSION : [0,1]  if set then only the last matching file is returned.  (Default is defined by source)
; VALID_ONLY:  [0,1]   If set then only existing files are returned.  (Default is defined by source keyword)
; VERBOSE:  set verbosity level (2 is typical)
; USER_PASS:  user:password combination for the remote server
; LIMITATIONS:
;   Beware of file pathnames that include the character sequences:  YY,  MM, DD, hh, mm, ss, .f  since these can be retranslated to the time
;-
function spp_file_retrieve,pathname,trange=trange,ndays=ndays,nhours=nhours,verbose=verbose, source=src, $
   last_version=last_version, $
   prefix = prefix, $
   key = source_key, $
   no_server = no_server, $
   ssr = ssr,ptp=ptp, $
   no_update=no_update,create_dir=create_dir,pos_start=pos_start, $
   daily_names=daily_names,hourly_names=hourly_names,resolution = res,shiftres=shiftres,valid_only=valid_only,  $
   fields_mago_survey = fields_mago_survey, $
 ;  no_server=no_server,user_pass=user_pass,L0=L0, $
   cal=cal,TVac=Tvac,snout2=snout2,snout1=snout1,crypt=crypt, goddard = goddard, hires1 = hires1, ion=ion,recent=recent,spani=spani,spanea=spanea,spaneb=spaneb,spc=spc,swem=swem,elec=elec,instr=instr,router=router

tstart = systime(1)

if keyword_set(fields_mago_survey) then begin
  pathname = 'psp/data/sci/sweap/.test/l1/mago_survey/YYYY/MM/spp_fld_l1_mago_survey_YYYYMMDD_v00.cdf
  daily_names = 1
  valid_only = 1
endif

if keyword_set(recent) then trange = systime(1) - [recent,0] * 86400d ;    Obtain the last N*24 hours
if keyword_set(ndays) then trange = time_double(trange[0]) + [0,ndays*86400L]
if keyword_set(nhours) then trange = time_double(trange[0]) + [0,nhours*3600L]



sweap_gsedata_dir = 'spp/data/sci/sweap/prelaunch/gsedata/'
realtime_dir = sweap_gsedata_dir+'realtime/'

if keyword_set(L0) then begin   ; default location of L0 files
  pathname = 'spp/data/sci/pfp/l0_all/YYYY/MM/spp_swp_all_l0_YYYYMMDD_v???.dat'
  daily_names=1
  last_version =1
endif

if keyword_set(elec) then begin
  spanea = 1
  dprint, 'Please use spanea keyword instead'
endif


; select for instrument
; note that thus far (20180420) spacecraft = swem
if keyword_set(tvac) then snout2=1
if keyword_set(spani) then instr = 'spani'
if keyword_set(spanea) then instr='spanea'
if keyword_set(spaneb) then instr='spaneb'
if keyword_set(spc) then instr = 'spc'
if keyword_set(swem) then instr = 'swem'

; select for location
if keyword_set(cal) then   router = 'cal'
if keyword_set(snout2) then router = 'snout2'
if keyword_set(snout1) then router = 'snout1'
if keyword_set(crypt) then router = 'crypt'
if keyword_set(rm133) then router = 'rm133'
if keyword_set(goddard) then router = 'hires1'
if keyword_set(hires1) then begin
  router = 'hires1'
  instr = 'swem'
endif

if keyword_set(ssr) then begin
  pathname = 'psp/data/sci/sweap/raw/SSR/YYYY/DOY/*_?_EA'
  daily_names=1
endif

if keyword_set(ptp) then begin
  pathname = 'psp/data/sci/sweap/raw/PTP/YYYY/DOY/sweap_spp_YYYYDOY_??.ptp.gz
  daily_names=1
endif


if ~keyword_set(pathname) then begin
  pathname = realtime_dir + router+'/'+instr+'/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
  hourly_names =1
  valid_only=1
endif


if not keyword_set(shiftres) then shiftres =0
if keyword_set(daily_names) then begin 
   res = round(24*3600L * daily_names)
   sres= round(24*3600L * shiftres)
endif

if keyword_set(hourly_names) then begin
  res = round(3600L * hourly_names)
  sres= round(3600L * shiftres)
endif

;lv = n_elements(last_version) eq 0 ? 1 : last_version 
vo = n_elements(valid_only) eq 0 ? 0 : valid_only

source = spp_file_source(src,source_key=source_key,verbose=verbose,user_pass=user_pass,no_server=no_server,valid_only=vo,  $
    last_version=last_version,no_update=no_update,resolution=res)

pos_start = strlen(source.local_data_dir)



dprint,dlevel=5,verbose=verbose,phelp=1,source   ; display the options

if keyword_set(res) then begin
  tr = timerange(trange)
  str = (tr-sres)/res
  dtr = (ceil(str[1]) - floor(str[0]) )  > 1           ; must have at least one file
  times = res * (floor(str[0]) + lindgen(dtr))+sres
  pathnames = time_string(times,tformat=pathname)
  pathnames = pathnames[uniq(pathnames)]   ; Remove duplicate filenames - assumes they are sorted
endif else pathnames = pathname

if  keyword_set(prefix) then pathnames = prefix+pathnames

if keyword_set(create_dir) then begin
  files = source.local_data_dir + pathnames
  file_mkdir2,file_dirname( files ),_extra=source
  return,files
endif

if keyword_set(source_key) then begin
  if source_key EQ 'FIELDS' then pathnames = str_sub(pathnames, 's\s', 'ss')
endif

files = file_retrieve(pathnames,_extra=source)
dprint,dlevel=3,verbose=verbose,systime(1)-tstart,' seconds to retrieve ',n_elements(files),' files'
if n_elements(files) eq 1 then files=files[0]
return,files


end

; Written by Davin Larson & adapted by Phyllis W with Gemini assistance
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2021-05-17 14:48:58 -0700 (Mon, 17 May 2021) $
; $LastChangedRevision: 29966 $
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

function swx_spane_file_retrieve, trange=trange, daily_names=daily_names, hourly_names=hourly_names, $
                                  valid_only=valid_only, last_version=last_version, source=src, key=source_key, $
                                  cal=cal, bench=bench, snout2=snout2

  ;; 1. Define base directory paths based on your instrument configuration
  base_dir = 'swx/spane/prelaunch/gsedata/realtime/'
  
  ;; Determine location (router) based on keywords, defaulting to snout2
  router = 'snout2'
  if keyword_set(cal) then router = 'cal'
  if keyword_set(bench) then router = 'bench'
  if keyword_set(snout2) then router = 'snout2'
  
  instr = 'swxspe'
  
  ;; 2. Determine file naming resolution (Defaulting to hourly for spp_socket files)
  if ~keyword_set(daily_names) and ~keyword_set(hourly_names) then hourly_names = 1
  
  if keyword_set(daily_names) then begin
    ; If daily is explicitly forced, use wildcards for the hours
    pathname = base_dir + router + '/' + instr + '/YYYY/MM/DD/spp_socket_YYYYMMDD_??.dat.gz'
    res = round(24L * 3600L * daily_names)
  endif else if keyword_set(hourly_names) then begin
    ; Standard hourly format matching your server files
    pathname = base_dir + router + '/' + instr + '/YYYY/MM/DD/spp_socket_YYYYMMDD_hh.dat.gz'
    res = round(3600L * hourly_names)
  endif

  ;; 3. Resolve the time range into specific timestamps
  tr = timerange(trange)
  str = tr / res
  dtr = (ceil(str[1]) - floor(str[0])) > 1
  times = res * (floor(str[0]) + lindgen(dtr))
  
  ;; 4. Substitute date/time special characters using SPEDAS time_string
  pathnames = time_string(times, tformat=pathname, escape_seq='\' )
  pathnames = pathnames[uniq(pathnames)] ; Eliminate any potential duplicates

  ;; 5. Initialize the SPEDAS file source environment
  vo = n_elements(valid_only) eq 0 ? 1 : valid_only
  lv = n_elements(last_version) eq 0 ? 1 : last_version
  
  ; Fetch file source configuration (assumes spp_file_source or similar wrapper exists)
  source = spp_file_source(src, source_key=source_key, valid_only=vo, last_version=lv, resolution=res)

  ;; 6. Retrieve the actual files via standard SPEDAS download utilities
  files = file_retrieve(pathnames, _extra=source)
  
  if n_elements(files) eq 1 then files = files[0]
  return, files
end
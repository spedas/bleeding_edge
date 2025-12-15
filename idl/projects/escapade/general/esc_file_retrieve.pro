;+
;
;FUNCTION:        ESC_FILE_RETRIEVE
;
;PURPOSE:         Retrieves or downloads the ESCAPADE data files.
;
;INPUTS:          String specifying relative path to files.
;                 PATHNAME must be retrieve to the LOCAL_DATA_DIR and REMOTE_DATA_DIR fields of the source keyword.
;                 "wildcards" (*, ?) are accepted.
;
;KEYWORDS:
;
;    TRANGE:      Specifies the time range to be loaded. Two element vector containing start and end times.
;                 If not present, then timerange() is called to obtain the limits.
;
;    SOURCE:      Alternates file source. Default is whatever is return by the esc_file_source() function.
;
; DAILY_RES:      Specifies the daily resolution for generating file names.
;
;HOURLY_RES:      Specifies the hourly resolution for generating file names.
;
; USER_PASS:      Specifies the user:password combination for the remote server.
;
;
;NOTE:            Please refer to mvn_pfp_file_retrieve().
;
;CAVEATS:         The basic usage of the "REMOTE_DATA_DIR" keyword differs from the default behavior of similar retrieval routines.
;
;                 For example:
;                 source.remote_data_dir = 'http://sprg.ssl.berkeley.edu/data/escapade/data/'
;                 pathname               = 'YYYY/MM/esc_test_file_YYYYMMDD.cdf'
;                 remote_data_dir        = 'commissioning/blue/ephemeris/'
;             
;                 In this case, esc_file_retrieve() retrieves the file by concatenating
;                 source.remote_data_dir + remote_data_dir + pathname, i.e., 
;
;                 http://sprg.ssl.berkeley.edu/data/escapade/data/commissioning/blue/ephemeris/YYYY/MM/esc_test_file_YYYYMMDD.cdf
; 
;                 Therefore, when the "REMOTE_DATA_DIR" keyword is explicitly specified,
;                 the routine does not automatically interpret or convert the character sequences
;                 YYYY, MM, DD, hh, mm, ss, .f as time placeholders.
;
;CREATED BY:      Takuya Hara on 2025-12-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2025-12-13 17:20:41 -0800 (Sat, 13 Dec 2025) $
; $LastChangedRevision: 33919 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/general/esc_file_retrieve.pro $
;
;-
FUNCTION esc_file_retrieve, pathname, trange=trange, verbose=verbose, local_data_dir=ldir, remote_data_dir=rdir,            $
                            source=src, user_pass=user_pass, files=files, last_version=last_version, valid_only=valid_only, $
                            daily_res=daily_res, hourly_res=hourly_res, resolution=res, shiftres=shiftres,                  $
                            no_server=no_server, no_download=no_download, no_update=no_update, recent=recent

  oneday = 86400.d0
  tstart = SYSTIME(1)
  IF KEYWORD_SET(recent) THEN trange = SYSTIME(1) - [recent, 0] * oneday ; Obtain the last N*24 hours

  IF NOT KEYWORD_SET(shitres) THEN shiftres = 0
  IF KEYWORD_SET(daily_res) THEN BEGIN
     res  = ROUND(oneday * daily_res)
     sres = ROUND(oneday * shiftres)
  ENDIF 
  IF KEYWORD_SET(hourly_res) THEN BEGIN
     res  = ROUND(3600L * hourly_res)
     sres = ROUND(3600L * shiftres)
  ENDIF 

  source = esc_file_source(src, verbose=verbose, local_data_dir=ldir, user_pass=user_pass, no_sever=no_server, valid_only=valid_only, last_version=last_version, no_update=no_update)
  IF undefined(src) THEN src = source
  
  pos_start = strlen(source.local_data_dir)
  
  dprint, dlevel=5, verbose=verbose, phelp=2, source ; display the options
  
  IF KEYWORD_SET(res) THEN BEGIN
     tr  = timerange(trange)
     str = (tr - sres) / res
     dtr = (CEIL(str[1]) - FLOOR(str[0]) )  > 1 ; must have at least one file
     times = res * (FLOOR(str[0]) + LINDGEN(dtr)) + sres
     pathnames = time_string(times, tformat=pathname)
     pathnames = spd_uniq(pathnames) ; Remove duplicate filenames - assumes they are sorted
  ENDIF ELSE pathnames = pathname
  IF ~undefined(rdir) THEN pathnames = rdir + pathnames

  files = file_retrieve(pathnames, _extra=source)
  dprint, dlevel=3, verbose=verbose, SYSTIME(1)-tstart, ' seconds to retrieve ', N_ELEMENTS(files), ' files'

  RETURN, files
END 

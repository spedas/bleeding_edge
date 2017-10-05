;+
;PROCEDURE:  thm_init
;PURPOSE:    Initializes system variables for themis.  Can be called from idl_startup to set
;            custom locations.
;
; The system variable !THEMIS is defined here.  The elements of this structure are explained below:
;
; !THEMIS.LOCAL_DATA_DIR    This is the root location for all THEMIS data files.
;                  The THEMIS software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
; !THEMIS.REMOTE_DATA_DIR   This is the URL of the server that can provide the data files.
;                  (default is: "http://themis.ssl.berkeley.edu/data/themis/")
;                  if the software does not find a needed file in LOCAL_DATA_DIR,
;                  then it will attempt to download the data from the URL and REMOTE_DATA_DIR is defined,
;                  the software will attempt to download the file from REMOTE_DATA_DIR, place it in LOCAL_DATA_DIR
;                  with the same relative pathname, and then continue processing.
;
;
;KEYWORDS:
;   RESET:           Reset !themis to values in environment (or values in keywords).
;   LOCAL_DATA_DIR:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   REMOTE_DATA_DIR: Use given value for remote_data_dir, rather than env.  Only works on inital
;                    call or reset.
;   NO_COLOR_SETUP   do not set colors if already taken care of
;
; Typical examples:
;
;          Desktop UNIX/LINUX computer located at SSL
;   LOCAL_DATA_DIR  = '/disks/data/themis/'               ; This master directory is read only.
;   REMOTE_DATA_DIR = ''                                  ; Should be empty sting. (/disks/data/themis and server are the same)
;
;          Desktop WINDOWS computer located at SSL
;   LOCAL_DATA_DIR  = '\\justice\data\themis\'            ; Justice is a samba server (physically the same as /disk/data/themis)
;   REMOTE_DATA_DIR = ''
;
;          laptop WINDOWS computer located far from a data server, but with internet connection.
;   LOCAL_DATA_DIR  = 'C;\data\themis\'                              ; Local (portable) directory on laptop
;   REMOTE_DATA_DIR = 'http://themis.ssl.berkeley.edu/data/themis/'    ;  URL used to download data to LOCAL_DATA_DIR
;
;          MacOS computer located away from SSL without a nearby data server
;   LOCAL_DATA_DIR  = '/data/themis/'                              ; Local (portable) directory on laptop
;   REMOTE_DATA_DIR = 'http://themis.ssl.berkeley.edu/data/themis/'    ;  URL used to download data to LOCAL_DATA_DIR
;
;   Note: If automatic downloads are used. (i.e. REMOTE_DATA_DIR is not an empty string) the user must ensure that
;   LOCAL_DATA_DIR is writeable.
;
;   Note to WINDOWS users: the WINDOWS version of IDL accepts both the '\' and '/' character as the directory
;   separation character. The converse is not true.
;
;
;HISTORY
; Written by Davin Larson
; 2006-12-16 KRB Can now be called from idl_startup to set paths using
; optional keywords.
; 2007-07-02, jmm, Adds trailing slash to local and remote data dirs,
;                  if not there
; 2013-02-27, jmm, Added comment to test SVN commit
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2016-10-06 16:54:56 -0700 (Thu, 06 Oct 2016) $
;$LastChangedRevision: 22062 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_init.pro $
;-
pro thm_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
         no_color_setup=no_color_setup,no_download=no_download

defsysv,'!themis',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!themis', file_retrieve(/structure_format)
endif

if keyword_set(reset) then !themis.init=0

if !themis.init ne 0 then begin 
;Assure that trailing slashes exist on data directories
    !themis.local_data_dir = spd_addslash(!themis.local_data_dir)
    !themis.remote_data_dir = spd_addslash(!themis.remote_data_dir)
    return
endif


!themis = file_retrieve(/structure_format)    ; force setting of all elements to default values.

;
; 2015-01-16
; 
; file_retrieve has preserve_mtime=1 as the default.  This causes
; problems on Windows machines that also have a "touch" executable
; installed (e.g. via a cygwin installation).  Disabling it here
; should fix that issue.  -- JWL
;

!themis.preserve_mtime = 0


thm_config,no_color_setup=no_color_setup,no_download=no_download

thm_set_verbose             ;propagate verbose setting into tplot_vars

; keywords on first call thm_init (or /reset) override environment and
; thm_config
if keyword_set(local_data_dir) then begin ;jmm, 2-jul-2007, add a slash if needed
    !themis.local_data_dir = spd_addslash(local_data_dir)    
endif

if keyword_set(remote_data_dir) then begin ;jmm, 2-jul-2007, add a slash if needed
    !themis.remote_data_dir = spd_addslash(remote_data_dir)
endif


servertestfile = '.themis_master'     ;  This file should only be found on the server. (Do not download this file!)
if file_test(!themis.local_data_dir+servertestfile) then begin
  !themis.no_server = 1
  !themis.no_download =1   ; this line is superfluous.  It can be deleted in the future.
endif


cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
printdat,cdf_version

cdf_version_readmin = '3.1.0'
cdf_version_writemin = '3.1.1'

if cdf_version lt cdf_version_readmin then begin
   print,'Your version of the CDF library ('+cdf_version+') is unable to read THEMIS data files.'
   print,'Please go to the following url to learn how to patch your system:'
   print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
   message,"You can have your data. You just can't read it! Sorry!"
endif

!themis.init = 1

printdat,/values,!themis,varname='!themis'   ;,/pgmtrace

if cdf_version lt cdf_version_writemin then begin
   print,ptrace()
   print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write THEMIS CDF data files.'
   print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
   print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
endif


dt = - (time_double('2007-2-17/11:01') - systime(1)) / 3600/24
days = floor(dt)
dt = (dt - days) * 24
hours = floor(dt)
dt = (dt - hours) * 60
mins = floor(dt)
dt = (dt - mins)  * 60
secs = floor(dt)

print,ptrace()
print,days,hours,mins,secs,format= '("THEMIS countdown:",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'

;debugging fix?
if !version.release ge '8.3' then begin
  !debug_process_events = 0
endif

end


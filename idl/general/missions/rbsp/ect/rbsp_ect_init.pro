;+
;PROCEDURE:  rbsp_ect_init
;PURPOSE:    Initializes system variables for RBSP ECT.  Can be called from idl_startup to set
;            custom locations.
;
; The system variable !RBSP_ECT is defined here.  The elements of this structure are explained below:
;
; !RBSP_ECT.LOCAL_DATA_DIR    This is the root location for all RBSP ECT data files.
;                  The RBSP ECT software expects all data files to reside in specific subdirectories relative
;                  to this root directory.;
;
; !RBSP_ECT.REMOTE_DATA_DIR   This is the URL of the server that can provide the data files.
;                  (default is: "http://themis.ssl.berkeley.edu/data/themis/")
;                  if the software does not find a needed file in LOCAL_DATA_DIR,
;                  then it will attempt to download the data from the URL and REMOTE_DATA_DIR is defined,
;                  the software will attempt to download the file from REMOTE_DATA_DIR, place it in LOCAL_DATA_DIR
;                  with the same relative pathname, and then continue processing.
;                  (NOT YET IMPLEMENTED)
;
;
;KEYWORDS:
;   RESET:           Reset !rbsp_ect to values in environment (or values in keywords).
;   LOCAL_DATA_DIR:  use given value for local_data_dir, rather than environment. Only works on
;                    initial call or reset.
;   REMOTE_DATA_DIR: Use given value for remote_data_dir, rather than env.  Only works on inital
;                    call or reset.
;   NO_COLOR_SETUP   do not set colors if already taken care of
;
; Typical examples:
;
;          Desktop UNIX/LINUX computer located at SSL
;   LOCAL_DATA_DIR  = '/disks/data/rbsp/'               ; This master directory is read only.
;   REMOTE_DATA_DIR = ''                                  ; Should be empty string. (/disks/data/rbsp and server are the same)
;
;          Desktop WINDOWS computer located at SSL
;   LOCAL_DATA_DIR  = '\\justice\data\rbsp\'            ; Justice is a samba server (physically the same as /disk/data/rbsp)
;   REMOTE_DATA_DIR = ''
;
;          laptop WINDOWS computer located far from a data server, but with internet connection.
;   LOCAL_DATA_DIR  = 'C;\data\rbsp\'                              ; Local (portable) directory on laptop
;   REMOTE_DATA_DIR = 'http://themis.ssl.berkeley.edu/data/themis/'    ;  URL used to download data to LOCAL_DATA_DIR
;
;          MacOS computer located away from SSL without a nearby data server
;   LOCAL_DATA_DIR  = '/data/rbsp/'                              ; Local (portable) directory on laptop
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
; Forked from rbsp_efw_init, Jan 2013 - Kris Kersten, kris.kersten@gmail.com
;
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2017-06-13 14:34:31 -0700 (Tue, 13 Jun 2017) $
;$LastChangedRevision: 23463 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/ect/rbsp_ect_init.pro $
;-

pro rbsp_ect_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, $
         no_color_setup=no_color_setup,no_download=no_download

cdf_leap_second_init

defsysv,'!rbsp_ect',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!rbsp_ect', file_retrieve(/structure_format)
endif

if keyword_set(reset) then !rbsp_ect.init=0

if !rbsp_ect.init ne 0 then return

!rbsp_ect = file_retrieve(/structure_format)    ; force setting of all elements to default values.
!rbsp_ect.user_agent=''

rbsp_ect_config,no_color_setup=no_color_setup,no_download=no_download


; keywords on first call rbsp_ect_init (or /reset) override environment and
; rbsp_ect_config
if keyword_set(local_data_dir) then begin
  temp_string = strtrim(local_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !rbsp_ect.local_data_dir = temporary(temp_string)
endif

if keyword_set(remote_data_dir) then begin
  temp_string = strtrim(remote_data_dir, 2)
  ll = strmid(temp_string, strlen(temp_string)-1, 1)
  If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
  !rbsp_ect.remote_data_dir = temporary(temp_string)
endif

; this probably won't be used for ECT, but may be useful is we set up a local repo
servertestfile = '.rbsp_ect_master'     ;  This file should only be found on the server. (Do not download this file!)
if file_test(!rbsp_ect.local_data_dir+servertestfile) then  begin
   !rbsp_ect.no_server = 1
;   !rbsp_ect.no_download = 1   ; This line is superfluous - it can be deleted.
endif


cdf_lib_info,version=v,subincrement=si,release=r,increment=i,copyright=c
cdf_version = string(format="(i0,'.',i0,'.',i0,a)",v,r,i,si)
printdat,cdf_version

cdf_version_readmin = '3.1.0' ;***THIS MAY NEED TO CHANGE
cdf_version_writemin = '3.1.1'

if cdf_version lt cdf_version_readmin then begin
   print,'Your version of the CDF library ('+cdf_version+') is unable to read RBSP ECT data files.'
   print,'Please go to the following url to learn how to patch your system:'
   print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
   message,"You can have your data. You just can't read it! Sorry!"
endif

!rbsp_ect.init = 1

printdat,/values,!rbsp_ect,varname='!rbsp_ect'   ;,/pgmtrace

if cdf_version lt cdf_version_writemin then begin
   print,ptrace()
   print,'Your version of the CDF library ('+cdf_version+') is unable to correctly write RBSP ECT CDF data files.'
   print,'If you ever need to create CDF files then go to the following URL to learn how to patch your system:'
   print,'http://cdf.gsfc.nasa.gov/html/idl62_or_earlier_and_cdf3_problems.html'
endif


dt = - (time_double('2007-2-17/11:01') - systime(1)) / 3600/24 ;***Needs update
days = floor(dt)
dt = (dt - days) * 24
hours = floor(dt)
dt = (dt - hours) * 60
mins = floor(dt)
dt = (dt - mins)  * 60
secs = floor(dt)

print,ptrace()
print,days,hours,mins,secs,format= '("RBSP countdown:",i4," Days, ",i02," Hours, ",i02," Minutes, ",i02," Seconds since launch")'



end

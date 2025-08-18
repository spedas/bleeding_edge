;+
;PROCEDURE:  istp_init
;PURPOSE:    Initializes system variables for ISTP data.  Can be called from idl_startup to set
;            custom locations.
;
;
;HISTORY
; Written by Davin Larson
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2017-03-08 10:30:02 -0800 (Wed, 08 Mar 2017) $
;$LastChangedRevision: 22925 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/istp_init.pro $
;-
pro istp_init, reset=reset  ;, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

defsysv,'!istp',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!istp',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !istp.init=0

if !istp.init ne 0 then return

!istp = file_retrieve(/structure_format)
;Read saved values from file
ftest = istp_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !istp.local_data_dir = ftest.local_data_dir
    !istp.remote_data_dir = ftest.remote_data_dir
    !istp.no_download = ftest.no_download
    !istp.no_update = ftest.no_update
    !istp.downloadonly = ftest.downloadonly
    !istp.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting ISTP to default configuration'
    endif else begin
      print,'No ISTP config found...creating default configuration'
    endelse
    !istp.local_data_dir  = root_data_dir() + 'istp/' 
    ;URL is deprecated
    ;!istp.remote_data_dir = 'http://cdaweb.gsfc.nasa.gov/istp_public/data/'
    ;New url 2012/10 pcruce@igpp
    !istp.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/'
endelse
!istp.archive_ext ='.arc'
!istp.min_age_limit = 900    ; Don't check for new files if local file is less than 900 seconds old.
;!istp.use_wget= getenv('username') eq 'davin'

;if keyword_set(local_data_dir) then  $
;   !istp.local_data_dir = local_data_dir

if file_test(!istp.local_data_dir+'.master') then !istp.no_server=1  ; Local directory IS the master directory

; To change default settings; create a new procedure:  istp_config.pro
;libs,'istp_config',routine=name
;if keyword_set(name) then call_procedure,name

!istp.init = 1

printdat,/values,!istp,varname='!istp

end



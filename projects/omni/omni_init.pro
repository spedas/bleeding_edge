;+
;PROCEDURE:  omni_init
;PURPOSE:    Initializes system variables for OMNI data.  Can be called from idl_startup to set
;            custom locations.
;
;
;HISTORY
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-04-03 09:58:23 -0700 (Fri, 03 Apr 2020) $
;$LastChangedRevision: 28486 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/omni/omni_init.pro $
;-
pro omni_init, reset=reset  ;, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

defsysv,'!omni',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!omni',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !omni.init=0

if !omni.init ne 0 then return

!omni = file_retrieve(/structure_format)
;Read saved values from file
ftest = omni_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !omni.local_data_dir = ftest.local_data_dir
    !omni.remote_data_dir = ftest.remote_data_dir
    !omni.no_download = ftest.no_download
    !omni.no_update = ftest.no_update
    !omni.downloadonly = ftest.downloadonly
    !omni.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting OMNI to default configuration'
    endif else begin
      print,'No OMNI config found...creating default configuration'
    endelse
;Different defaults at SSL, jmm, 2018-07-19, OMNI data is in
;/disks/data/istp, but root_data_dir will return /disks/data
    If(root_data_dir() Eq '/disks/data/' && $
       file_test(root_data_dir()+'themis/.themis_master')) Then Begin
       !omni.local_data_dir = root_data_dir()+'istp/' ;at SSL - linux
    Endif Else !omni.local_data_dir  = root_data_dir() + 'omni/' 
    !omni.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/'
endelse
; omniive_ext isn't needed because we use OMNI data from CDFs at SPDF now
;!omni.omniive_ext ='.arc'
!omni.min_age_limit = 900    ; Don't check for new files if local file is less than 900 seconds old.
;!omni.use_wget= getenv('username') eq 'davin'

if getenv('SPEDAS_DATA_DIR') ne '' then $
   !omni.LOCAL_DATA_DIR = spd_addslash(getenv('SPEDAS_DATA_DIR'))+'omni/'
  
if keyword_set(local_data_dir) then  $
   !omni.local_data_dir = local_data_dir

if file_test(!omni.local_data_dir+'.master') then !omni.no_server=1  ; Local directory IS the master directory

; To change default settings; create a new procedure:  omni_config.pro
;libs,'omni_config',routine=name
;if keyword_set(name) then call_procedure,name

!omni.init = 1

printdat,/values,!omni,varname='!omni'

end



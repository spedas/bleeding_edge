;+
;PROCEDURE:  wind_init
;PURPOSE:    Initializes system variables for WIND.  Can be called from idl_startup to set
;            custom locations.
;
;HISTORY
; Written by Davin Larson
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2017-02-16 14:54:44 -0800 (Thu, 16 Feb 2017) $
;$LastChangedRevision: 22807 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/wind_init.pro $
;-
pro wind_init, reset=reset  ;, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

defsysv,'!wind',exists=exists
if not keyword_set(exists) then begin
   defsysv,'!wind',  file_retrieve(/structure_format)
endif

if keyword_set(reset) then !wind.init=0

if !wind.init ne 0 then return

!wind = file_retrieve(/structure_format)
;Read saved values from file
ftest = wind_read_config()
If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !wind.local_data_dir = ftest.local_data_dir
    !wind.remote_data_dir = ftest.remote_data_dir
    !wind.no_download = ftest.no_download
    !wind.no_update = ftest.no_update
    !wind.downloadonly = ftest.downloadonly
    !wind.verbose = ftest.verbose
Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting WIND to default configuration'
    endif else begin
      print,'No WIND config found...creating default configuration'
    endelse
    ; The WIND load routines add a trailing "wind" component to 
    ; the local_data_dir.  So we should leave that out of the
    ; default path.  JWL 2014-07-25

    ;!wind.local_data_dir = spd_default_local_data_dir() + 'wind' + path_sep()
    !wind.local_data_dir = root_data_dir()
    !wind.remote_data_dir = 'https://spdf.gsfc.nasa.gov/pub/data/'
endelse
if file_test(!wind.local_data_dir+'wind/.master') then begin  ; Local directory IS the master directory
   !wind.no_server=1    ;   
   !wind.no_download=1  ; This line is superfluous
endif

;libs,'wind_config',routine=name
;if keyword_set(name) then call_procedure,name

!wind.init = 1

printdat,/values,!wind,varname='!wind'

end


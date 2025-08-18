;+
; NAME:  
;   yyy_init
; 
; PURPOSE:    
;   Initializes system variables for yyy data. Can be called from idl_startup to set
;            custom locations.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-05-13 14:10:12 -0700 (Sun, 13 May 2018) $
;$LastChangedRevision: 25206 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/api_examples/file_configuration_tab/yyy_init.pro $
;-

pro yyy_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, no_color_setup=no_color_setup
  defsysv,'!yyy',exists=exists
  if not keyword_set(exists) then begin
     defsysv,'!yyy',  file_retrieve(/structure_format)
  endif
  
  if keyword_set(reset) then !yyy.init=0
  
  if !yyy.init ne 0 then return
  
  !yyy = file_retrieve(/structure_format)
  
  ;Read saved values from file
  ftest = yyy_read_config()
  
  If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
      !yyy.local_data_dir = ftest.local_data_dir
      !yyy.remote_data_dir = ftest.remote_data_dir
      !yyy.no_download = ftest.no_download
      !yyy.no_update = ftest.no_update
      !yyy.downloadonly = ftest.downloadonly
      !yyy.verbose = ftest.verbose
  Endif else begin; use defaults
      if keyword_set(reset) then begin
        print,'Resetting yyy to default configuration'
      endif else begin
        print,'No yyy config found...creating default configuration'
      endelse
      !yyy.local_data_dir = spd_default_local_data_dir()
      !yyy.remote_data_dir = ''
  endelse
  
  if file_test(!yyy.local_data_dir+'yyy/.master') then begin  ; Local directory IS the master directory
      !yyy.no_server = 1
  endif
  ;libs,'yyy_config',routine=name
  ;if keyword_set(name) then call_procedure,name
  
  !yyy.init = 1
  
  printdat,/values,!yyy,varname='!yyy

end

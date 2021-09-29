;+
;PROCEDURE:  geotail_init
;PURPOSE:    Initializes system variables for geotail data.  Can be called from idl_startup to set
;            custom locations.
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-03-07 11:40:11 -0800 (Wed, 07 Mar 2018) $
;$LastChangedRevision: 24846 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/geotail/geotail_init.pro $
;-

pro geotail_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, no_color_setup=no_color_setup

  if not keyword_set(no_color_setup) then begin
    spd_graphics_config,colortable=colortable
  endif ; no_color_setup
  
  defsysv,'!geotail',exists=exists
  if not keyword_set(exists) then begin
     defsysv,'!geotail',  file_retrieve(/structure_format)
  endif
  
  if keyword_set(reset) then !geotail.init=0
  
  if !geotail.init ne 0 then return
  
  !geotail = file_retrieve(/structure_format)
  
  ;Read saved values from file
  ftest = geotail_read_config()
  
  If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
      !geotail.local_data_dir = ftest.local_data_dir
      !geotail.remote_data_dir = ftest.remote_data_dir
      !geotail.no_download = ftest.no_download
      !geotail.no_update = ftest.no_update
      !geotail.downloadonly = ftest.downloadonly
      !geotail.verbose = ftest.verbose
  Endif else begin; use defaults
      if keyword_set(reset) then begin
        print,'Resetting geotail to default configuration'
      endif else begin
        print,'No geotail config found...creating default configuration'
      endelse
      !geotail.local_data_dir = spd_default_local_data_dir() + 'geotail/'
      !geotail.remote_data_dir = ''
  endelse
  
  !geotail.init = 1
  
  printdat,/values,!geotail,varname='!geotail


end

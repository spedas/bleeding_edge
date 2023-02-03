;+
; Procedure:
;       goesr_init
;
; Purpose:
;       Initializes system variables for GOES-R data.  Can be called from idl_startup to set
;             custom locations.
;
; Keywords:
;       reset: resets configuration data already in place on the machine
;       local_data_dir: location to save data files on the local machine
;       remote_data_dir: location of the data on the remote machine
;       no_color_setup: skip setting up the graphics configuration
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2023-02-02 07:46:23 -0800 (Thu, 02 Feb 2023) $
; $LastChangedRevision: 31461 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/goesr_init.pro $
;-

pro goesr_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir, no_color_setup = no_color_setup

  compile_opt idl2

  defsysv,'!goesr',exists=exists
  if not keyword_set(exists) then begin
    defsysv,'!goesr',  file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !goesr.init=0

  if !goesr.init ne 0 then return

  !goesr = file_retrieve(/structure_format)
  ;Read saved values from file
  ftest = goesr_read_config()
  If(size(ftest, /type) Eq 8) && ~keyword_set(reset) Then Begin
    !goesr.local_data_dir = ftest.local_data_dir
    !goesr.remote_data_dir = ftest.remote_data_dir
    !goesr.no_download = ftest.no_download
    !goesr.no_update = ftest.no_update
    !goesr.downloadonly = ftest.downloadonly
    !goesr.verbose = ftest.verbose
  Endif else begin; use defaults
    if keyword_set(reset) then begin
      print,'Resetting GOES-R to default configuration'
    endif else begin
      print,'No GOES-R config found...creating default configuration'
    endelse
    !goesr.local_data_dir  = spd_default_local_data_dir() + 'goesr' + path_sep()
    ;https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/goes16/l2/data/magn-l2-hires/2020/
    !goesr.remote_data_dir = 'https://data.ngdc.noaa.gov/platforms/solar-space-observing-satellites/goes/'
  endelse
  !goesr.min_age_limit = 900    ; Don't check for new files if local file is less than 900 seconds old.

  if file_test(!goesr.local_data_dir+'.master') then begin ; Local directory IS the master directory
    !goesr.no_server = 1
  endif

  ; Do not do color setup if taken care for already
  if not keyword_set(no_color_setup) then begin

    spd_graphics_config,colortable=colortable

  endif ; no_color_setup

  !goesr.init = 1

  printdat,/values,!goesr,varname='!goesr'

end
